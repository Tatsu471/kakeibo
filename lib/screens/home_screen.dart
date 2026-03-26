import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import 'entry_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

// ============================================================
// ルート画面：BottomNavをホールドして各画面を切り替えるShell
// ============================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0; // 0=Home, 1=History, 2=Settings

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surface.withOpacity(0.85)
              : Colors.white.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: colorScheme.primary.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => setState(() => _currentIndex = 2),
                  color: _currentIndex == 2
                      ? colorScheme.primary
                      : colorScheme.onBackground.withOpacity(0.4),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () {},
                  color: colorScheme.onBackground.withOpacity(0.4),
                ),
                FloatingActionButton(
                  elevation: 6,
                  backgroundColor: colorScheme.primary,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EntryScreen()),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart_outlined),
                  onPressed: () => setState(() => _currentIndex = 1),
                  color: _currentIndex == 1
                      ? colorScheme.primary
                      : colorScheme.onBackground.withOpacity(0.4),
                ),
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () => setState(() => _currentIndex = 0),
                  color: _currentIndex == 0
                      ? colorScheme.primary
                      : colorScheme.onBackground.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ホーム画面本体 (Firestoreから月間合計をリアルタイム取得)
// ============================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseService = ExpenseService();
    final now = DateTime.now();
    final monthLabel = '${now.year}年${now.month}月';

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
            // ヘッダー（月表示）
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
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '支出サマリー',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onBackground.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 今月の食費（Firestoreリアルタイム）
            StreamBuilder<double>(
              stream: expenseService.monthlyFoodTotal(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return GlassCard(
                  title: '今月の食費',
                  amount: '¥${total.toStringAsFixed(0)}',
                  accentColor: colorScheme.secondary,
                );
              },
            ),
            const SizedBox(height: 16),
            // 推移グラフ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 180,
                padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surface.withOpacity(0.15)
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.6),
                    width: 1,
                  ),
                ),
                child: StreamBuilder<List<Expense>>(
                  stream: expenseService.monthlyExpenses(),
                  builder: (context, snapshot) {
                    final expenses = snapshot.data ?? [];
                    return MonthlyTrendChart(expenses: expenses);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 今月の交通費（Firestoreリアルタイム）
            StreamBuilder<double>(
              stream: expenseService.monthlyTransportTotal(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return GlassCard(
                  title: '今月の交通費',
                  amount: '¥${total.toStringAsFixed(0)}',
                  accentColor: colorScheme.tertiary,
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 支出推移グラフ（fl_chart）
// ============================================================
class MonthlyTrendChart extends StatelessWidget {
  final List<Expense> expenses;

  const MonthlyTrendChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // カテゴリごとの日次合計を計算
    final Map<int, double> foodMap = {};
    final Map<int, double> transportMap = {};
    
    for (var exp in expenses) {
      final day = exp.date.day;
      if (exp.category == 'food') {
        foodMap[day] = (foodMap[day] ?? 0) + exp.amount;
      } else {
        transportMap[day] = (transportMap[day] ?? 0) + exp.amount;
      }
    }

    // グラフデータ作成（1日から今日まで）
    final now = DateTime.now();
    final foodSpots = <FlSpot>[];
    final transportSpots = <FlSpot>[];
    
    for (int i = 1; i <= now.day; i++) {
      foodSpots.add(FlSpot(i.toDouble(), foodMap[i] ?? 0));
      transportSpots.add(FlSpot(i.toDouble(), transportMap[i] ?? 0));
    }

    if (foodSpots.isEmpty && transportSpots.isEmpty) return const Center(child: Text('データなし'));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.onBackground.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0 && value != 1 && value != now.day) {
                  return const SizedBox();
                }
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: colorScheme.onBackground.withOpacity(0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 食費ライン
          LineChartBarData(
            spots: foodSpots,
            isCurved: true,
            color: colorScheme.secondary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.secondary.withOpacity(0.08),
            ),
          ),
          // 交通費ライン
          LineChartBarData(
            spots: transportSpots,
            isCurved: true,
            color: colorScheme.tertiary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.tertiary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// グラスモーフィズムカード
// ============================================================
class GlassCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color accentColor;

  const GlassCard({
    super.key,
    required this.title,
    required this.amount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.08 : 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onBackground.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onBackground,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accentColor == colorScheme.secondary 
                        ? Icons.restaurant_rounded 
                        : Icons.directions_bus_rounded,
                    color: accentColor,
                    size: 26,
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
