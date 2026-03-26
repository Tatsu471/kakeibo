# 📖 STEP 2-A 実装解説ドキュメント
## 〜Firebase環境構築編〜

> **対象読者**: 新卒エンジニアや、Firebaseを初めて使う方
> **ゴール**: 「Firebaseとは何か」から「アプリへの接続方法」までを理解すること

---

## 🗂️ このドキュメントで扱う作業

```
[手順1] Firebaseプロジェクトの作成（ブラウザ操作）
[手順2] Google認証の有効化（ブラウザ操作）
[手順3] Firestoreデータベースの作成（ブラウザ操作）
[手順4] Firebase CLIのインストール（ターミナル）
[手順5] Firebaseへのログイン（ターミナル）
[手順6] FlutterアプリとFirebaseの接続（ターミナル）
```

---

## 1. Firebase とは何か

Firebase は Google が提供する「バックエンド一式サービス（BaaS）」です。

通常、アプリを作る際には：
- ユーザーデータを保存するための**データベースサーバー**
- ログイン機能を処理する**認証サーバー**
- それらを動かすための**サーバーコード**

が必要ですが、Firebase はこれらを全部引き受けてくれます。
コードを書くだけでサーバー管理が不要になります。

### 今回使う Firebase の機能

| サービス名 | 役割 |
|---|---|
| Firebase Authentication | Googleアカウントでのログイン機能 |
| Cloud Firestore | 支出データを保存するデータベース |

---

## 2. Firebase コンソールでの作業（ブラウザ操作）

### 【手順1】プロジェクトの作成

Firebaseでアプリを使うには「プロジェクト」という箱を作る必要があります。

1. [https://console.firebase.google.com/](https://console.firebase.google.com/) を開く
2. 「プロジェクトを追加」→ プロジェクト名（`kakeibo`）を入力
3. Google アナリティクスは「無効」→ 「プロジェクトを作成」

> 💡 **プロジェクトIDについて**
> 作成時に `kakeibo-9b5fa` のような固有のIDが自動で割り当てられます。
> これがFirebase上でのアプリの「住所」になります。

### 【手順2】Google 認証の有効化

Firebase はいくつかのログイン方式をサポートしていますが、デフォルトでは全て無効になっています。

1. 左メニュー →「Authentication」→「始める」
2. 「Sign-in method」タブ →「Google」を選択 → 「有効にする」をON
3. プロジェクトの公開名とサポートメールを入力 → 「保存」

### 【手順3】Firestore データベースの作成

1. 左メニュー →「Firestore Database」→「データベースの作成」
2. ロケーション: `asia-northeast1`（東京）を選択
3. セキュリティルール: 「テストモードで開始」→「有効にする」

> ⚠️ **テストモードとは？**
> 最初は「誰でもデータを読み書きできる」状態です。
> 開発中は便利ですが、後でセキュリティルールを設定して制限をかけます（後述）。

---

## 3. Firebase CLI とは何か

CLI（Command Line Interface）とは、ブラウザではなく**ターミナル（黒い画面）でコマンドを入力して操作するツール**のことです。

Firebase CLI を使うと、ターミナルからFirebaseコンソールの設定を読み書きできます。

### 【手順4】Firebase CLI のインストール（Mac の場合）

```bash
brew install firebase-cli
```

> 💡 `brew` とは Mac 専用のソフトウェアインストール管理ツールです。
> インターネットからダウンロード〜インストールまで自動でやってくれます。

### 【手順5】Firebase へのログイン

```bash
firebase login
```

ブラウザが開き、Googleアカウントでの認証を求められます。
完了すると「✔ Logged in as your@gmail.com」と表示されます。

> ℹ️ 別のアカウントに切り替えたい場合：
> ```bash
> firebase logout
> firebase login
> ```

---

## 4. FlutterFire CLI によるアプリ接続

**FlutterFire CLI** は Flutter と Firebase を繋ぐための専用ツールです。
このツールが `lib/firebase_options.dart` というファイルを自動生成してくれます。

### 【手順4-前準備】FlutterFire CLI のインストール

```bash
dart pub global activate flutterfire_cli
```

> ℹ️ インストール後にパスが通っていない場合は以下を実行：
> ```bash
> export PATH="$PATH":"$HOME/.pub-cache/bin"
> # ターミナルを再起動しても有効にするには：
> echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
> ```

### 【手順6】アプリとFirebaseの接続

```bash
# プロジェクトIDとプラットフォームを直接指定
flutterfire configure --project=kakeibo-9b5fa --platforms=web
```

> 💡 **なぜ `--platforms=web` を指定するの？**
> このアプリはFlutter Webとして動かすため。
> `android` や `ios` 用の設定は今回不要です。

実行後、`lib/firebase_options.dart` が自動生成されます。

```dart
// 自動生成されるファイルのイメージ
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSy...',      // FirebaseのAPIキー
  appId: '1:4651...',       // このアプリのID
  projectId: 'kakeibo-9b5fa', // プロジェクトの住所
  authDomain: '...',         // 認証に使うドメイン
  // ...
);
```

> ⚠️ **このファイルはGitにコミットしない！**
> `firebase_options.dart` には機密情報が含まれているため、`.gitignore` に追記して除外します。
> （STEP 1で設定済み）

---

## 5. Firestore セキュリティルールの設定

テストモードのままでは「誰でもデータを読み書きできる」状態なので、必ず制限をかけます。

### 設定手順

1. Firebaseコンソール →「Firestore Database」→「ルール」タブ
2. 以下のルールをコピー＆ペーストして「公開」

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/expenses/{expenseId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### このルールの意味

```
request.auth != null
```
→ ログインしているユーザーのみアクセス可能（未ログインは拒否）

```
request.auth.uid == userId
```
→ URLの `{userId}` 部分と、ログイン中のユーザーIDが一致する場合のみ許可

**つまり「自分のデータにしかアクセスできない」** という最低限のセキュリティです。

---

## 6. STEP 2-A のトラブルシューティング記録

| エラー | 原因 | 解決策 |
|---|---|---|
| `zsh: command not found: firebase` | Firebase CLI未インストール | `brew install firebase-cli` |
| `zsh: command not found: flutterfire` | PATHが通っていない | `export PATH="$PATH":"$HOME/.pub-cache/bin"` |
| 対話式メニューでスペースが効かない | ターミナルの互換性問題 | `--platforms=web` オプションで直接指定 |
