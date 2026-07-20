import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around FirebaseAuth so controllers never touch the SDK
/// directly. Keeps auth error mapping and Google sign-in flow in one place.
class AuthService {
  FirebaseAuth? _authOverride;
  GoogleSignIn? _googleSignInOverride;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _authOverride = auth,
        _googleSignInOverride = googleSignIn;

  // Lazy on purpose: FirebaseAuth.instance throws until a real Firebase
  // project is configured, and AuthService is constructed unconditionally
  // by every auth screen's State — touching it eagerly here would crash
  // screen creation itself, before FirebaseStatus.isAvailable can be
  // checked. Deferring to first real use keeps the app usable pre-Firebase.
  FirebaseAuth get _auth => _authOverride ??= FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => _googleSignInOverride ??= GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
          code: 'sign-in-cancelled', message: 'Google sign-in was cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<String?> getIdToken({bool forceRefresh = false}) {
    return _auth.currentUser?.getIdToken(forceRefresh) ?? Future.value(null);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Maps FirebaseAuthException codes to user-friendly copy for toasts.
  static String friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak — use at least 8 characters';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled';
      default:
        return e.message ?? 'Authentication failed. Please try again';
    }
  }
}
