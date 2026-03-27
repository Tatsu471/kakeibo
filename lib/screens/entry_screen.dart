import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/expense_service.dart';

/// 記録入力画面：タブ切り替え + 独自電卓キーパッド
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _memoController = TextEditingController();

  String _displayValue = '0'; // 電卓に表示する数値文字列
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // ===== 電卓ロジック =====
  void _onKeyTap(String key) {
    setState(() {
      if (key == 'C') {
        _displayValue = '0';
      } else if (key == '⌫') {
        if (_displayValue.length <= 1) {
          _displayValue = '0';
        } else {
          _displayValue = _displayValue.substring(0, _displayValue.length - 1);
        }
      } else if (key == '.') {
        if (!_displayValue.contains('.')) {
          _displayValue += '.';
        }
      } else {
        if (_displayValue == '0') {
          _displayValue = key;
        } else {
          if (_displayValue.length < 9) { // 最大9桁
            _displayValue += key;
          }
        }
      }
    });
  }

  // ===== 保存処理 =====
  Future<void> _save() async {
    final amount = double.tryParse(_displayValue);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('金額が未入力です'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final category = _tabController.index == 0 ? 'food' : 'transport';
      await _expenseService.addExpense(Expense(
        amount: amount,
        category: category,
        date: DateTime.now(),
        memo: _memoController.text.trim(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category == 'food' ? '食費' : '交通費'} ¥${amount.toStringAsFixed(0)} を記録しました！',
            ),
            backgroundColor: const Color(0xFF2E8F7D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(); // ホーム画面に戻る
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
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
              // ===== AppBar 相当 =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: colorScheme.onBackground,
                    ),
                    Expanded(
                      child: Text(
                        '支出を記録',
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

              // ===== タブバー（食費 / 交通費）=====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surface.withOpacity(0.2)
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        labelColor: isDark ? colorScheme.onPrimary : Colors.white,
                        unselectedLabelColor: colorScheme.onBackground.withOpacity(0.5),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: '🍚  食費'),
                          Tab(text: '🚃  交通費'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ===== 金額ディスプレイ =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surface.withOpacity(0.25)
                            : Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '¥ $_displayValue',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.secondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ===== メモ入力 =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: TextField(
                  controller: _memoController,
                  style: TextStyle(color: colorScheme.onBackground),
                  decoration: InputDecoration(
                    hintText: 'メモ（任意）例：ランチ、Suicaチャージ',
                    hintStyle: TextStyle(
                        color: colorScheme.onBackground.withOpacity(0.4),
                        fontSize: 13),
                    prefixIcon: Icon(Icons.edit_note,
                        color: colorScheme.onBackground.withOpacity(0.4)),
                    filled: true,
                    fillColor: isDark
                        ? colorScheme.surface.withOpacity(0.15)
                        : Colors.white.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ===== 電卓キーパッド =====
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.85, // スマホで縦長になりすぎないように調整
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _Keypad(onKey: _onKeyTap),
                    ),
                  ),
                ),
              ),

              // ===== 保存ボタン =====
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('記録する',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 電卓キーパッドウィジェット =====
class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  const _Keypad({required this.onKey});

  static const _keys = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['C', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: _keys.map((row) {
        return Expanded(
          child: Row(
            children: row.map((key) {
              final isSpecial = key == 'C' || key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onKey(key),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSpecial
                                  ? colorScheme.secondary.withOpacity(
                                      isDark ? 0.25 : 0.15)
                                  : isDark
                                      ? colorScheme.surface.withOpacity(0.25)
                                      : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              key,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSpecial
                                    ? colorScheme.secondary
                                    : colorScheme.onBackground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
