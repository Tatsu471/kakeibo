# 📖 Phase 2-1: GitHub 連携と自動デプロイ (CI/CD)
## 〜「保存」から「自動配送」へ〜

> **対象読者**: Git の基本はわかるが、CI/CD や GitHub Actions は初めての方
> **ゴール**: なぜ GitHub Actions を使うのか、何が自動化されたのかを理解すること

---

## 1. Git 連携 vs GitHub Actions (CI/CD)

これまでは「コードの保存（Git）」と「公開作業（手動デプロイ）」が別々でした。

| 項目 | 通常の Git 連携 | GitHub Actions (導入後) |
| :--- | :--- | :--- |
| **役割** | コードの履歴保存・バックアップ | **自動ビルド・自動デプロイ** |
| **おもな作業** | `git push` (保存) | `git push` → **あとは放置** |
| **作業場所** | あなたの PC | GitHub のサーバー上 (仮想マシン) |
| **メリット** | 過去の状態に戻せる | デプロイの手間がゼロになる |

### CI/CD とは？
- **CI (Continuous Integration)**: 継続的インテグレーション。コードを push するたびに、自動でエラーがないかチェックしたりビルドしたりすること。
- **CD (Continuous Deployment)**: 継続的デプロイ。テストやビルドが成功したら、そのまま本番環境（Firebase Hosting）へ自動で公開すること。

---

## 2. GitHub Actions の裏側で行われていること

`.github/workflows/deploy.yml` に書かれた指示に従って、GitHub の向こう側で以下のロボット作業が行われています。

1. **Checkout**: GitHub にある最新のコードを手元（仮想マシン）に持ってくる。
2. **Setup Flutter**: まっさらの PC に Flutter をインストールする。
3. **Restore Secrets**: GitHub に秘密に隠しておいた `firebase_options.dart` を復元する。
4. **Build**: `flutter build web --release` を実行して、公開用のファイルを作る。
5. **Deploy**: Firebase Hosting にファイルを送り込み、サイトを更新する。

---

## 3. なぜ `firebase_options.dart` を Secrets に隠すの？

設計図や初期設定でも触れましたが、このファイルには **Firebase の API キー** が含まれています。
GitHub リポジトリが Public（公開）の場合、これをそのまま push すると全世界に合鍵を渡すことになります。

そこで：
1. **ローカル**: `.gitignore` で push 対象から外す（合鍵を外に持ち出さない）。
2. **GitHub**: `Secrets` という安全な金庫に中身を保管する。
3. **Actions**: ビルドする瞬間だけ金庫から中身を取り出して使う。

これで安全性を保ちつつ、自動デプロイを実現しています。

---

## 4. 今後の開発サイクル

これからは、コードを修正して push するだけで本番環境が更新されます。

```bash
git add .
git commit -m "修正内容"
git push origin main
```

これだけで GitHub Actions が動き出し、数分後には https://kakeibo-9b5fa.web.app が最新版になります。
ビルドの進捗は GitHub の **Actions** タブでいつでも確認できます。
