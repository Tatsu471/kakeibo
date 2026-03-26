# 📖 STEP 1 実装解説ドキュメント
## 〜環境構築とベースUI〜

> **対象読者**: このアプリを初めて触る新卒エンジニアや、コードに不慣れな方
> **ゴール**: 「何をどの順番で作ったのか、なぜそうしたのか」を理解してもらうこと

---

## 🗂️ このSTEPで作ったもの・変えたもの 全体マップ

```
kakeibo/
├── pubspec.yaml                    ← アプリの「部品リスト」（今回新規作成）
├── .gitignore                      ← Gitに含めてはいけないファイルを定義（今回新規作成）
└── lib/
    ├── main.dart                   ← アプリの「電源スイッチ」（今回作成・テーマ定義）
    └── screens/
        ├── home_screen.dart        ← ホーム画面 + 画面切り替えの司令塔（今回作成）
        ├── entry_screen.dart       ← 記録入力画面の「空箱」（STEP 3で中身を実装予定）
        ├── history_screen.dart     ← 振り返り画面の「空箱」（STEP 4で中身を実装予定）
        └── settings_screen.dart    ← 設定画面の「空箱」（STEP 2以降で実装予定）
```

---

## 1. `pubspec.yaml` ― アプリの「部品リスト」

### 何のファイル？
アプリが使う「外部の便利道具（パッケージ）」を申告するファイルです。
料理のレシピに「材料：卵2個、牛乳200ml…」と書くのと同じイメージです。

### 今回追加したパッケージ
```yaml
dependencies:
  google_fonts: ^6.2.1  # ← Googleが提供するフォント集（Zen Maru Gothicを使うために必要）
```

### なぜ `flutter pub get` を実行するの？
`pubspec.yaml` に書いた材料は「申告しただけ」の状態です。
`flutter pub get` を実行して初めて、インターネットから実際にダウンロードされます。
スーパーのカゴに入れた商品を、レジに持っていく作業だと思ってください。

---

## 2. `lib/main.dart` ― アプリの「電源スイッチ＋デザインルールブック」

### 何のファイル？
Flutter（Dartという言語で書くスマホ・Webアプリのフレームワーク）の起動地点です。
コンピューターは `main()` 関数を見つけると「ここから動かせばいいんだな」と認識します。

### 今回のポイント：テーマの定義

アプリ全体のデザインを「ライトモード」と「ダークモード」の2つに分けて定義しました。

```dart
// ===== 織璃無テーマカラー定義 =====
static const Color _lapisLazuli = Color(0xFF1A237E); // 瑠璃色
static const Color _antiqueGold = Color(0xFFE0B94F); // 黄金
static const Color _seaTeal    = Color(0xFF2E8F7D); // 静かな青緑
static const Color _lilyWhite  = Color(0xFFFDFDFD); // 純白
```

> 💡 **なぜ色を変数（名前）で定義するの？**
> `Color(0xFF1A237E)` という謎の数字を毎回書くと、「この色って何だっけ？」となります。
> `_lapisLazuli`（瑠璃色）という名前をつけておくことで、コードを人間が読めるようになります。
> また、「瑠璃色を変えたい！」となったときに、この1箇所だけ直せば全部変わります。

#### ライトモードとダークモードの違い

| 項目 | ライトモード | ダークモード |
|------|------------|------------|
| 背景色 | 淡いホワイト | 瑠璃色（Lapis Lazuli） |
| メインテキスト | 瑠璃色 | 純白 |
| アクセント（食費） | 黄金 | 黄金（共通） |

```dart
// OS設定に従って自動で切り替わる（将来はボタンでも切り替え予定）
themeMode: ThemeMode.system,
```

> 💡 **`ThemeMode.system` って何？**
> MacやiPhoneの「外観設定」で「ダーク」を選ぶと、アプリも自動でダークになります。
> ユーザーがいちいちアプリ内で設定しなくてよいので、これが一番スマートです。

---

## 3. `lib/screens/home_screen.dart` ― 画面の司令塔

このファイルには3つのクラス（役割のかたまり）が入っています。

### ① `HomeShell` ― 画面切り替えの司令塔

