// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'dart:async';

class AuthService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

  // Cache variables
  dynamic _cachedUser;
  String? _cachedUserStatus;
  String? _cachedUserId;
  DateTime? _lastCacheUpdate;
  static const cacheDuration = Duration(minutes: 5);

  // Token management
  bool _isRefreshingToken = false;
  
  // Debug flags
  static const bool _debugMode = true;

  void _debugLog(String message) {
    if (_debugMode) {
      print('🔐 AuthService: $message');
    }
  }

  void _clearCache() {
    _debugLog('Clearing auth cache');
    _cachedUser = null;
    _cachedUserStatus = null;
    _cachedUserId = null;
    _lastCacheUpdate = null;
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < cacheDuration;
  }

  /// Force logout: Completely removes all tokens and auth state
  Future<void> forceLogout() async {
    _debugLog('Force logout called');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all auth-related preferences
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.remove('auth_timestamp');
      
      // Clear any other potential auth data
      await prefs.remove('credentials');
      await prefs.remove('user');
      await prefs.remove('profile');
      
    } catch (e) {
      _debugLog('Error during force logout: $e');
    } finally {
      _clearCache();
      _debugLog('Force logout complete');
    }
  }

  Future<bool> isLoggedIn() async {
    _debugLog('Checking login status');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) {
      _debugLog('No access token found');
      return false;
    }
    
    _debugLog('Access token found, validating...');
    
    // Try to get user details to validate token
    try {
      await getCurrentUser(validateOnly: true);
      _debugLog('Token validation successful');
      return true;
    } catch (e) {
      _debugLog('Token validation failed: $e');
      
      // Try to refresh the token
      if (!_isRefreshingToken) {
        _debugLog('Attempting token refresh');
        final refreshed = await _refreshToken();
        return refreshed;
      }
      
      _debugLog('Token refresh skipped (already in progress)');
      return false;
    }
  }

  Future<bool> _refreshToken() async {
    _isRefreshingToken = true;
    _debugLog('Starting token refresh');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        _debugLog('No refresh token available');
        await forceLogout();
        _isRefreshingToken = false;
        return false;
      }
      
      _debugLog('Calling refresh-token API');
      final response = await _apiClient.post(
        '/auth/refresh-token',
        {'refreshToken': refreshToken},
        requiresAuth: false
      );
      
      if (response['success']) {
        _debugLog('Token refresh successful');
        await setLoggedIn({
          'accessToken': response['data']['accessToken'],
          'refreshToken': response['data']['refreshToken']
        });
        _isRefreshingToken = false;
        return true;
      } else {
        _debugLog('Token refresh failed: ${response['message']}');
        await forceLogout();
        _isRefreshingToken = false;
        return false;
      }
    } catch (e) {
      _debugLog('Token refresh error: $e');
      await forceLogout();
      _isRefreshingToken = false;
      return false;
    }
  }

  Future<void> setLoggedIn(Map<String, dynamic> authData) async {
    _debugLog('Setting logged in state');
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('access_token', authData['accessToken']);
    await prefs.setString('refresh_token', authData['refreshToken']);
    await prefs.setString('auth_timestamp', DateTime.now().toIso8601String());
    
    if (authData['user'] != null && authData['user']['email'] != null) {
      await prefs.setString('user_email', authData['user']['email']);
    }
    
    _clearCache();
    _debugLog('Login state saved');
  }

  Future<void> setLoggedOut() async {
    _debugLog('Setting logged out state (standard)');
    await forceLogout();
  }

  Future<bool> checkEmailExists(String email) async {
    _debugLog('Checking if email exists: $email');
    try {
      final response = await _apiClient.post(
        '/auth/check-email',
        {'email': email},
        requiresAuth: false
      );
      
      final result = response['data']['exists'] ?? false;
      _debugLog('Email exists check result: $result');
      return result;
    } catch (e) {
      _debugLog('Error checking email existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    _debugLog('Signing in with email: $email');
    try {
      // First, force logout to clear any existing tokens
      await forceLogout();
      
      final response = await _apiClient.post(
        '/auth/login',
        {
          'email': email,
          'password': password
        },
        requiresAuth: false
      );
      
      if (response['success']) {
        _debugLog('Sign in successful');
        await setLoggedIn(response['data']);
        return {'success': true, 'redirectTo': '/dashboard'};
      }
      
      _debugLog('Sign in failed: ${response['message']}');
      return {'success': false, 'message': response['message'] ?? 'Login failed'};
    } catch (e) {
      _debugLog('Error signing in: $e');
      return {'success': false, 'message': 'An error occurred during sign in'};
    }
  }

  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password) async {
    _debugLog('Registering new user with email: $email');
    try {
      // First, force logout to clear any existing tokens
      await forceLogout();
      
      final response = await _apiClient.post(
        '/auth/register',
        {
          'email': email,
          'password': password
        },
        requiresAuth: false
      );
      
      if (response['success']) {
        _debugLog('Registration successful');
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
      
      _debugLog('Registration failed: ${response['message']}');
      return {
        'success': false,
        'message': response['message'] ?? 'Registration failed'
      };
    } catch (e) {
      _debugLog('Error registering user: $e');
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}'
      };
    }
  }

  Future<void> signOut() async {
    _debugLog('Sign out requested');
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken != null) {
        _debugLog('Calling logout API');
        await _apiClient.post('/auth/logout', {'refreshToken': refreshToken});
      }
    } catch (e) {
      _debugLog('Error during logout API call: $e');
    } finally {
      _debugLog('Completing logout process');
      await forceLogout();
    }
  }

  Future<dynamic> getCurrentUser({bool validateOnly = false}) async {
    if (!validateOnly && _cachedUser != null && _isCacheValid()) {
      _debugLog('Returning cached user');
      return _cachedUser;
    }

    _debugLog('Fetching current user from API');
    try {
      final response = await _apiClient.get('/auth/me');
      
      if (response['success']) {
        _debugLog('Retrieved user successfully');
        _cachedUser = response['data'];
        _lastCacheUpdate = DateTime.now();
        return _cachedUser;
      } else {
        _debugLog('User retrieval failed: ${response['message']}');
        throw Exception('Failed to get user: ${response['message']}');
      }
    } catch (e) {
      _debugLog('Error getting current user: $e');
      
      // Try to refresh the token if we get an authentication error
      if (!_isRefreshingToken && e.toString().contains('403')) {
        _debugLog('403 error detected, attempting token refresh');
        final refreshed = await _refreshToken();
        if (refreshed && !validateOnly) {
          // Try again after refresh
          _debugLog('Token refreshed, retrying getCurrentUser');
          return getCurrentUser();
        }
      }
      
      throw e;
    }
  }

  Future<String> getUserStatus() async {
    if (_cachedUserStatus != null && _isCacheValid()) {
      _debugLog('Returning cached user status: $_cachedUserStatus');
      return _cachedUserStatus!;
    }

    _debugLog('Determining user status');
    try {
      final user = await getCurrentUser();
      if (user == null) {
        _cachedUserStatus = 'logged_out';
        _debugLog('User is logged out');
        return _cachedUserStatus!;
      }

      _cachedUserStatus = user['status'] ?? 'active';
      _debugLog('User status: $_cachedUserStatus');
      return _cachedUserStatus!;
    } catch (e) {
      _debugLog('Error getting user status: $e');
      _cachedUserStatus = 'logged_out';
      return _cachedUserStatus!;
    }
  }

  Future<String?> getCurrentUserId() async {
    if (_cachedUserId != null && _isCacheValid()) {
      _debugLog('Returning cached user ID: $_cachedUserId');
      return _cachedUserId;
    }

    _debugLog('Getting current user ID');
    try {
      final user = await getCurrentUser();
      _cachedUserId = user?['id'] ?? user?['email'];
      _debugLog('Current user ID: $_cachedUserId');
      return _cachedUserId;
    } catch (e) {
      _debugLog('Error getting current user ID: $e');
      return null;
    }
  }

  Future<bool> setEmployeePassword(String email, String password) async {
    _debugLog('Setting password for email: $email');
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
      final result = response['success'] ?? false;
      _debugLog('Password set result: $result');
      return result;
    } catch (e) {
      _debugLog('Error setting employee password: $e');
      return false;
    }
  }
}