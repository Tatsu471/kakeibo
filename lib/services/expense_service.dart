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

/// 月別サマリのモデルクラス
class MonthlySummary {
  final String dateKey; // YYYY-MM
  final double foodTotal;
  final double transportTotal;

  MonthlySummary({
    required this.dateKey,
    required this.foodTotal,
    required this.transportTotal,
  });

  factory MonthlySummary.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MonthlySummary(
      dateKey: doc.id,
      foodTotal: (data['foodTotal'] as num?)?.toDouble() ?? 0.0,
      transportTotal: (data['transportTotal'] as num?)?.toDouble() ?? 0.0,
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

  /// 現在のユーザーのmonthly_summariesコレクション参照
  CollectionReference<Map<String, dynamic>> get _summariesRef {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('monthly_summaries');
  }

  /// 支出を追加する
  Future<void> addExpense(Expense expense) async {
    final batch = _db.batch();
    
    // 1. expensesへの追加
    final newDocRef = _expensesRef.doc();
    batch.set(newDocRef, expense.toMap());

    // 2. monthly_summariesの更新
    final dateKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
    final summaryRef = _summariesRef.doc(dateKey);
    
    batch.set(summaryRef, {
      if (expense.category == 'food') 'foodTotal': FieldValue.increment(expense.amount),
      if (expense.category == 'transport') 'transportTotal': FieldValue.increment(expense.amount),
    }, SetOptions(merge: true));

    await batch.commit();
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
    final doc = await _expensesRef.doc(id).get();
    if (!doc.exists) return;

    final expense = Expense.fromDoc(doc);
    final batch = _db.batch();

    batch.delete(_expensesRef.doc(id));

    final dateKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
    final summaryRef = _summariesRef.doc(dateKey);
    
    batch.set(summaryRef, {
      if (expense.category == 'food') 'foodTotal': FieldValue.increment(-expense.amount),
      if (expense.category == 'transport') 'transportTotal': FieldValue.increment(-expense.amount),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// 当月より前の詳細支出データ（expenses）のみを全て削除する
  Future<int> deletePastDetailExpenses() async {
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    
    final snapshot = await _expensesRef
        .where('date', isLessThan: Timestamp.fromDate(startOfCurrentMonth))
        .get();
    
    if (snapshot.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    return snapshot.docs.length;
  }

  /// 過去の月別サマリーを取得するStream
  Stream<List<MonthlySummary>> getMonthlySummaries() {
    return _summariesRef.orderBy(FieldPath.documentId, descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MonthlySummary.fromDoc(doc)).toList();
    });
  }

  /// 全データをCSV形式で取得する（エクスポート用）
  Future<String> exportDataAsCSV() async {
    final snapshot = await _expensesRef.orderBy('date', descending: true).get();
    final buffer = StringBuffer();
    
    // ヘッダー
    buffer.writeln('日付,カテゴリ,金額,メモ');
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(date);
      final category = data['category'] == 'food' ? '食費' : '交通費';
      final amount = data['amount'];
      final memo = (data['memo'] as String).replaceAll(',', ' '); // CSVとしてのカンマを避ける
      
      buffer.writeln('$dateStr,$category,$amount,$memo');
    }
    return buffer.toString();
  }

  /// 本人の全てのデータ（支出、サマリー）を物理削除する
  Future<void> deleteAllUserData() async {
    final batch = _db.batch();
    
    // 1. expensesの全削除
    final expenses = await _expensesRef.get();
    for (var doc in expenses.docs) {
      batch.delete(doc.reference);
    }
    
    // 2. monthly_summariesの全削除
    final summaries = await _summariesRef.get();
    for (var doc in summaries.docs) {
      batch.delete(doc.reference);
    }
    
    // 3. ユーザー自身のドキュメントも削除（もし情報を持たせていれば）
    final uid = _auth.currentUser!.uid;
    batch.delete(_db.collection('users').doc(uid));

    await batch.commit();
  }
}
