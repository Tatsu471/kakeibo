import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../main.dart'; // themeNotifier のためにインポート

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
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _ThemeSelectionSheet(),
                );
              },
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'ヘルプ',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => _HelpDialog(),
                );
              },
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

// ============================================================
// テーマ選択用のボトムシート
// ============================================================
class _ThemeSelectionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'デザイン設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _ThemeOption(
            icon: Icons.brightness_auto,
            label: 'システム設定に従う',
            mode: ThemeMode.system,
          ),
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            label: 'ライトモード',
            mode: ThemeMode.light,
          ),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: 'ダークモード',
            mode: ThemeMode.dark,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode mode;

  const _ThemeOption({required this.icon, required this.label, required this.mode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: themeNotifier.value == mode ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        themeNotifier.value = mode;
        Navigator.pop(context);
      },
    );
  }
}

// ============================================================
// ヘルプダイアログ
// ============================================================
class _HelpDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.help_outline, color: colorScheme.secondary),
          const SizedBox(width: 8),
          const Text('SakuToko の使い方'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. 割く（記録する）', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('下の「＋」ボタンから、食費や交通費をサクッと入力。金額は正確に、感情は横に置いて記録しましょう。'),
          SizedBox(height: 12),
          Text('2. 咲く（振り返る）', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('浮いた食費が、豊かな移動体験として花開く。推移グラフで資金の循環を確認しましょう。'),
          SizedBox(height: 12),
          Text('3. トコトコ (Lilim)', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('りりむはあなたの歩みを静かに見守り、トコトコと伴走してくれます。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
