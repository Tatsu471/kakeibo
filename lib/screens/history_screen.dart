import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';

/// 振り返り画面：カテゴリフィルタ + 日付別アコーディオン表示
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedCategory = 'all'; // all, food, transport

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseService = ExpenseService();
    final now = DateTime.now();
    final monthLabel = '${now.year}年${now.month}月 | SakuToko';

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
                    Icons.history_rounded,
                    color: colorScheme.onBackground.withOpacity(0.35),
                    size: 22,
                  ),
                ],
              ),
            ),

            // ===== カテゴリフィルタ（チップ形式）=====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FilterChip(
                    label: 'すべて',
                    isSelected: _selectedCategory == 'all',
                    onTap: () => setState(() => _selectedCategory = 'all'),
                  ),
                  _FilterChip(
                    label: '食費',
                    isSelected: _selectedCategory == 'food',
                    onTap: () => setState(() => _selectedCategory = 'food'),
                  ),
                  _FilterChip(
                    label: '交通費',
                    isSelected: _selectedCategory == 'transport',
                    onTap: () => setState(() => _selectedCategory = 'transport'),
                  ),
                ],
              ),
            ),

            // ===== 支出リスト（Firestoreリアルタイム＋グループ化）=====
            Expanded(
              child: StreamBuilder<List<Expense>>(
                stream: expenseService.monthlyExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allExpenses = snapshot.data ?? [];
                  // フィルタリング
                  final expenses = _selectedCategory == 'all'
                      ? allExpenses
                      : allExpenses.where((e) => e.category == _selectedCategory).toList();

                  if (expenses.isEmpty) {
                    return _EmptyState(isDark: isDark);
                  }

                  // 日付ごとにグループ化
                  final Map<String, List<Expense>> grouped = {};
                  for (var e in expenses) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(e.date);
                    if (grouped[dateKey] == null) grouped[dateKey] = [];
                    grouped[dateKey]!.add(e);
                  }

                  final dateKeys = grouped.keys.toList();
                  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: dateKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = dateKeys[index];
                      final dayExpenses = grouped[dateKey]!;
                      final isToday = dateKey == todayStr;

                      return _DateAccordion(
                        dateLabel: DateFormat('M/d (E)', 'ja').format(dayExpenses.first.date),
                        expenses: dayExpenses,
                        initiallyExpanded: isToday,
                        isDark: isDark,
                        index: index,
                      );
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

// ===== フィルタリング用チップ =====
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primary.withOpacity(0.8),
        labelStyle: TextStyle(color: isSelected ? Colors.white : colorScheme.onBackground.withOpacity(0.6)),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : colorScheme.onBackground.withOpacity(0.1))),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
    );
  }
}

// ===== 日付別アコーディオン =====
class _DateAccordion extends StatelessWidget {
  final String dateLabel;
  final List<Expense> expenses;
  final bool initiallyExpanded;
  final bool isDark;
  final int index;

  const _DateAccordion({
    required this.dateLabel,
    required this.expenses,
    required this.initiallyExpanded,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.4), width: 1),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: initiallyExpanded,
                        title: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: Text('¥${total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: colorScheme.primary)),
                        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        children: expenses.map((e) => _ExpenseListItem(expense: e, isDark: isDark)).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    final timeLabel = DateFormat('HH:mm').format(expense.date);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(isFood ? Icons.restaurant_rounded : Icons.directions_bus_rounded, color: accentColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.memo.isEmpty ? (isFood ? '食費' : '交通費') : expense.memo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(timeLabel, style: TextStyle(fontSize: 11, color: colorScheme.onBackground.withOpacity(0.4))),
                ],
              ),
            ),
            Text('¥${expense.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor)),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: colorScheme.error.withOpacity(0.4)),
              onPressed: () => _confirmDelete(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記録の削除'),
        content: const Text('この記録を削除してもよろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) await ExpenseService().deleteExpense(expense.id!);
  }
}

// ===== 空状態の表示 =====
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: colorScheme.onBackground.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text('記録がありません', style: TextStyle(color: colorScheme.onBackground.withOpacity(0.3))),
        ],
      ),
    );
  }
}
