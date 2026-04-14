import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/expense_service.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseService = ExpenseService();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [colorScheme.background, Color.lerp(colorScheme.background, colorScheme.surface, 0.5)!]
                : [colorScheme.background, Color.lerp(colorScheme.background, colorScheme.primary, 0.06)!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== AppBar =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: colorScheme.onBackground,
                    ),
                    Expanded(
                      child: Text(
                        '過去のアーカイブ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // バランス用
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'これまでの月ごとの総支出（食費・交通費）を振り返ります。',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),

              // ===== 月別サマリーリスト =====
              Expanded(
                child: StreamBuilder<List<MonthlySummary>>(
                  stream: expenseService.getMonthlySummaries(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final summaries = snapshot.data ?? [];
                    if (summaries.isEmpty) {
                      return Center(
                        child: Text(
                          '記録がありません',
                          style: TextStyle(color: colorScheme.onBackground.withOpacity(0.3)),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: summaries.length,
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        final parts = summary.dateKey.split('-');
                        final displayMonth = '${parts[0]}年${int.parse(parts[1])}月';

                        return _SummaryCard(
                          title: displayMonth,
                          foodTotal: summary.foodTotal,
                          transportTotal: summary.transportTotal,
                          isDark: isDark,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double foodTotal;
  final double transportTotal;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.foodTotal,
    required this.transportTotal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = foodTotal + transportTotal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.08 : 0.6),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '¥${total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AmountBar(
                        icon: Icons.restaurant_rounded,
                        color: colorScheme.secondary,
                        amount: foodTotal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AmountBar(
                        icon: Icons.directions_bus_rounded,
                        color: colorScheme.tertiary,
                        amount: transportTotal,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountBar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double amount;

  const _AmountBar({required this.icon, required this.color, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '¥${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
