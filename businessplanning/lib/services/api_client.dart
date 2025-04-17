// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;
  static const bool _debugMode = true;
  
  ApiClient({required this.baseUrl});
  
  void _debugLog(String message) {
    if (_debugMode) {
      print('🌐 ApiClient: $message');
    }
  }
  
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token != null) {
        _debugLog('Adding authorization header with token');
        headers['Authorization'] = 'Bearer $token';
      } else {
        _debugLog('No access token available for authenticated request');
      }
    }
    
    return headers;
  }
  
  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    _debugLog('GET request to $endpoint (auth: $requiresAuth)');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      _debugLog('Request URL: $uri');
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _debugLog('GET request timeout');
          throw TimeoutException('Request timed out');
        },
      );
      
      _debugLog('Response status: ${response.statusCode}');
      if (_debugMode && response.statusCode >= 400) {
        _debugLog('Response body: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      _debugLog('GET request error: $e');
      
      if (e is ApiException) {
        rethrow;
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<dynamic> post(String endpoint, dynamic data, {bool requiresAuth = true}) async {
    _debugLog('POST request to $endpoint (auth: $requiresAuth)');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    try {
      final body = json.encode(data);
      _debugLog('Request body: $body');
      
      final uri = Uri.parse('$baseUrl$endpoint');
      _debugLog('Request URL: $uri');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _debugLog('POST request timeout');
          throw TimeoutException('Request timed out');
        },
      );
      
      _debugLog('Response status: ${response.statusCode}');
      if (_debugMode && response.statusCode >= 400) {
        _debugLog('Response body: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      _debugLog('POST request error: $e');
      
      if (e is ApiException) {
        rethrow;
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<dynamic> put(String endpoint, dynamic data, {bool requiresAuth = true}) async {
    _debugLog('PUT request to $endpoint (auth: $requiresAuth)');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    try {
      final body = json.encode(data);
      _debugLog('Request body: $body');
      
      final uri = Uri.parse('$baseUrl$endpoint');
      _debugLog('Request URL: $uri');
      
      final response = await http.put(
        uri,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _debugLog('PUT request timeout');
          throw TimeoutException('Request timed out');
        },
      );
      
      _debugLog('Response status: ${response.statusCode}');
      if (_debugMode && response.statusCode >= 400) {
        _debugLog('Response body: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      _debugLog('PUT request error: $e');
      
      if (e is ApiException) {
        rethrow;
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    _debugLog('DELETE request to $endpoint (auth: $requiresAuth)');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      _debugLog('Request URL: $uri');
      
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _debugLog('DELETE request timeout');
          throw TimeoutException('Request timed out');
        },
      );
      
      _debugLog('Response status: ${response.statusCode}');
      if (_debugMode && response.statusCode >= 400) {
        _debugLog('Response body: ${response.body}');
      }
      
      return _processResponse(response);
    } catch (e) {
      _debugLog('DELETE request error: $e');
      
      if (e is ApiException) {
        rethrow;
      }
      
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
  
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        _debugLog('Processing successful response');
        final String responseBody = response.body.trim();
        
        if (responseBody.isEmpty) {
          _debugLog('Empty response body, returning empty success');
          return {'success': true};
        }
        
        return json.decode(responseBody);
      } catch (e) {
        _debugLog('Error parsing response: $e');
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error parsing response: ${response.body}',
        );
      }
    } else {
      final errorMessage = _getErrorMessage(response);
      _debugLog('Error response: ${response.statusCode} - $errorMessage');
      
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }
  }
  
  String _getErrorMessage(http.Response response) {
    try {
      final String responseBody = response.body.trim();
      
      if (responseBody.isEmpty) {
        return 'Error: ${response.statusCode}';
      }
      
      final body = json.decode(responseBody);
      return body['message'] ?? 'Unknown error occurred';
    } catch (e) {
      _debugLog('Error parsing error message: $e');
      return 'Error: ${response.statusCode}';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException({required this.statusCode, required this.message});
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class TimeoutException extends ApiException {
  TimeoutException(String message) : super(statusCode: 408, message: message);
}