// lib/utils/transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Utility class for instant page transitions
/// Eliminates all animation delays in navigation
class InstantPageTransition<T> extends CustomTransitionPage<T> {
  /// Creates a page with no transition animation
  /// 
  /// This ensures all page changes happen instantly with zero delay
  InstantPageTransition({
    required Widget child,
    String? name,
    Object? arguments,
    LocalKey? key,
    String? restorationId,
  }) : super(
          key: key ?? ValueKey(child.hashCode),
          name: name,
          arguments: arguments,
          restorationId: restorationId,
          child: child,
          transitionsBuilder: (_, __, ___, child) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          opaque: true,
          barrierDismissible: false,
          maintainState: true,
        );
}

/// Creates a GoRoute page with no transition animation
Page<T> createNoTransitionPage<T>({
  required Widget child,
  String? name,
  Object? arguments,
  LocalKey? key,
  String? restorationId,
}) {
  return InstantPageTransition<T>(
    child: child,
    name: name,
    arguments: arguments,
    key: key,
    restorationId: restorationId,
  );
}

/// Extension method for GoRouter to create routes with instant transitions
extension GoRouterExtensions on GoRouter {
  /// Creates a route that uses instant transitions with no animations
  Route<T> instantTransitionRoute<T>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return MaterialPageRoute(
      builder: (context) => child,
      settings: CustomTransitionPage<T>(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (_, __, ___, child) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

/// Extension for BuildContext to handle page transitions
extension BuildContextExtensions on BuildContext {
  /// Navigate to a new route with no animation
  void pushInstant(String location) {
    GoRouter.of(this).push(location);
  }
  
  /// Replace current route with a new one without animation
  void goInstant(String location) {
    GoRouter.of(this).go(location);
  }
}