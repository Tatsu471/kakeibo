import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';

/// 振り返り画面：当月の支出を日付降順でリスト表示 + 織璃無の固定テキスト
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseService = ExpenseService();
    final now = DateTime.now();
    final monthLabel = '${now.year}年${now.month}月の記録';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [colorScheme.background,
                 Color.lerp(colorScheme.background, colorScheme.surface, 0.5)!]
              : [colorScheme.background,
                 Color.lerp(colorScheme.background, colorScheme.primary, 0.06)!],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ===== ヘッダー =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onBackground,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Icon(
                    Icons.history,
                    color: colorScheme.onBackground.withOpacity(0.35),
                    size: 20,
                  ),
                ],
              ),
            ),

            // ===== 織璃無の固定テキスト（吹き出し風）=====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surface.withOpacity(0.2)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 織璃無アイコン（円形プレースホルダー）
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.secondary.withOpacity(0.15),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '織',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '過去の記録だね。どう感じる？',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onBackground.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ===== 支出リスト（Firestoreリアルタイム）=====
            Expanded(
              child: StreamBuilder<List<Expense>>(
                stream: expenseService.monthlyExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data ?? [];

                  if (expenses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: colorScheme.onBackground.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'まだ記録がありません',
                            style: TextStyle(
                              color: colorScheme.onBackground.withOpacity(0.35),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return _ExpenseListItem(expense: expense, isDark: isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 支出リストアイテム =====
class _ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final bool isDark;

  const _ExpenseListItem({required this.expense, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFood = expense.category == 'food';
    final accentColor = isFood ? colorScheme.secondary : colorScheme.tertiary;
    final dateLabel = DateFormat('M/d (E)', 'ja').format(expense.date);
    final timeLabel = DateFormat('HH:mm').format(expense.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.08 : 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // カテゴリアイコン
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isFood ? Icons.restaurant_rounded : Icons.directions_bus_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // メモ＋日時
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.memo.isEmpty
                            ? (isFood ? '食費' : '交通費')
                            : expense.memo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateLabel  $timeLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onBackground.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                // 金額
                Text(
                  '¥${expense.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
