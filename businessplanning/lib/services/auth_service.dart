import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache variables
  dynamic _cachedUser;
  String? _cachedUserStatus;
  String? _cachedUserId;
  DateTime? _lastCacheUpdate;
  static const cacheDuration = Duration(minutes: 5);

  String _simpleHash(String input) {
    var bytes = utf8.encode(input);
    var base64 = base64Encode(bytes);
    return base64;
  }

  void _clearCache() {
    _cachedUser = null;
    _cachedUserStatus = null;
    _cachedUserId = null;
    _lastCacheUpdate = null;
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < cacheDuration;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') != null;
  }

  Future<void> setLoggedIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    _clearCache();
  }

  Future<void> setLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    _clearCache();
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      var userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return userSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      String hashedPassword = _simpleHash(password);

      var userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var userData = userSnapshot.docs.first.data();
        if (userData['password'] == hashedPassword) {
          await setLoggedIn(email);
          return {'success': true, 'redirectTo': '/dashboard'};
        }
      }

      return {'success': false, 'message': 'Invalid email or password'};
    } catch (e) {
      print('Error signing in: $e');
      return {'success': false, 'message': 'An error occurred during sign in'};
    }
  }

  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      if (await checkEmailExists(email)) {
        return {'success': false, 'message': 'Email already in use'};
      }

      String hashedPassword = _simpleHash(password);
      DocumentReference docRef = await _firestore.collection('users').add({
        'email': email,
        'password': hashedPassword,
        'status': 'complete',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(docRef.id).update({
        'id':docRef.id
      });

      // Store the user ID in the cached user data
      _cachedUser = {'id': docRef.id, 'email': email, 'status': 'complete'};
      await setLoggedIn(email);
      return {
        'success': true,
        'message': 'Registration successful',
        'userId': docRef.id
      };
    } catch (e) {
      print('Error registering user: $e');
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}'
      };
    }
  }

  Future<void> signOut() async {
    await setLoggedOut();
    _clearCache();
  }

  Future<dynamic> getCurrentUser() async {
    if (_cachedUser != null && _isCacheValid()) {
      return _cachedUser;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) return null;

    try {
      var userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        _cachedUser = userSnapshot.docs.first.data();
        _lastCacheUpdate = DateTime.now();
        return _cachedUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
    }

    _clearCache();
    return null;
  }

  Future<String> getUserStatus() async {
    if (_cachedUserStatus != null && _isCacheValid()) {
      return _cachedUserStatus!;
    }

    final user = await getCurrentUser();
    if (user == null) {
      _cachedUserStatus = 'logged_out';
      return _cachedUserStatus!;
    }

    _cachedUserStatus = user['status'] ?? 'active';
    return _cachedUserStatus!;
  }

  Future<String?> getCurrentUserId() async {
    if (_cachedUserId != null && _isCacheValid()) {
      return _cachedUserId;
    }

    final user = await getCurrentUser();
    _cachedUserId = user?['id'] ??
        user?[
            'email']; // Use email or another identifier if 'id' is not available
    return _cachedUserId;
  }

  Future<bool> setEmployeePassword(String email, String password) async {
    try {
      String hashedPassword = _simpleHash(password);
      var userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        await userSnapshot.docs.first.reference
            .update({'password': hashedPassword});
        _clearCache();
        return true;
      }

      return false;
    } catch (e) {
      print('Error setting employee password: $e');
      return false;
    }
  }
}
