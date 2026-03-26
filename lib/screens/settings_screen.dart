import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// 設定画面：ユーザー情報表示 + ログアウト
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

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
            // ヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(
                children: [
                   Text(
                    '設定',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onBackground,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // ユーザープロフィールカード
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surface.withOpacity(0.25)
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          backgroundImage: user?.photoURL != null 
                              ? NetworkImage(user!.photoURL!) 
                              : null,
                          child: user?.photoURL == null 
                              ? Icon(Icons.person, size: 40, color: colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? '名前なし',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'メールアドレスなし',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 設定メニューリスト
            _SettingTile(
              icon: Icons.palette_outlined,
              title: 'デザイン設定',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'ヘルプ',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.logout,
              title: 'ログアウト',
              titleColor: Colors.redAccent,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ログアウト'),
                    content: const Text('ログアウトしてもよろしいですか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('ログアウト', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authService.signOut();
                }
              },
            ),

            const Spacer(),
            
            // バージョン情報
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Version 1.0.0 (MVP)',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onBackground.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: titleColor ?? colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: titleColor ?? colorScheme.onBackground,
          ),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.onBackground.withOpacity(0.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: colorScheme.surface.withOpacity(0.1),
      ),
    );
  }
}
