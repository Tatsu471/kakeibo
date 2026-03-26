import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Googleログインボタン付きのログイン画面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // 成功すると authStateChanges が発火し、自動でホーム画面へ遷移
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログインに失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                ? [
                    colorScheme.background,
                    Color.lerp(colorScheme.background, colorScheme.surface, 0.5)!,
                  ]
                : [
                    colorScheme.background,
                    Color.lerp(colorScheme.background, colorScheme.primary, 0.06)!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 織璃無キャラクターエリア
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(isDark ? 0.2 : 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '織璃無',
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // タイトル
                  Text(
                    '織璃無の家計簿',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'あなたの物語に、今日も良き一行が加わりますように。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onBackground.withOpacity(0.5),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Google ログインボタン
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? colorScheme.surface.withOpacity(0.3)
                                : Colors.white.withOpacity(0.8),
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? colorScheme.secondary.withOpacity(0.3)
                                    : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Googleのシンボルカラーを使ったGアイコン
                                    const Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4285F4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Googleでログイン',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
