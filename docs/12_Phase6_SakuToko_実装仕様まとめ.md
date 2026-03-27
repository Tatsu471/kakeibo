# Phase 6: SakuToko ブランド実装仕様まとめ

Phase 6 で実施された「SakuToko（サクトコ）」へのリブランディングに関する、実装の具体的詳細を記録した仕様書です。

---

## 🎨 1. アセット構成
提供された 4 種のロゴファイルを、プロジェクト標準のディレクトリ構造に配置しました。

- **配置ディレクトリ**: `assets/logo/`
- **ファイル名と用途**:
  - `logo_black.png`: ライトモード用（透過なし）
  - `logo_black_transparent.png`: ライトモード用（透過あり）
  - `logo_white.png`: ダークモード用（透過なし）
  - `logo_white_transparent.png`: ダークモード用（透過あり / **ホーム画面ヘッダーで使用**）
- **OGP 画像**: `web/assets/ogp.png` に `logo_white.png` をコピー。

---

## ✍️ 2. 名称・メタデータの一括置換
「織璃無の家計簿」および「kakeibo」という旧名称を、以下のすべての箇所で **SakuToko** に統合しました。

- **`lib/main.dart`**: MaterialApp の `title` を `SakuToko` に更新。
- **`web/index.html`**:
  - `<title>` を `SakuToko` に変更。
  - OGP メタタグ（`og:title`, `og:image`, `og:description`）を追加。
- **`web/manifest.json`**: アプリケーション名を `SakuToko` に、テーマカラーを `_lapisLazuli (#1A237E)` に変更。

---

## 📱 3. UI 画面ごとの文字列・ロゴ反映
各画面のタイトルやヘルプメッセージを新ブランドに合わせて調整しました。

### ホーム画面 (`home_screen.dart`)
- **ロゴ配置**: ヘッダー左上に `logo_white_transparent.png` (Dark) または `logo_black_transparent.png` (Light) を高さ 32px で配置。
- **文言**: 「支出サマリー」の横に月表示を集約。

### 入力画面 (`entry_screen.dart`)
- **タイトル**: `SakuToko | 記録` に更新。
- **スナックバー**: 保存完了時のメッセージを「食費/交通費 ¥XXX を記録しました！」に統一。

### 履歴画面 (`history_screen.dart`)
- **タイトル**: `YYYY年M月 | SakuToko` に更新。

### 設定画面 (`settings_screen.dart`)
- **ヘルプダイアログ**: タイトルを `SakuToko の使い方` に変更し、以下のコンセプト文を反映。
  - **1. 割く**: リソースの決断と記録。
  - **2. 咲く**: 未来の体験。
  - **3. トコトコ**: りりむとの伴走。

---

## ✅ 実装ステータス
- すべての実装作業は完了しており、`docs/kakeibo_cursorrules.md` にも今後の開発における名称厳守ルール（SakuToko / りりむ）が追記されています。
