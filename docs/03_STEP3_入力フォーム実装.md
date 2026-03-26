# 📖 STEP 3 実装解説ドキュメント
## 〜手動入力フォームとHome連携〜

> **対象読者**: 新卒エンジニアや Flutter / Firestore 初心者の方
> **ゴール**: データの「書き込み」「リアルタイム取得」「画面への反映」の流れを理解すること

---

## 🗂️ このSTEPで作ったもの・変えたもん

```
kakeibo/lib/
├── services/
│   └── expense_service.dart   ← Firestoreとのやりとりを担当（新規作成）
└── screens/
    ├── entry_screen.dart      ← 記録入力画面（スケルトンから本実装へ）
    └── home_screen.dart       ← 固定値→Firestoreリアルタイムデータへ変更
```


---

## 1. `lib/services/expense_service.dart` ― データ操作の司令塔

### Expense モデルクラス

**モデル**とは「データの形を定義したもの」です。

```dart
class Expense {
  final double amount;    // 金額
  final String category;  // 'food' or 'transport'
  final DateTime date;    // 日時
  final String memo;      // メモ
}
```

Firestoreに保存するときは「Dartのオブジェクト」→「Map（辞書形式）」に変換し、
読み込むときは逆に「Map」→「Dartのオブジェクト」に変換します。
これを担う `toMap()` / `fromDoc()` メソッドがモデルクラスに入っています。

### ExpenseService クラス

```dart
// ユーザーごとのパス: users/{uid}/expenses
CollectionReference get _expensesRef {
  final uid = _auth.currentUser!.uid;
  return _db.collection('users').doc(uid).collection('expenses');
}
```

> 💡 **なぜ `users/{uid}/expenses` というパス設計？**
> `uid` はFirebase Authが発行する「そのユーザーだけに割り当てられたID」です。
> Firestoreのセキュリティルールで `request.auth.uid == userId` という条件にすることで、
> 自分の `uid` フォルダにしかアクセスできなくなります。

### Firestoreへの書き込み

```dart
Future<void> addExpense(Expense expense) async {
  await _expensesRef.add(expense.toMap());
}
```

`.add()` を呼ぶだけで自動的にIDが生成されてドキュメントが作成されます。

### 月間合計のリアルタイムStream

```dart
Stream<double> _monthlyTotal(String category) {
  // Firestoreに「今月のデータ全部」を問い合わせる
  return _expensesRef
      .where('date', isGreaterThanOrEqualTo: startOfMonth)
      .where('date', isLessThan: endOfMonth)
      .snapshots()  // ← リアルタイム更新を受け取る
      .map((snapshot) => snapshot.docs
          .where((doc) => doc.data()['category'] == category) // Dart側でカテゴリ絞り込み
          .fold(0, (sum, doc) => sum + doc.data()['amount']));
}
```

> ⚠️ **なぜカテゴリ絞り込みをDart側で行うの？**
> FirestoreはFirebase内で「複数条件の複合検索」をするには事前に「複合インデックス（目次）」を作る必要があります。
> 「日付」と「カテゴリ」を同時に使う検索には、この複合インデックスが必要でした。
> インデックス未作成のままだとFirestoreは空の結果を返します。
> 今回はインデックス作成を避けるため、日付だけをFirestoreに問い合わせ、
> カテゴリの絞り込みはDart（アプリ内）で行う方法を採用しています。

---

## 2. `lib/screens/entry_screen.dart` ― 記録入力画面

### 全体の構造

```
Column（縦並び）
├── AppBar相当（✕ボタン＋タイトル）
├── TabBar（食費 / 交通費 切り替え）
├── 金額ディスプレイ（¥1200 のような表示）
├── メモ入力フィールド
├── 電卓キーパッド（_Keypad）
└── 「記録する」ボタン
```

### タブ切り替え（TabController）

```dart
// initStateで初期化（2タブ = length: 2）
_tabController = TabController(length: 2, vsync: this);

// 保存時にどちらのタブか判定
final category = _tabController.index == 0 ? 'food' : 'transport';
```

### 電卓ロジック（_onKeyTap）

キーパッドの各ボタンが押されるたびに文字列として金額を組み立てます。

```dart
void _onKeyTap(String key) {
  if (key == 'C') {
    _displayValue = '0';           // クリア
  } else if (key == '⌫') {
    _displayValue = _displayValue.substring(0, length - 1); // 1文字削除
  } else {
    _displayValue += key;          // 数字を末尾に追加
  }
}
```

### 保存処理とバリデーション（入力チェック）

```dart
Future<void> _save() async {
  final amount = double.tryParse(_displayValue);

  // バリデーション: 金額が0以下なら保存しない
  if (amount == null || amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('金額が未入力です')), // エラー通知
    );
    return; // ← ここでreturnして処理を止める
  }

  await _expenseService.addExpense(...); // Firestoreに保存

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('記録しました！')), // 成功通知
  );
  Navigator.of(context).pop(); // ホーム画面に戻る
}
```

---

## 3. `lib/screens/home_screen.dart` の変更 ― リアルタイム表示

### 修正前：固定値をハードコード

```dart
// ❌ 修正前（データが変わっても画面は変わらない）
GlassCard(title: '今月の食費', amount: '¥45,000')
```

### 修正後：StreamBuilder でリアルタイム更新

```dart
// ✅ 修正後（保存するたびに自動で数字が更新される）
StreamBuilder<double>(
  stream: expenseService.monthlyFoodTotal(), // 川（Stream）を監視
  builder: (context, snapshot) {
    final total = snapshot.data ?? 0; // データがなければ0
    return GlassCard(
      title: '今月の食費',
      amount: '¥${total.toStringAsFixed(0)}', // 小数点なし表示
    );
  },
),
```

> 💡 **`StreamBuilder` とは？**
> 川（Stream）を常に監視して、新しいデータが流れてきたら自動的に画面を再描画するウィジェットです。
> 記録を保存した瞬間、Firestoreがアプリへ「更新があったよ！」と通知し、
> `StreamBuilder` がそれを受け取って合計値を更新・再表示します。

---

## 4. STEP 3 受け入れテスト結果

| テスト内容 | 結果 |
|---|---|
| ＋ボタンで入力画面が開くか | ✅ |
| 食費タブ・交通費タブが切り替わるか | ✅ |
| 電卓で金額を入力できるか | ✅ |
| 「記録する」で緑のスナックバーが出てホームに戻るか | ✅ |
| ホーム画面の合計金額が増えるか | ✅ |
| 金額未入力で「記録する」→ エラー表示されるか | ✅ |

---

## 📌 次のSTEP 4 でやること

- 振り返り画面：当月の全支出を日付降順でリスト表示
- 織璃無の固定テキスト（「過去の記録だね。どう感じる？」）
- 異常系：未入力で保存した場合のエラーハンドリング（STEP 3で実装済み）
