import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:social_media_app/services/firebase_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static Future<User?> registerWithEmail(
    String email,
    String password,
    String username,
    String photoUrl,
  ) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(username);
      await credential.user?.updatePhotoURL(photoUrl);

      await FirebaseService.updateUserProfile(
        userId: credential.user!.uid,
        username: username,
        photoURL: photoUrl,
      );

      await credential.user?.sendEmailVerification();
      return credential.user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  static Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('forget password error: $e');
      rethrow;
    }
  }

  static Future<void> updateProfile(String username) async {
    if (_auth.currentUser == null) return;

    try {
      await _auth.currentUser?.updateDisplayName(username);
      await FirebaseService.updateUserProfile(
        userId: _auth.currentUser!.uid,
        username: username,
        photoURL: _auth.currentUser!.photoURL!,
      );
      await _auth.currentUser?.reload();
    } catch (e) {
      print('Profile update error: $e');
      rethrow;
    }
  }
}
