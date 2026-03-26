# 📖 STEP 5 実装解説ドキュメント
## 〜デプロイ準備・セキュリティ監査・Firebase Hosting 公開〜

> **対象読者**: 新卒エンジニアやデプロイ経験が浅い方
> **ゴール**: 「開発環境で動くもの」を「誰でも使える本番環境」に公開する一連の流れを理解すること

---

## 🗂️ このSTEPで行った作業

```
[手順1] セキュリティ監査（シークレットの漏洩チェック）
[手順2] Web プラットフォームのサポートを有効化
[手順3] 本番用ビルドの生成（flutter build web）
[手順4] firebase.json に Hosting 設定を追加
[手順5] Firebase Hosting へデプロイ
```

---

## 1. セキュリティ監査

### チェックポイント一覧

| 確認内容 | 結果 | 理由 |
|---|---|---|
| `firebase_options.dart` が `.gitignore` に記載されているか | ✅ | APIキーを含むため公開禁止 |
| `lib/` 配下に `AIzaSy` 等のシークレットが露出していないか | ✅ | `firebase_options.dart` 以外に記載なし |
| `.env` ファイルが `.gitignore` に記載されているか | ✅ | 環境変数ファイルは公開禁止 |
| `firebase.json` の内容（プロジェクトIDのみか）| ✅ | プロジェクトIDは公開情報につき問題なし |

> 💡 **`firebase_options.dart` はなぜGitにあげてはいけないの？**
> このファイルには Firebase APIキーが含まれています。
> APIキーが公開されると、第三者がFirebaseに不正アクセスできる可能性があります。
> `.gitignore` に記載することで、`git commit` の対象から除外しています。

---

## 2. Web プラットフォームのサポートを有効化

```bash
flutter create . --platforms web
```

> 💡 **なぜこれが必要だったの？**
> `flutter run -d chrome` では開発サーバーが適当に補完してくれていましたが、
> `flutter build web` のような本番ビルドには `web/` フォルダが必要です。
> このコマンドで `web/index.html` などの Web 向けテンプレートが生成されました。

---

## 3. 本番用ビルド（flutter build web）

```bash
flutter build web --release
```

**開発モード vs 本番モードの違い：**

| | 開発モード（flutter run） | 本番モード（--release） |
|---|---|---|
| 目的 | デバッグ・確認 | 実際のユーザーに公開 |
| 速度 | 遅い（デバッグ情報付き） | 速い（最適化済み） |
| ファイルサイズ | 大きい | 小さい |
| デバッグツール | 使える | 無効 |

今回のビルドでは **MaterialIcons を 99.4%（1.6MB → 9KB）削減** できました。
これは「使っていないアイコンを自動的に除外するTree-shaking」という最適化の結果です。

---

## 4. `firebase.json` ― Firebase Hosting の設定

```json
{
  "hosting": {
    "public": "build/web",     // 公開するフォルダ（buildコマンドの出力先）
    "ignore": [                // デプロイしないファイル
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [              // 全URLを index.html に転送
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

> 💡 **`rewrites` はなぜ必要？**
> Flutter Web は「SPA（Single Page Application）」という仕組みで動きます。
> `/history` や `/settings` などのURLに直接アクセスしたとき、
> サーバー側には対応するHTMLファイルが存在しないためエラーになります。
> `rewrites` を設定することで「どんなURLでも `index.html` を返す」→
> Flutter がJavascripで正しい画面を表示するという流れになります。

---

## 5. デプロイ（firebase deploy）

```bash
firebase deploy --only hosting --project kakeibo-9b5fa
```

> **`--only hosting`** とは？
> Firebase には認証・Firestore・関数など複数のサービスがあります。
> `--only hosting` をつけることで「ホスティングだけデプロイ」と限定できます。
> 誤って他の設定（セキュリティルール等）を上書きしないための安全策です。

---

## 6. Netlify vs Firebase Hosting

設計図では「Netlify または Firebase Hosting」と記載されていました。

| | Netlify | Firebase Hosting |
|---|---|---|
| 長所 | GitHub 連携で自動デプロイ | Firebase と一体管理、設定がシンプル |
| 短所 | 別サービスの管理が必要 | GitHub Actions の設定が別途必要 |
| 向いている場面 | GitHub をメインに使う場合 | Firebase をフル活用する場合 |

今回は **Firebase をすでに使っている**ため Firebase Hosting を選択しました。

---

## 7. 本番URL と最終テスト結果

**🌐 本番URL: https://kakeibo-9b5fa.web.app**

| テスト内容 | 結果 |
|---|---|
| ログイン画面が表示されるか | ✅ |
| Google ログインが成功するか | ✅ |
| ホーム画面で月間合計が表示されるか | ✅ |
| ＋ボタンで記録が保存され合計が増えるか | ✅ |
| 振り返り画面でリストが表示されるか | ✅ |

---

## 📌 Phase 2 候補（MVP完成後）

| 機能 | 技術 | 優先度 |
|---|---|---|
| 折れ線・棒グラフで月間推移を可視化 | `fl_chart` パッケージ | ⭐⭐⭐ |
| 設定画面（ログアウト・プロフィール） | 追加画面の実装 | ⭐⭐ |
| ダーク/ライトモードの手動切り替え | `Riverpod` での状態管理 | ⭐⭐ |
| OCR レシート自動読み取り | Google ML Kit | ⭐ |
| GitHub 連携の自動デプロイ | GitHub Actions | ⭐ |
