# 📖 STEP 4 実装解説ドキュメント
## 〜振り返りリスト画面〜

> **対象読者**: 新卒エンジニアや Flutter / Firestore 初心者の方
> **ゴール**: リスト表示・空の状態・日付フォーマットの実装パターンを理解すること

---

## 🗂️ このSTEPで変更したもの

```
kakeibo/
├── lib/
│   ├── main.dart                   ← 日本語ロケール初期化を追加
│   └── screens/
│       └── history_screen.dart    ← スケルトンから本実装へ（大幅更新）
└── pubspec.yaml                    ← intl パッケージを追加
```

---

## 1. `pubspec.yaml` に追加したパッケージ

```yaml
intl: ^0.19.0  # 日付・数値のロケール対応フォーマット
```

`intl`（internationalization の略）パッケージは、日付や数値を
特定の国の表現形式に変換するためのライブラリです。

```dart
// 例：日本語の曜日付き日付
DateFormat('M/d (E)', 'ja').format(DateTime.now())
// → "3/26 (木)"
```

---

## 2. `lib/main.dart` の追加 ― ロケール初期化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja', null); // ← 追加！
  await Firebase.initializeApp(...);
  runApp(const KakeiboApp());
}
```

> ⚠️ **なぜこれが必要？ → ハマりポイント**
> `DateFormat('M/d (E)', 'ja')` のように「日本語（ja）」を指定して
> フォーマットするには、事前にロケールデータをメモリに読み込む必要があります。
> 読み込まずに使うと `LocaleDataException` という赤いエラーが発生します。
> `initializeDateFormatting('ja', null)` でこのデータを先に準備します。

---

## 3. `lib/screens/history_screen.dart` ― 振り返り画面

### 全体の構造

```
Container（グラデーション背景）
└── SafeArea
    └── Column（縦並び）
        ├── ヘッダー（「2026年3月の記録」）
        ├── 織璃無の吹き出し（固定テキスト）
        └── Expanded
            └── StreamBuilder
                ├── ローディング中 → CircularProgressIndicator
                ├── データなし    → 「まだ記録がありません」
                └── データあり   → ListView.builder（リスト）
```

### 織璃無の固定テキスト（吹き出し）

```dart
Row(
  children: [
    // 織璃無アイコン（円形プレースホルダー）
    Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, ...),
      child: Text('織'), // 画像が決まったら Image.asset に差し替え予定
    ),
    Expanded(
      child: Text('過去の記録だね。どう感じる？'),
    ),
  ],
),
```

### 3つの状態を分岐する StreamBuilder

```dart
StreamBuilder<List<Expense>>(
  stream: expenseService.monthlyExpenses(),
  builder: (context, snapshot) {

    // ① まだデータが届いていない（通信中）
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }

    final expenses = snapshot.data ?? [];

    // ② データはあるが中身が空（記録がない）
    if (expenses.isEmpty) {
      return Text('まだ記録がありません');
    }

    // ③ データがある → リスト表示
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        return _ExpenseListItem(expense: expenses[index]);
      },
    );
  },
),
```

> 💡 **`snapshot.data ?? []` の `??` とは？**
> `??` は「左側が null なら右側を使う」という演算子です。
> データが届く前は `snapshot.data` が null になるため、
> `?? []`（nullなら空リスト）でクラッシュを防いでいます。

### _ExpenseListItem ― 各リスト行の見た目

各行に表示する情報：

| 要素 | 内容 |
|---|---|
| アイコン | 食費 🍚 / 交通費 🚃 |
| タイトル | メモがあればメモ、なければカテゴリ名 |
| サブテキスト | 日付 + 時刻（例：`3/26 (木) 13:25`） |
| 金額 | カテゴリ色で強調表示 |

```dart
// メモがなければカテゴリ名を代わりに表示
Text(expense.memo.isEmpty ? (isFood ? '食費' : '交通費') : expense.memo)
```

---

## 4. `ExpenseService.monthlyExpenses()` ― 日付降順で全件取得

```dart
Stream<List<Expense>> monthlyExpenses() {
  return _expensesRef
      .where('date', isGreaterThanOrEqualTo: startOfMonth)
      .where('date', isLessThan: endOfMonth)
      .orderBy('date', descending: true) // ← 新しい順（降順）
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList());
}
```

> 💡 **降順ってなに？**
> `descending: true` = 大きい順・新しい順。
> `descending: false`（デフォルト）= 小さい順・古い順。
> 振り返り画面では「最新の記録を上に」表示したいため降順にしています。

---

## 5. トラブルシューティング記録

| エラー | 原因 | 解決策 |
|---|---|---|
| `LocaleDataException` | `DateFormat('ja')` 使用前にロケール初期化が必要 | `main()` に `initializeDateFormatting('ja', null)` を追加 |

---

## 6. STEP 4 受け入れテスト結果

| テスト内容 | 結果 |
|---|---|
| グラフアイコンで振り返り画面に切り替わるか | ✅ |
| STEP 3で記録したデータが降順でリスト表示されるか | ✅ |
| 各行にアイコン・メモ・日付・金額が表示されるか | ✅ |
| 「過去の記録だね。どう感じる？」の吹き出しが表示されるか | ✅ |

---

## 📌 次のSTEP 5 でやること

- 不要ファイルの整理と `/audit` ワークフローの実行
- Netlify または Firebase Hosting へのデプロイ
- 本番環境URLで一連の動作確認

## 📌 Phase 2 候補（MVPクリア後）

| 機能 | 技術 |
|---|---|
| 折れ線/棒グラフで月間推移を可視化 | `fl_chart` パッケージ |
| ダーク/ライトモードの手動切り替え | `Provider` や `Riverpod` での状態管理 |
| 設定画面（ログアウト・プロフィール） | 追加画面の実装 |
| OCR（レシート自動読み取り） | Google ML Kit |
