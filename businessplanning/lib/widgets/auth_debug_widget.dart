// lib/widgets/auth_debug_widget.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// A widget to help debug authentication issues.
/// Add this to your login page for temporary debugging.
class AuthDebugWidget extends StatefulWidget {
  const AuthDebugWidget({Key? key}) : super(key: key);

  @override
  State<AuthDebugWidget> createState() => _AuthDebugWidgetState();
}

class _AuthDebugWidgetState extends State<AuthDebugWidget> {
  final AuthService _auth = AuthService();
  Map<String, String> _authData = {};
  bool _isLoading = false;
  String _status = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => 
        k.contains('token') || 
        k.contains('user') || 
        k.contains('auth') ||
        k.contains('email')
      ).toList();

      final data = <String, String>{};
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          // Truncate long values
          if (value.length > 50) {
            data[key] = '${value.substring(0, 47)}...';
          } else {
            data[key] = value;
          }
        }
      }

      // Check login status
      final isLoggedIn = await _auth.isLoggedIn();
      _status = isLoggedIn ? 'Logged In' : 'Logged Out';

      setState(() {
        _authData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading auth data: $e');
      setState(() {
        _authData = {'error': e.toString()};
        _isLoading = false;
        _status = 'Error';
      });
    }
  }

  Future<void> _clearAuthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.forceLogout();
      _loadAuthData();
    } catch (e) {
      print('Error clearing auth data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auth Debug (Status: $_status)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _loadAuthData,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: _clearAuthData,
                    tooltip: 'Clear Auth Data',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_authData.isEmpty)
            const Text('No auth data found', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
          else
            ...List.generate(_authData.entries.length, (index) {
              final entry = _authData.entries.elementAt(index);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}