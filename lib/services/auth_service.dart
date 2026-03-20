import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current User
  User? get currentUser => _auth.currentUser;

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign In — Web Compatible
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.setCustomParameters({
        'login_hint': 'user@example.com'
      });

      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);

      return userCredential.user;
    } catch (e) {
      print('Google Sign In Error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Display Name
  String get userName =>
      _auth.currentUser?.displayName ?? 'User';

  // Get User Email
  String get userEmail =>
      _auth.currentUser?.email ?? '';

  // Get User Photo
  String get userPhoto =>
      _auth.currentUser?.photoURL ?? '';
}