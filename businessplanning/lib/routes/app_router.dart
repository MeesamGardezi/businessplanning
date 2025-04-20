// lib/routes/app_router.dart
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/complete_profile_page.dart'; // Add this import
import '../state/app_state.dart';
import '../utils/transitions.dart';

/// Router configuration for the application.
/// Uses go_router for navigation with instant transitions.
class AppRouter {
  // Private constructor for singleton
  AppRouter._();
  
  // Singleton instance
  static final AppRouter _instance = AppRouter._();
  
  // Factory constructor
  factory AppRouter() => _instance;
  
  // State management
  final AppState _appState = AppState();
  
  // Router instance
  late final GoRouter router;
  
  /// Initialize the router
  void init() {
    router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: _routes,
      redirect: _guardRoutes,
      errorBuilder: _errorBuilder,
    );
  }
  
  /// Parse route parameters from query string
  static Map<String, dynamic> parseParams(GoRouterState state) {
    final stopwatch = Stopwatch()..start();
    try {
      final paramsJson = state.uri.queryParameters['params'];
      if (paramsJson != null && paramsJson.isNotEmpty) {
        final result = json.decode(paramsJson) as Map<String, dynamic>;
        _logTiming('Params parsing', stopwatch.elapsed);
        return result;
      }
    } catch (e) {
      debugPrint('Error parsing params: $e');
      _logTiming('Params parsing error', stopwatch.elapsed);
    }
    _logTiming('Params parsing (empty)', stopwatch.elapsed);
    return {};
  }
  
  /// Log routing performance
  static void _logTiming(String operation, Duration duration) {
    developer.log(
      '$operation took ${duration.inMilliseconds}ms',
      name: 'RouterPerformance',
      time: DateTime.now(),
    );
  }
  
  /// Route guard for authentication
  Future<String?> _guardRoutes(BuildContext context, GoRouterState state) async {
    final totalStopwatch = Stopwatch()..start();
    try {
      final authStopwatch = Stopwatch()..start();
      final bool isLoggedIn = _appState.isLoggedIn.value;
      _logTiming('Auth check', authStopwatch.elapsed);

      final bool isLoggingIn = state.matchedLocation == '/login';
      final bool isRegistering = state.matchedLocation == '/register';
      final bool isHomePage = state.matchedLocation == '/';
      final bool isCompletingProfile = state.matchedLocation.startsWith('/complete-profile');

      if (!isLoggedIn) {
        if (!isHomePage &&
            !isLoggingIn &&
            !isRegistering &&
            !isCompletingProfile) {
          final currentPath = state.uri.toString();
          _logTiming('Redirect to login', totalStopwatch.elapsed);
          return '/login?redirect=${Uri.encodeComponent(currentPath)}';
        }
        return null;
      }

      if (isLoggedIn) {
        if (isLoggingIn || isRegistering) {
          final redirectTo = state.uri.queryParameters['redirect'];
          if (redirectTo != null && redirectTo.isNotEmpty) {
            _logTiming('Redirect from login/register to previous page', totalStopwatch.elapsed);
            return Uri.decodeComponent(redirectTo);
          }
          _logTiming('Redirect to dashboard', totalStopwatch.elapsed);
          return '/dashboard';
        }

        final userStatusStopwatch = Stopwatch()..start();
        final userStatus = _appState.userStatus.value;
        _logTiming('User status fetch', userStatusStopwatch.elapsed);

        final userIdStopwatch = Stopwatch()..start();
        final currentUserId = _appState.currentUserId.value;
        _logTiming('User ID fetch', userIdStopwatch.elapsed);

        if (isCompletingProfile) {
          final profileUserId = state.pathParameters['userId'];
          if (profileUserId != currentUserId) {
            final signOutStopwatch = Stopwatch()..start();
            await _appState.signOut();
            _logTiming('Sign out', signOutStopwatch.elapsed);
            _logTiming('Redirect to login after unauthorized profile access', totalStopwatch.elapsed);
            return '/login';
          }
        }

        if (userStatus == 'incomplete' && !isCompletingProfile) {
          final redirectPath = currentUserId != null
              ? '/complete-profile/$currentUserId'
              : '/login';
          _logTiming('Redirect to complete profile', totalStopwatch.elapsed);
          return redirectPath;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in router redirect: $e');
      _logTiming('Error redirect to login', totalStopwatch.elapsed);
      return '/login';
    } finally {
      _logTiming('Total redirect process', totalStopwatch.elapsed);
    }
  }
  
  /// Error page builder
  Widget _errorBuilder(BuildContext context, GoRouterState state) {
    final stopwatch = Stopwatch()..start();
    final errorPage = Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
    _logTiming('Error page build', stopwatch.elapsed);
    return errorPage;
  }
  
  /// Route definitions
  List<RouteBase> get _routes => [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final page = InstantPageTransition(
          child: HomePage(isDarkMode: _appState.isDarkMode.value),
        );
        _logTiming('HomePage build', stopwatch.elapsed);
        return page;
      },
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final page = InstantPageTransition(
          child: LoginPage(
            redirectUrl: state.uri.queryParameters['redirect'],
          ),
        );
        _logTiming('LoginPage build', stopwatch.elapsed);
        return page;
      },
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final page = InstantPageTransition(
          child: RegisterPage(),
        );
        _logTiming('RegisterPage build', stopwatch.elapsed);
        return page;
      },
    ),
    // Add the complete-profile route
    GoRoute(
      path: '/complete-profile/:userId',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final userId = state.pathParameters['userId'] ?? '';
        final page = InstantPageTransition(
          child: CompleteProfilePage(userId: userId),
        );
        _logTiming('CompleteProfilePage build', stopwatch.elapsed);
        return page;
      },
    ),
    // Add a simpler route without userId parameter for direct navigation from register page
    GoRoute(
      path: '/complete-profile',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final userId = state.extra as String? ?? '';
        final page = InstantPageTransition(
          child: CompleteProfilePage(userId: userId),
        );
        _logTiming('CompleteProfilePage (from extra) build', stopwatch.elapsed);
        return page;
      },
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final params = parseParams(state);
        final page = InstantPageTransition(
          child: DashboardPage(
            pageContent: 'home',
            params: params,
          ),
        );
        _logTiming('DashboardPage (home) build', stopwatch.elapsed);
        return page;
      },
      routes: [
        GoRoute(
          path: 'home',
          pageBuilder: (context, state) {
            final stopwatch = Stopwatch()..start();
            final params = parseParams(state);
            final page = InstantPageTransition(
              child: DashboardPage(
                pageContent: 'home',
                params: params,
              ),
            );
            _logTiming('DashboardPage (home) build', stopwatch.elapsed);
            return page;
          },
        ),
        GoRoute(
          path: 'projects',
          pageBuilder: (context, state) {
            final stopwatch = Stopwatch()..start();
            final params = parseParams(state);
            final page = InstantPageTransition(
              child: DashboardPage(
                pageContent: 'projects',
                params: params,
              ),
            );
            _logTiming('DashboardPage (projects) build', stopwatch.elapsed);
            return page;
          },
        ),
        GoRoute(
          path: 'settings',
          pageBuilder: (context, state) {
            final stopwatch = Stopwatch()..start();
            final params = parseParams(state);
            final page = InstantPageTransition(
              child: DashboardPage(
                pageContent: 'settings',
                params: params,
              ),
            );
            _logTiming('DashboardPage (settings) build', stopwatch.elapsed);
            return page;
          },
        ),
      ],
    ),
  ];
}