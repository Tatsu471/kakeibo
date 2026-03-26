import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication を管理するサービスクラス
/// Web向けに signInWithPopup を使用（clientID設定不要）
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーを返す（未ログインなら null）
  User? get currentUser => _auth.currentUser;

  /// 認証状態の変化を監視するストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Googleでサインイン（Webポップアップ方式）
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      // ポップアップ方式：ブラウザの小窓でGoogleアカウント選択
      return await _auth.signInWithPopup(googleProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
