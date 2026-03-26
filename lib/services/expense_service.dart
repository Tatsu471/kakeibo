import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 支出データのモデルクラス
class Expense {
  final String? id;
  final double amount;
  final String category; // 'food' or 'transport'
  final DateTime date;
  final String memo;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.memo,
  });

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'category': category,
    'date': Timestamp.fromDate(date),
    'memo': memo,
  };

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
      memo: data['memo'] as String? ?? '',
    );
  }
}

/// Firestore の支出データを操作するサービスクラス
class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーのexpensesコレクション参照
  CollectionReference<Map<String, dynamic>> get _expensesRef {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('expenses');
  }

  /// 支出を追加する
  Future<void> addExpense(Expense expense) async {
    await _expensesRef.add(expense.toMap());
  }

  /// 当月の食費合計をリアルタイム取得するStream
  Stream<double> monthlyFoodTotal() => _monthlyTotal('food');

  /// 当月の交通費合計をリアルタイム取得するStream
  Stream<double> monthlyTransportTotal() => _monthlyTotal('transport');

  // 当月データを日付でのみ取得し、Dart側でカテゴリをフィルタ
  // （Firestoreの複合インデックス不要）
  Stream<double> _monthlyTotal(String category) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return _expensesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['category'] == category)
            .fold<double>(
              0,
              (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
            ));
  }

  /// 当月の全支出をリアルタイム取得するStream（日付降順）
  Stream<List<Expense>> monthlyExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return _expensesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList();
          // 日付降順にソート（新しい順）
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// 支出を削除する
  Future<void> deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }
}
