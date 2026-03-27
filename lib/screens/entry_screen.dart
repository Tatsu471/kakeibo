import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                        'SakuToko | 記録',
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ));
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          '¥ $_displayValue',
                          key: ValueKey<String>(_displayValue), // 変更を検知するために必要
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.secondary,
                            letterSpacing: 2,
                            // 数字部分のフォント比較（適宜メインに合わせる）
                            fontFamily: GoogleFonts.outfit().fontFamily,
                          ),
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
    return Column(
      children: _keys.map((row) {
        return Expanded(
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: _KeypadButton(
                  label: key,
                  onTap: () => onKey(key),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ===== アニメーション付き電卓ボタン =====
class _KeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpecial = widget.label == 'C' || widget.label == '⌫';

    // 期間限定：フォント比較用のロジック
    // 1~4 は Outfit, その他は Space Mono
    final intValue = int.tryParse(widget.label);
    final TextStyle labelStyle = (intValue != null && intValue >= 1 && intValue <= 4)
        ? GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 26)
        : GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 24);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isSpecial
                      ? colorScheme.secondary.withOpacity(isDark ? 0.25 : 0.15)
                      : isDark
                          ? colorScheme.surface.withOpacity(0.25)
                          : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: labelStyle.copyWith(
                    color: isSpecial ? colorScheme.secondary : colorScheme.onBackground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
