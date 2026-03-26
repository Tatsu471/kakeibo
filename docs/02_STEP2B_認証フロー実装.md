# 📖 STEP 2-B 実装解説ドキュメント
## 〜認証フロー実装編〜

> **対象読者**: 新卒エンジニアやFlutter/Firebase初心者の方
> **ゴール**: 「ログイン画面」「認証の仕組み」「画面の振り分け」のコードを理解すること

---

## 🗂️ このSTEPで作ったもの・変えたもの

```
kakeibo/
├── pubspec.yaml                    ← Firebase パッケージを追記
├── lib/
│   ├── firebase_options.dart       ← FlutterFire CLI が自動生成（触らない）
│   ├── main.dart                   ← Firebase初期化 + AuthGate 追加
│   ├── services/
│   │   └── auth_service.dart       ← 認証ロジックをまとめたクラス（新規作成）
│   └── screens/
│       └── login_screen.dart       ← ログイン画面（新規作成）
└── firestore.rules                 ← セキュリティルール定義ファイル（新規作成）
```

---

## 1. `pubspec.yaml` に追加したパッケージ

```yaml
dependencies:
  firebase_core: ^3.6.0    # Firebase の基盤（必須）
  firebase_auth: ^5.3.1    # 認証機能
  cloud_firestore: ^5.4.4  # データベース（STEP 3で本格利用）
```

> 💡 **なぜ `google_sign_in` パッケージは使わないの？**
> 当初は `google_sign_in` パッケージを使う予定でしたが、
> Web環境では「OAuthクライアントIDをHTMLに設定する」という追加作業が発生します。
> Firebase Auth 本体の `signInWithPopup` を使えばその設定が不要なため、こちらに切り替えました。
> 機能は全く同じです。

---

## 2. `lib/services/auth_service.dart` ― 認証ロジックの管理

### 「サービスクラス」とは何か

画面（Screen）とロジック（処理）を分離するための設計パターンです。

```
❌ 悪い設計: ログイン画面のコードにFirebaseの処理を直接書く
✅ 良い設計: AuthServiceがFirebaseの処理を担当 → 画面はAuthServiceを呼ぶだけ
```

こうすることで、後から「LINEログインも追加したい」となったときに
`auth_service.dart` だけを修正すればよくなります。

### コードの解説

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 認証状態の変化を「川（Stream）」として流す
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Googleでサインイン（ポップアップ方式）
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    return await _auth.signInWithPopup(googleProvider); // 小窓が開く
  }

  // サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

> 💡 **Streamとは？**
> 「川」のようなものです。水（データ）がリアルタイムで流れてきます。
> ユーザーがログインしたりログアウトしたりするたびに、自動で「状態が変わったよ！」と通知が来ます。
> 画面側はこの川を「監視（listen）」しておくことで、常に最新の状態を表示できます。

---

## 3. `lib/main.dart` の変更 ― Firebase初期化とAuthGate

### Firebase初期化

```dart
void main() async {
  // Flutterのエンジン起動を保証してからFirebaseを初期化
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KakeiboApp());
}
```

> 💡 **なぜ `async/await` が必要なの？**
> `Firebase.initializeApp()` はインターネット越しの処理なので、完了するまで時間がかかります。
> `await` をつけることで「Firebaseの準備が完全に終わるまで次の処理に進まない」と保証できます。
> `async/await` なしだと、Firebaseの準備が終わる前にアプリが起動してエラーになります。

### AuthGate ― 認証状態で画面を振り分けるゲート

```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // 認証状態の川を監視
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeShell(); // ログイン済み → ホーム画面
        }
        return const LoginScreen(); // 未ログイン → ログイン画面
      },
    );
  }
}
```

#### この仕組みのポイント

```
Firebase ──ログイン状態が変化──→ Stream に流れる
                                      ↓
                              StreamBuilder が検知
                                      ↓
              ログイン済み？ → HomeShell / 未ログイン？ → LoginScreen
```

**ユーザーがログインした瞬間、コードを1行も書かずに自動でホーム画面に切り替わります。**
これが `Stream` を使う最大のメリットです。

---

## 4. `lib/screens/login_screen.dart` ― ログイン画面

### 全体の構造

```
Scaffold
└── Container（グラデーション背景）
    └── Center
        └── Column（縦並び）
            ├── 織璃無プレースホルダー（円形）
            ├── タイトル「織璃無の家計簿」
            ├── サブテキスト（キャラクターの言葉）
            └── Googleログインボタン（グラスモーフィズム）
```

### ローディング状態の管理

```dart
class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // ← ローディング中かどうかのフラグ

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true); // ローディング開始
    try {
      await _authService.signInWithGoogle();
      // 成功 → AuthGateが自動で画面を切り替えるので、ここでは何もしない
    } catch (e) {
      // 失敗 → スナックバーでエラー表示
      ScaffoldMessenger.of(context).showSnackBar(...);
    } finally {
      if (mounted) setState(() => _isLoading = false); // ローディング終了
    }
  }
}
```

> 💡 **`mounted` チェックとは？**
> ログイン処理中にユーザーが画面を閉じた場合、`setState` を呼ぶと例外が発生します。
> `mounted` が `true` の時だけ（＝画面がまだ表示されている時だけ）`setState` を呼ぶのが安全です。

---

## 5. トラブルシューティング記録

| エラー | 原因 | 解決策 |
|---|---|---|
| `ClientID not set` | `google_sign_in` パッケージがWeb向けにOAuth ID設定を要求 | `signInWithPopup` 方式に切り替え（`google_sign_in` 削除） |
| `couldn't resolve package 'google_sign_in_web'` | パッケージ削除後もビルドキャッシュに残骸が残っていた | `flutter clean` → `flutter pub get` で解消 |

---

## 6. STEP 2 受け入れテスト結果

| テスト内容 | 結果 |
|---|---|
| アプリ起動時にログイン画面が表示されるか | ✅ |
| 「Googleでログイン」ボタンを押すとポップアップが開くか | ✅ |
| Googleアカウントでログイン後、ホーム画面に自動遷移するか | ✅ |

---

## 📌 次のSTEP 3 でやること

- 記録入力画面の実装（タブ切り替え・電卓キーパッド）
- Firestoreへの支出データの書き込み
- ホーム画面の月間合計額をFirestoreから取得してリアルタイム表示
