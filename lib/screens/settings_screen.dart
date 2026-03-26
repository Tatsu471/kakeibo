import 'package:flutter/material.dart';

/// 設定画面（STEP 2以降で実装予定）のスケルトン
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: colorScheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'STEP 2以降で実装予定',
              style: TextStyle(color: colorScheme.onBackground.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
