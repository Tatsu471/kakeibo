import 'dart:ui';
import 'package:flutter/material.dart';
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
            const Spacer(),
            // 織璃無キャラクタープレースホルダー
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(isDark ? 0.2 : 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.secondary.withOpacity(0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '織璃無\n(画像配置予定)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
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
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface.withOpacity(0.25)
                  : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? colorScheme.secondary.withOpacity(0.25)
                    : Colors.white.withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 2.0,
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
