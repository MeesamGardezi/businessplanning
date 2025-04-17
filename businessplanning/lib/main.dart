import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Use path URL strategy for web routing (removes hash from URLs)
  usePathUrlStrategy();
  
  // Initialize the router
  final appRouter = AppRouter();
  appRouter.init();
  
  // Run the app
  runApp(MyApp(router: appRouter));
}

class MyApp extends StatefulWidget {
  final AppRouter router;
  
  const MyApp({
    Key? key,
    required this.router,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Access the global app state
  final AppState _appState = AppState();
  
  @override
  void initState() {
    super.initState();
    
    // Add observer for system theme changes
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize dark mode setting based on current platform brightness
    _appState.updateDarkModeSetting();
  }
  
  @override
  void dispose() {
    // Remove system theme observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangePlatformBrightness() {
    // Update theme when system brightness changes
    _appState.updateDarkModeSetting();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes and rebuild app
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _appState.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          routerConfig: widget.router.router,
          title: 'Strategy Planning',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
        );
      },
    );
  }
}