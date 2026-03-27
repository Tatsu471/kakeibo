import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart' show HomeShell;
import 'screens/login_screen.dart';

// テーマモードを管理するグローバルなNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  // Flutterのエンジン起動を保証してからFirebaseを初期化
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja', null); // 日本語ロケールを初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KakeiboApp());
}

class KakeiboApp extends StatelessWidget {
  const KakeiboApp({super.key});

  // ===== 織璃無テーマカラー定義 =====
  static const Color _lapisLazuli = Color(0xFF1A237E); // 瑠璃色
  static const Color _antiqueGold = Color(0xFFE0B94F);  // 黄金
  static const Color _seaTeal    = Color(0xFF2E8F7D);  // 静かな青緑
  static const Color _lilyWhite  = Color(0xFFFDFDFD);  // 純白

  // --------- ライトテーマ -----------
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _lapisLazuli,
      onPrimary: _lilyWhite,
      secondary: _antiqueGold,
      onSecondary: _lapisLazuli,
      tertiary: _seaTeal,
      onTertiary: _lilyWhite,
      surface: _lilyWhite,
      onSurface: _lapisLazuli,
      background: Color(0xFFF0F4F8),
      onBackground: _lapisLazuli,
      error: Color(0xFFB00020),
      onError: _lilyWhite,
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    textTheme: GoogleFonts.zenMaruGothicTextTheme(
      ThemeData.light().textTheme,
    ),
  );

  // --------- ダークテーマ -----------
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _antiqueGold,
      onPrimary: _lapisLazuli,
      secondary: _seaTeal,
      onSecondary: _lilyWhite,
      tertiary: _antiqueGold,
      onTertiary: _lapisLazuli,
      surface: Color(0xFF1E2A6B),
      onSurface: _lilyWhite,
      background: _lapisLazuli,
      onBackground: _lilyWhite,
      error: Color(0xFFCF6679),
      onError: Color(0xFF1C0008),
    ),
    scaffoldBackgroundColor: _lapisLazuli,
    textTheme: GoogleFonts.zenMaruGothicTextTheme(
      ThemeData.dark().textTheme,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'SakuToko',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: currentMode,
          // 認証状態を監視して画面を振り分ける
          home: const AuthGate(),
        );
      },
    );
  }
}

/// 認証状態に応じてログイン画面 or ホーム画面を表示するゲート
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 接続待機中はスプラッシュ的なローディング表示
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ログイン済み → ホーム画面
        if (snapshot.hasData) {
          return const HomeShell();
        }
        // 未ログイン → ログイン画面
        return const LoginScreen();
      },
    );
  }
}
