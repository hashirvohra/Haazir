import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? _currentUserUid;
  static String? _token;

  static String? get currentUserUid => _currentUserUid;
  static String? get token => _token;
  static bool get isAuthenticated => _currentUserUid != null;

  /// Registers a new user with email and password.
  /// After successful FirebaseAuth creation, a document is stored in the
  /// `users` collection using the Firebase UID as the document ID.
  static Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;
      // Store user profile in Firestore
      await _db.collection('users').doc(uid).set({
        'username': email,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _currentUserUid = uid;
      _token = await cred.user!.getIdToken();
      return {'success': true, 'message': 'Successfully signed up'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error during sign‑up'};
    }
  }

  /// Logs in an existing user with email and password.
  /// Handles common FirebaseAuthException codes and returns clear messages.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;
      _currentUserUid = uid;
      _token = await cred.user!.getIdToken();
      return {'success': true, 'username': uid};
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          msg = 'Account does not exist.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        default:
          msg = e.message ?? 'Login failed';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error during login'};
    }
  }

  /// Logs out the current user.
  static Future<void> logout() async {
    await _auth.signOut();
    _currentUserUid = null;
    _token = null;
  }
}
