// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:businessplanning/services/auth_service.dart';

import '../pages/dashboard_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../theme.dart';

class AppRouter {
  static final AuthService _authService = AuthService();
  
  // Private constructor to prevent instantiation
  AppRouter._();

  // Logger
  static void _logTiming(String operation, Duration duration) {
    developer.log(
      '$operation took ${duration.inMilliseconds}ms',
      name: 'RouterPerformance',
      time: DateTime.now(),
    );
  }

  // Page wrapper to avoid transitions
  static Page<void> _noTransitionPage({required Widget child}) {
    return CustomTransitionPage<void>(
      key: ValueKey(child.hashCode),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child; // No animation
      },
      child: child,
    );
  }

  // Parse params from URL
  static Map<String, dynamic> _parseParams(GoRouterState state) {
    final stopwatch = Stopwatch()..start();
    try {
      final paramsJson = state.uri.queryParameters['params'];
      if (paramsJson != null && paramsJson.isNotEmpty) {
        final result = json.decode(paramsJson) as Map<String, dynamic>;
        _logTiming('Params parsing', stopwatch.elapsed);
        return result;
      }
    } catch (e) {
      debugPrint('Error parsing dashboard params: $e');
      _logTiming('Params parsing error', stopwatch.elapsed);
    }
    _logTiming('Params parsing (empty)', stopwatch.elapsed);
    return {};
  }

  // Router instance
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      // Home page
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          final stopwatch = Stopwatch()..start();
          final page = _noTransitionPage(child: HomePage());
          _logTiming('HomePage build', stopwatch.elapsed);
          return page;
        },
      ),
      
      // Authentication routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final stopwatch = Stopwatch()..start();
          final page = _noTransitionPage(
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
          final page = _noTransitionPage(child: RegisterPage());
          _logTiming('RegisterPage build', stopwatch.elapsed);
          return page;
        },
      ),
      
      // Dashboard routes
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) {
          final stopwatch = Stopwatch()..start();
          final params = _parseParams(state);
          final page = _noTransitionPage(
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
              final params = _parseParams(state);
              final page = _noTransitionPage(
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
              final params = _parseParams(state);
              final page = _noTransitionPage(
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
              final params = _parseParams(state);
              final page = _noTransitionPage(
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
    ],
    redirect: _handleRedirect,
    errorBuilder: _buildErrorPage,
  );
  
  // Auth redirect handler 
  static Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    final totalStopwatch = Stopwatch()..start();
    try {
      final authStopwatch = Stopwatch()..start();
      final bool isLoggedIn = await _authService.isLoggedIn();
      _logTiming('Auth check', authStopwatch.elapsed);

      final bool isLoggingIn = state.matchedLocation == '/login';
      final bool isRegistering = state.matchedLocation == '/register';
      final bool isHomePage = state.matchedLocation == '/';

      // Not logged in
      if (!isLoggedIn) {
        if (!isHomePage && !isLoggingIn && !isRegistering && 
            !state.matchedLocation.startsWith('/complete-profile')) {
          final currentPath = state.uri.toString();
          _logTiming('Redirect to login', totalStopwatch.elapsed);
          return '/login?redirect=${Uri.encodeComponent(currentPath)}';
        }
        return null;
      }

      // Logged in
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
        final userStatus = await _authService.getUserStatus();
        _logTiming('User status fetch', userStatusStopwatch.elapsed);

        final userIdStopwatch = Stopwatch()..start();
        final currentUserId = await _authService.getCurrentUserId();
        _logTiming('User ID fetch', userIdStopwatch.elapsed);

        if (state.matchedLocation.startsWith('/complete-profile')) {
          final profileUserId = state.pathParameters['userId'];
          if (profileUserId != currentUserId) {
            final signOutStopwatch = Stopwatch()..start();
            await _authService.signOut();
            _logTiming('Sign out', signOutStopwatch.elapsed);
            _logTiming('Redirect to login after unauthorized profile access', totalStopwatch.elapsed);
            return '/login';
          }
        }

        if (userStatus == 'incomplete') {
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
  
  // Error page builder
  static Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    final stopwatch = Stopwatch()..start();
    final errorPage = Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                state.error?.toString() ?? 'The requested page could not be found.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
    _logTiming('Error page build', stopwatch.elapsed);
    return errorPage;
  }
}