```
[設定ボタン] [カメラ] [＋ボタン] [グラフ] [ホーム]
    ↑            ↑        ↑         ↑        ↑
   設定画面へ  (後で実装)  入力画面へ  履歴画面へ  ホームへ
```

`HomeShell` は `StatefulWidget` という「状態を持てる」ウィジェットです。
「今どの画面にいるか（番号）」をメモリに記憶しておきます。

```dart
int _currentIndex = 0; // 0=ホーム, 1=履歴, 2=設定
```

**`IndexedStack` という仕組みを使っています。**
3枚の画面を重ねておいて、現在の番号の画面だけ「表面」に出す、という方法です。
毎回画面を作り直さないので動作が速いです。

### ② `HomeScreen` ― ホーム画面の中身

「今月の食費」「織璃無のキャラクター」「今月の交通費」を縦に並べています。

**グラデーション背景の仕組み**
```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,  // 左上からスタート
  end: Alignment.bottomRight, // 右下に向かって
  colors: [白っぽい色, 少し青みがかかった色],
)
```
絵の具を塗るときに、左上から右下に向かってじわっと色が変わっていくイメージです。

### ③ `GlassCard` ― グラスモーフィズムのカード

「グラスモーフィズム」とは、磨りガラス越しに背景が透けて見える、今流行のデザイン手法です。

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // ← 背景をぼかす
  child: Container(
    color: Colors.white.withOpacity(0.65), // ← 白の半透明で「ガラス」を表現
    ...
  ),
)
```

**テーマカラー参照の書き方**（重要！）
```dart
// ❌ 悪い例（ハードコード）
color: Color(0xFF1A237E) // 直接書いてしまうと、テーマ変更に追従できない

// ✅ 良い例（テーマ参照）
color: colorScheme.primary // テーマが変われば自動で正しい色になる
```

---

## 4. `.gitignore` ― 「これをGitに含めないで！」リスト

### Gitって何？
コードの「変更履歴を記録する仕組み」です。GitHubなどにアップロードすることで、
チームで共同作業したり、「昨日のコードに戻したい！」ができるようになります。

### なぜ `.gitignore` が必要？
絶対にGitHubにアップしてはいけないファイルがあります。

```gitignore
# ❌ 絶対ダメ！インターネットに公開されると最悪タダ使いされる
.env                    ← APIキーなどの暗号（秘密情報）
google-services.json    ← Firebaseの設定（Step 2で作成予定）
GoogleService-Info.plist ← iOS用Firebaseの設定（同上）
```

`.gitignore` に書いておくと、Gitが「あ、これは含めなくていいんだな」と判断してくれます。
**Step 2でFirebaseを設定する前にこれを準備しておくのが重要です。**

---

## 5. スケルトン画面（空箱）について

`entry_screen.dart`, `history_screen.dart`, `settings_screen.dart` は今は空っぽです。

```dart
// 現在はこういう状態（中身は後で作る）
class EntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('STEP 3で実装予定')),
    );
  }
}
```

### なぜ空っぽのまま作るの？

1. **ナビゲーション（画面遷移）を先に繋いでおく**ため
   → ボタンを押したら画面が切り替わる、という「骨格」を先に作っておくことで、
   `EntryScreen` の中身を実装するときに「繋ぎ直し」の作業が発生しません。

2. **エラーを防ぐ**ため
   → `_screens = [HomeScreen(), HistoryScreen(), SettingsScreen()]` というリストに
   `HistoryScreen` が入っていないと、コンパイルエラーになります。

---

## 6. STEP 1 の受け入れテスト結果

| テスト内容 | 結果 |
|-----------|------|
| スマホサイズで下部ナビゲーションが表示されるか | ✅ |
| 各ナビアイコンで画面が切り替わるか | ✅ |
| ライトモードで淡いホワイト背景になるか | ✅ |
| ダークモードで瑠璃色背景になるか | ✅ |
| グラスモーフィズムのカードが表示されるか | ✅ |
| Zen Maru Gothicフォントが適用されているか | ✅ |

---

## 📌 次のSTEP 2 でやること

- Firebase プロジェクトの作成と接続
- Google ログイン機能の実装
- Firestore のセキュリティルール設定

> ⚠️ STEP 2 を始める前に `.env` ファイルを作成し、
> `.gitignore` に確実に含まれているか確認してから進めること。
