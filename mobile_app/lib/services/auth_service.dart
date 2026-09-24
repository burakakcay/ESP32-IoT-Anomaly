import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<String> getIdToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Oturum açılmamış.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw StateError('Kimlik belirteci alınamadı.');
    }

    return token;
  }
}
