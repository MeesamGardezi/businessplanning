// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

  // Cache variables
  dynamic _cachedUser;
  String? _cachedUserStatus;
  String? _cachedUserId;
  DateTime? _lastCacheUpdate;
  static const cacheDuration = Duration(minutes: 5);

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
    return prefs.getString('access_token') != null;
  }

  Future<void> setLoggedIn(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('access_token', authData['accessToken']);
    await prefs.setString('refresh_token', authData['refreshToken']);
    
    if (authData['user'] != null && authData['user']['email'] != null) {
      await prefs.setString('user_email', authData['user']['email']);
    }
    
    _clearCache();
  }

  Future<void> setLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    
    _clearCache();
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/check-email',
        {'email': email},
        requiresAuth: false
      );
      
      return response['data']['exists'] ?? false;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        {
          'email': email,
          'password': password
        },
        requiresAuth: false
      );
      
      if (response['success']) {
        await setLoggedIn(response['data']);
        return {'success': true, 'redirectTo': '/dashboard'};
      }
      
      return {'success': false, 'message': response['message'] ?? 'Login failed'};
    } catch (e) {
      print('Error signing in: $e');
      return {'success': false, 'message': 'An error occurred during sign in'};
    }
  }

  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        {
          'email': email,
          'password': password
        },
        requiresAuth: false
      );
      
      if (response['success']) {
        await setLoggedIn({
          'accessToken': response['data']['accessToken'],
          'refreshToken': response['data']['refreshToken'],
          'user': {'email': email}
        });
        
        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful',
          'userId': response['data']['uid']
        };
      }
      
      return {
        'success': false,
        'message': response['message'] ?? 'Registration failed'
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken != null) {
        await _apiClient.post('/auth/logout', {'refreshToken': refreshToken});
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await setLoggedOut();
    }
  }

  Future<dynamic> getCurrentUser() async {
    if (_cachedUser != null && _isCacheValid()) {
      return _cachedUser;
    }

    try {
      final response = await _apiClient.get('/auth/me');
      
      if (response['success']) {
        _cachedUser = response['data'];
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
    _cachedUserId = user?['id'] ?? user?['email'];
    return _cachedUserId;
  }

  Future<bool> setEmployeePassword(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/set-password',
        {
          'email': email,
          'password': password
        },
        requiresAuth: false
      );
      
      _clearCache();
      return response['success'] ?? false;
    } catch (e) {
      print('Error setting employee password: $e');
      return false;
    }
  }
}