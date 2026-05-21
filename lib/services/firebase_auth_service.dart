import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Email/password diye sign in
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        debugPrint('Login error: কোনো user পাওয়া যায়নি।');
      } else if (e.code == 'wrong-password') {
        debugPrint('Login error: পাসওয়ার্ড ভুল।');
      } else {
        debugPrint('Login error: \${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Login error: \$e');
      return null;
    }
  }

  /// New user register korte
  Future<User?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        debugPrint('Register error: পাসওয়ার্ড খুব দুর্বল।');
      } else if (e.code == 'email-already-in-use') {
        debugPrint('Register error: এই email আগে থেকেই registered।');
      } else {
        debugPrint('Register error: \${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Register error: \$e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('Sign out সফল হয়েছে।');
    } catch (e) {
      debugPrint('Sign out error: \$e');
    }
  }

  /// Current logged in user
  User? get currentUser {
    return _auth.currentUser;
  }

  /// Auth state changes listen korte
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}