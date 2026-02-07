import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  bool _initialized = false;
  bool _isMockLoggedIn = false;

  User? get currentUser => _initialized ? _auth?.currentUser : null;
  bool get isLoggedIn => currentUser != null || _isMockLoggedIn;
  String? get username => currentUser?.displayName ?? currentUser?.email ?? (_isMockLoggedIn ? "Guest User" : null);
  String? get email => currentUser?.email ?? (_isMockLoggedIn ? "guest@example.com" : null);
  String? get photoUrl => currentUser?.photoURL;

  Future<void> init() async {
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
      _initialized = true;
    } catch (e) {
      print("AuthService: Firebase not initialized. $e");
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!_initialized || _auth == null || _googleSignIn == null) {
        throw Exception("Firebase not initialized. Cannot sign in.");
    }
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> login(String email, String password) async {
    if (!_initialized || _auth == null) {
        // Fallback for demo/testing if Firebase fails
        if (email.isNotEmpty && password.length >= 6) {
            _isMockLoggedIn = true;
            return;
        }
        throw Exception("Firebase not initialized. Cannot real login.");
    }
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      // If firebase fails (e.g. network), fallback to mock for this demo
      print("Firebase login failed: $e. Falling back to mock.");
      _isMockLoggedIn = true;
    }
  }

  Future<void> logout() async {
    _isMockLoggedIn = false;
    if (!_initialized) return;
    await _googleSignIn?.signOut();
    await _auth?.signOut();
  }
}


