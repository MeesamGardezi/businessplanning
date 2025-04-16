import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'pages/dashboard_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'services/auth_service.dart';

final AuthService _authService = AuthService();

class RouterLogger {
  static void logTiming(String operation, Duration duration) {
    developer.log(
      '$operation took ${duration.inMilliseconds}ms',
      name: 'RouterPerformance',
      time: DateTime.now(),
    );
  }
}

class NoTransitionPage extends CustomTransitionPage<void> {
  NoTransitionPage({
    required Widget child,
  }) : super(
          key: ValueKey(child.hashCode),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          child: child,
        );
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final page = NoTransitionPage(child: HomePage());
        RouterLogger.logTiming('HomePage build', stopwatch.elapsed);
        return page;
      },
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final page = NoTransitionPage(
          child: LoginPage(
            redirectUrl: state.uri.queryParameters['redirect'],
          ),
        );
        RouterLogger.logTiming('LoginPage build', stopwatch.elapsed);
        return page;
      },
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final page = NoTransitionPage(child: RegisterPage());
        RouterLogger.logTiming('RegisterPage build', stopwatch.elapsed);
        return page;
      },
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) {
        final stopwatch = Stopwatch()..start();
        final params = _parseParams(state);
        final page = NoTransitionPage(
          child: DashboardPage(
            pageContent: 'home',
            params: params,
          ),
        );
        RouterLogger.logTiming('DashboardPage (home) build', stopwatch.elapsed);
        return page;
      },
      routes: [
        GoRoute(
          path: 'home',
          pageBuilder: (context, state) {
            final stopwatch = Stopwatch()..start();
            final params = _parseParams(state);
            final page = NoTransitionPage(
              child: DashboardPage(
                pageContent: 'home',
                params: params,
              ),
            );
            RouterLogger.logTiming('DashboardPage (home) build', stopwatch.elapsed);
            return page;
          },
        ),
        GoRoute(
          path: 'projects',
          pageBuilder: (context, state) {
            final stopwatch = Stopwatch()..start();
            final params = _parseParams(state);
            final page = NoTransitionPage(
              child: DashboardPage(
                pageContent: 'projects',
                params: params,
              ),
            );
            RouterLogger.logTiming('DashboardPage (projects) build', stopwatch.elapsed);
            return page;
          },
        ),
        GoRoute(
          path: 'settings',
          pageBuilder: (context, state) {
            final stopwatch = Stopwatch()..start();
            final params = _parseParams(state);
            final page = NoTransitionPage(
              child: DashboardPage(
                pageContent: 'settings',
                params: params,
              ),
            );
            RouterLogger.logTiming('DashboardPage (settings) build', stopwatch.elapsed);
            return page;
          },
        ),
        
      ],
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final totalStopwatch = Stopwatch()..start();
    try {
      final authStopwatch = Stopwatch()..start();
      final bool isLoggedIn = await _authService.isLoggedIn();
      RouterLogger.logTiming('Auth check', authStopwatch.elapsed);

      final bool isLoggingIn = state.matchedLocation == '/login';
      final bool isRegistering = state.matchedLocation == '/register';
      final bool isHomePage = state.matchedLocation == '/';

      if (!isLoggedIn) {
        if (!isHomePage &&
            !isLoggingIn &&
            !isRegistering &&
            !state.matchedLocation.startsWith('/complete-profile')) {
          final currentPath = state.uri.toString();
          RouterLogger.logTiming('Redirect to login', totalStopwatch.elapsed);
          return '/login?redirect=${Uri.encodeComponent(currentPath)}';
        }
        return null;
      }

      if (isLoggedIn) {
        if (isLoggingIn || isRegistering) {
          final redirectTo = state.uri.queryParameters['redirect'];
          if (redirectTo != null && redirectTo.isNotEmpty) {
            RouterLogger.logTiming('Redirect from login/register to previous page', totalStopwatch.elapsed);
            return Uri.decodeComponent(redirectTo);
          }
          RouterLogger.logTiming('Redirect to dashboard', totalStopwatch.elapsed);
          return '/dashboard';
        }

        final userStatusStopwatch = Stopwatch()..start();
        final userStatus = await _authService.getUserStatus();
        RouterLogger.logTiming('User status fetch', userStatusStopwatch.elapsed);

        final userIdStopwatch = Stopwatch()..start();
        final currentUserId = await _authService.getCurrentUserId();
        RouterLogger.logTiming('User ID fetch', userIdStopwatch.elapsed);

        if (state.matchedLocation.startsWith('/complete-profile')) {
          final profileUserId = state.pathParameters['userId'];
          if (profileUserId != currentUserId) {
            final signOutStopwatch = Stopwatch()..start();
            await _authService.signOut();
            RouterLogger.logTiming('Sign out', signOutStopwatch.elapsed);
            RouterLogger.logTiming('Redirect to login after unauthorized profile access', totalStopwatch.elapsed);
            return '/login';
          }
        }

        if (userStatus == 'incomplete') {
          final redirectPath = currentUserId != null
              ? '/complete-profile/$currentUserId'
              : '/login';
          RouterLogger.logTiming('Redirect to complete profile', totalStopwatch.elapsed);
          return redirectPath;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in router redirect: $e');
      RouterLogger.logTiming('Error redirect to login', totalStopwatch.elapsed);
      return '/login';
    } finally {
      RouterLogger.logTiming('Total redirect process', totalStopwatch.elapsed);
    }
  },
  errorBuilder: (context, state) {
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
    RouterLogger.logTiming('Error page build', stopwatch.elapsed);
    return errorPage;
  },
);

Map<String, dynamic> _parseParams(GoRouterState state) {
  final stopwatch = Stopwatch()..start();
  try {
    final paramsJson = state.uri.queryParameters['params'];
    if (paramsJson != null && paramsJson.isNotEmpty) {
      final result = json.decode(paramsJson) as Map<String, dynamic>;
      RouterLogger.logTiming('Params parsing', stopwatch.elapsed);
      return result;
    }
  } catch (e) {
    debugPrint('Error parsing dashboard params: $e');
    RouterLogger.logTiming('Params parsing error', stopwatch.elapsed);
  }
  RouterLogger.logTiming('Params parsing (empty)', stopwatch.elapsed);
  return {};
}