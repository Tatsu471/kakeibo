import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

                    // 直近6ヶ月分をグラフ用に抽出（日付昇順）
                    final chartData = summaries.reversed.toList();
                    if (chartData.length > 6) {
                      chartData.removeRange(0, chartData.length - 6);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: summaries.length + 1, // グラフの分 +1
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _MonthlyTrendChart(data: chartData, isDark: isDark);
                        }
                        
                        final summary = summaries[index - 1];
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

class _MonthlyTrendChart extends StatelessWidget {
  final List<MonthlySummary> data;
  final bool isDark;

  const _MonthlyTrendChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final month = data[index].dateKey.split('-')[1];
                    return Text('${int.parse(month)}月', 
                      style: TextStyle(fontSize: 10, color: colorScheme.onBackground.withOpacity(0.5)));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.foodTotal + entry.value.transportTotal,
                  width: 16,
                  color: Colors.transparent, // 背景
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: [
                    BarChartRodStackItem(0, entry.value.foodTotal, colorScheme.secondary),
                    BarChartRodStackItem(entry.value.foodTotal, 
                      entry.value.foodTotal + entry.value.transportTotal, colorScheme.tertiary),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    double max = 0;
    for (var s in data) {
      if (s.foodTotal + s.transportTotal > max) max = s.foodTotal + s.transportTotal;
    }
    return max * 1.2 + 1000;
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
