// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A comprehensive theme class for the BusinessPlanning application.
/// Contains design tokens, theme data, and utility methods for styling.
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation
  
  // ========== MODE DETECTION ==========
  /// Determines if the current theme mode is dark
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  
  // ========== THEME MODES ==========
  /// Gets the appropriate theme based on the system preference
  static ThemeData getTheme(Brightness brightness) =>
      brightness == Brightness.dark ? darkTheme : lightTheme;
      
  // ========== COLOR SYSTEM ==========
  // Primary palette
  static const Color _lightPrimaryColor = Color(0xFF00796B); // teal.shade700
  static const Color _lightSecondaryColor = Color(0xFF009688); // teal.shade500  
  static const Color _lightTertiaryColor = Color(0xFF4DB6AC); // teal.shade300
  
  static const Color _darkPrimaryColor = Color(0xFF4DB6AC); // teal.shade300
  static const Color _darkSecondaryColor = Color(0xFF26A69A); // teal.shade400
  static const Color _darkTertiaryColor = Color(0xFF80CBC4); // teal.shade200
  
  // Neutral palette - Light theme
  static const Color _lightNeutralBg = Color(0xFFFAFAFA); // grey.shade50
  static const Color _lightNeutralCard = Color(0xFFFFFFFF); // white
  static const Color _lightNeutralSurface = Color(0xFFF5F5F5); // grey.shade100
  static const Color _lightNeutralBorder = Color(0xFFEEEEEE); // grey.shade200
  static const Color _lightNeutralDisabled = Color(0xFFE0E0E0); // grey.shade300
  
  // Neutral palette - Dark theme
  static const Color _darkNeutralBg = Color(0xFF121212); // dark grey
  static const Color _darkNeutralCard = Color(0xFF1E1E1E); // lighter dark grey
  static const Color _darkNeutralSurface = Color(0xFF242424); // even lighter dark grey
  static const Color _darkNeutralBorder = Color(0xFF323232); // subtle border for dark theme
  static const Color _darkNeutralDisabled = Color(0xFF454545); // disabled state for dark theme
  
  // Text colors - Light theme
  static const Color _lightTextPrimary = Color(0xFF212121); // grey.shade900
  static const Color _lightTextSecondary = Color(0xFF616161); // grey.shade700
  static const Color _lightTextTertiary = Color(0xFF9E9E9E); // grey.shade500
  static const Color _lightTextOnPrimary = Color(0xFFFFFFFF); // white
  
  // Text colors - Dark theme
  static const Color _darkTextPrimary = Color(0xFFE0E0E0); // light grey
  static const Color _darkTextSecondary = Color(0xFFB0B0B0); // medium grey
  static const Color _darkTextTertiary = Color(0xFF868686); // darker grey
  static const Color _darkTextOnPrimary = Color(0xFF121212); // near black
  
  // Status colors - Universal (adjusted in dark mode)
  static const Color _lightError = Color(0xFFEF5350); // red.shade400
  static const Color _lightSuccess = Color(0xFF66BB6A); // green.shade400
  static const Color _lightWarning = Color(0xFFFFB74D); // orange.shade300
  static const Color _lightInfo = Color(0xFF4FC3F7); // lightBlue.shade300
  
  static const Color _darkError = Color(0xFFE57373); // red.shade300
  static const Color _darkSuccess = Color(0xFF81C784); // green.shade300
  static const Color _darkWarning = Color(0xFFFFD54F); // amber.shade300
  static const Color _darkInfo = Color(0xFF4DD0E1); // cyan.shade300
  
  // Additional palette - Light theme
  static const Color _lightAccentBlue = Color(0xFF42A5F5); // blue.shade400
  static const Color _lightAccentPurple = Color(0xFFAB47BC); // purple.shade400
  static const Color _lightAccentAmber = Color(0xFFFFCA28); // amber.shade400
  
  // Additional palette - Dark theme
  static const Color _darkAccentBlue = Color(0xFF64B5F6); // blue.shade300
  static const Color _darkAccentPurple = Color(0xFFBA68C8); // purple.shade300
  static const Color _darkAccentAmber = Color(0xFFFFD54F); // amber.shade300
  
  // ========== ELEVATION OVERLAYS ==========
  // Used for dark theme elevation appearance
  static const List<double> _elevationOverlayPercentages = [0, 0.05, 0.08, 0.11, 0.12, 0.14];
  
  // ========== SPACING SYSTEM ==========
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  static const double spaceXXXL = 64.0;
  
  // ========== RESPONSIVE BREAKPOINTS ==========
  static const double breakpointXS = 0;
  static const double breakpointSM = 600;
  static const double breakpointMD = 960;
  static const double breakpointLG = 1280;
  static const double breakpointXL = 1920;
  
  // ========== BORDER RADIUS ==========
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircular = 100.0;
  
  // ========== SHADOWS ==========
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];
  
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
  
  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];
      
  // Dark theme shadows are more subtle
  static List<BoxShadow> get shadowSmallDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];
  
  static List<BoxShadow> get shadowMediumDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
  
  static List<BoxShadow> get shadowLargeDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.20),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];
      
  // ========== DURATIONS ==========
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  // ========== SIDEBAR STYLING ==========
  static const double sidebarWidthCollapsed = 72.0;
  static const double sidebarWidthExpanded = 280.0;
  static const double sidebarItemHeight = 56.0;
  static const double sidebarIconSize = 24.0;
  static const double sidebarTextSize = 14.0;
  
  // ========== TYPOGRAPHY SCALE ==========
  static const TextStyle _displayLargeBase = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle _displayMediumBase = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle _displaySmallBase = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.25,
  );
  
  static const TextStyle _headlineLargeBase = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle _headlineMediumBase = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle _headlineSmallBase = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle _titleLargeBase = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle _titleMediumBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle _titleSmallBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle _bodyLargeBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle _bodyMediumBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle _bodySmallBase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle _labelLargeBase = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );
  
  static const TextStyle _labelMediumBase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  static const TextStyle _labelSmallBase = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  // ========== LIGHT THEME ==========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        primary: _lightPrimaryColor,
        onPrimary: _lightTextOnPrimary,
        primaryContainer: Color(0xFFB2DFDB), // teal.shade100
        onPrimaryContainer: Color(0xFF004D40), // teal.shade900
        secondary: _lightSecondaryColor,
        onSecondary: _lightTextOnPrimary,
        secondaryContainer: Color(0xFFB2DFDB), // teal.shade100
        onSecondaryContainer: Color(0xFF004D40), // teal.shade900
        tertiary: _lightTertiaryColor,
        onTertiary: _lightTextOnPrimary,
        tertiaryContainer: Color(0xFFE0F2F1), // teal.shade50
        onTertiaryContainer: Color(0xFF004D40), // teal.shade900
        error: _lightError,
        onError: _lightTextOnPrimary,
        errorContainer: Color(0xFFFFEBEE), // red.shade50
        onErrorContainer: Color(0xFFB71C1C), // red.shade900
        background: _lightNeutralBg,
        onBackground: _lightTextPrimary,
        surface: _lightNeutralCard,
        onSurface: _lightTextPrimary,
        surfaceVariant: _lightNeutralSurface,
        onSurfaceVariant: _lightTextSecondary,
        outline: _lightNeutralBorder,
        outlineVariant: _lightNeutralDisabled,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: _lightTextPrimary,
        onInverseSurface: _lightNeutralCard,
        inversePrimary: _lightTertiaryColor,
        brightness: Brightness.light,
      ),
      
      // ========== TYPOGRAPHY ==========
      textTheme: const TextTheme(
        displayLarge: _displayLargeBase,
        displayMedium: _displayMediumBase,
        displaySmall: _displaySmallBase,
        headlineLarge: _headlineLargeBase,
        headlineMedium: _headlineMediumBase,
        headlineSmall: _headlineSmallBase,
        titleLarge: _titleLargeBase,
        titleMedium: _titleMediumBase,
        titleSmall: _titleSmallBase,
        bodyLarge: _bodyLargeBase,
        bodyMedium: _bodyMediumBase,
        bodySmall: _bodySmallBase,
        labelLarge: _labelLargeBase,
        labelMedium: _labelMediumBase,
        labelSmall: _labelSmallBase,
      ).apply(
        bodyColor: _lightTextPrimary,
        displayColor: _lightTextPrimary,
      ),
      
      // ========== COMPONENT THEMES ==========
      // Card Theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: _lightNeutralBorder, width: 1),
        ),
        color: _lightNeutralCard,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.all(spaceMD),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightTextOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightTextOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimaryColor,
          side: const BorderSide(color: _lightPrimaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 40),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightNeutralSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _lightPrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _lightError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _lightError, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: _lightTextTertiary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: _lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: _lightTextTertiary,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: _lightError,
          fontSize: 12,
        ),
        prefixIconColor: _lightTextSecondary,
        suffixIconColor: _lightTextSecondary,
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXS),
        ),
        side: const BorderSide(color: _lightTextSecondary, width: 1.5),
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _lightNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _lightPrimaryColor;
          }
          return Colors.transparent;
        }),
      ),
      
      // Radio Button Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _lightNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _lightPrimaryColor;
          }
          return _lightTextSecondary;
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return _lightPrimaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _lightNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _lightPrimaryColor;
          }
          return _lightNeutralCard;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _lightNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _lightPrimaryColor.withOpacity(0.5);
          }
          return _lightTextTertiary.withOpacity(0.3);
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _lightPrimaryColor,
        inactiveTrackColor: _lightPrimaryColor.withOpacity(0.2),
        thumbColor: _lightPrimaryColor,
        overlayColor: _lightPrimaryColor.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        trackHeight: 4,
        valueIndicatorColor: _lightPrimaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: _lightTextOnPrimary,
          fontSize: 12,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _lightNeutralBorder,
        thickness: 1,
        space: spaceLG,
      ),
      
      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        color: _lightNeutralCard,
        textStyle: const TextStyle(
          color: _lightTextPrimary,
          fontSize: 14,
        ),
      ),
      
      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _lightTextPrimary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        textStyle: const TextStyle(
          color: _lightNeutralCard,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightTextPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        contentTextStyle: const TextStyle(
          color: _lightNeutralCard,
          fontSize: 14,
        ),
        actionTextColor: _lightTertiaryColor,
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: _lightNeutralCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _lightTextSecondary,
        ),
      ),
      
      // BottomSheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _lightNeutralCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLG),
          ),
        ),
        elevation: 0,
        modalBackgroundColor: _lightNeutralCard,
        showDragHandle: true,
        dragHandleColor: _lightTextTertiary,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _lightNeutralCard,
        foregroundColor: _lightTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        iconTheme: IconThemeData(
          color: _lightTextPrimary,
          size: 24,
        ),
        centerTitle: false,
        scrolledUnderElevation: 4,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: _lightPrimaryColor,
        unselectedLabelColor: _lightTextSecondary,
        indicatorColor: _lightPrimaryColor,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightNeutralCard,
        selectedItemColor: _lightPrimaryColor,
        unselectedItemColor: _lightTextSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Date Picker Theme
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _lightNeutralCard,
        headerBackgroundColor: _lightPrimaryColor,
        headerForegroundColor: _lightTextOnPrimary,
        dayBackgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return _lightPrimaryColor;
          }
          return null;
        }),
        dayForegroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _lightTextOnPrimary;
          }
          return _lightTextPrimary;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _lightNeutralSurface,
        disabledColor: _lightNeutralDisabled,
        selectedColor: _lightPrimaryColor.withOpacity(0.1),
        secondarySelectedColor: _lightPrimaryColor.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: _lightTextPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          color: _lightPrimaryColor,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCircular),
        ),
      ),
      
      // Segmented Button Theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return _lightPrimaryColor;
            }
            return _lightNeutralSurface;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return _lightTextOnPrimary;
            }
            return _lightTextPrimary;
          }),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
          ),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _lightPrimaryColor,
        circularTrackColor: _lightNeutralDisabled,
        linearTrackColor: _lightNeutralDisabled,
      ),
      
      // Additional properties
      splashColor: _lightPrimaryColor.withOpacity(0.1),
      highlightColor: _lightPrimaryColor.withOpacity(0.05),
      scaffoldBackgroundColor: _lightNeutralBg,
      dividerColor: _lightNeutralBorder,
      disabledColor: _lightNeutralDisabled,
      hintColor: _lightTextTertiary,
      iconTheme: const IconThemeData(
        color: _lightTextSecondary,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: _lightTextOnPrimary,
        size: 24,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // ========== DARK THEME ==========
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        primary: _darkPrimaryColor,
        onPrimary: _darkTextOnPrimary,
        primaryContainer: Color(0xFF00796B), // teal.shade700
        onPrimaryContainer: Color(0xFFB2DFDB), // teal.shade100
        secondary: _darkSecondaryColor,
        onSecondary: _darkTextOnPrimary,
        secondaryContainer: Color(0xFF00796B), // teal.shade700
        onSecondaryContainer: Color(0xFFB2DFDB), // teal.shade100
        tertiary: _darkTertiaryColor,
        onTertiary: _darkTextOnPrimary,
        tertiaryContainer: Color(0xFF006064), // cyan.shade900
        onTertiaryContainer: Color(0xFFB2EBF2), // cyan.shade100
        error: _darkError,
        onError: _darkTextOnPrimary,
        errorContainer: Color(0xFF611C1A), // darker red
        onErrorContainer: Color(0xFFFFCDD2), // red.shade100
        background: _darkNeutralBg,
        onBackground: _darkTextPrimary,
        surface: _darkNeutralCard,
        onSurface: _darkTextPrimary,
        surfaceVariant: _darkNeutralSurface,
        onSurfaceVariant: _darkTextSecondary,
        outline: _darkNeutralBorder,
        outlineVariant: _darkNeutralDisabled,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: _darkTextPrimary,
        onInverseSurface: _darkNeutralCard,
        inversePrimary: _darkPrimaryColor,
        brightness: Brightness.dark,
      ),
      
      // ========== TYPOGRAPHY ==========
      textTheme: const TextTheme(
        displayLarge: _displayLargeBase,
        displayMedium: _displayMediumBase,
        displaySmall: _displaySmallBase,
        headlineLarge: _headlineLargeBase,
        headlineMedium: _headlineMediumBase,
        headlineSmall: _headlineSmallBase,
        titleLarge: _titleLargeBase,
        titleMedium: _titleMediumBase,
        titleSmall: _titleSmallBase,
        bodyLarge: _bodyLargeBase,
        bodyMedium: _bodyMediumBase,
        bodySmall: _bodySmallBase,
        labelLarge: _labelLargeBase,
        labelMedium: _labelMediumBase,
        labelSmall: _labelSmallBase,
      ).apply(
        bodyColor: _darkTextPrimary,
        displayColor: _darkTextPrimary,
      ),
      
      // ========== COMPONENT THEMES ==========
      // Card Theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: _darkNeutralBorder, width: 1),
        ),
        color: _darkNeutralCard,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.all(spaceMD),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkTextOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkTextOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          side: const BorderSide(color: _darkPrimaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 40),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkNeutralSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _darkPrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _darkError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _darkError, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: _darkTextTertiary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: _darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: _darkTextTertiary,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: _darkError,
          fontSize: 12,
        ),
        prefixIconColor: _darkTextSecondary,
        suffixIconColor: _darkTextSecondary,
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXS),
        ),
        side: const BorderSide(color: _darkTextSecondary, width: 1.5),
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _darkNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor;
          }
          return Colors.transparent;
        }),
      ),
      
      // Radio Button Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _darkNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor;
          }
          return _darkTextSecondary;
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return _darkPrimaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _darkNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor;
          }
          return _darkNeutralCard;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _darkNeutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor.withOpacity(0.5);
          }
          return _darkTextTertiary.withOpacity(0.3);
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _darkPrimaryColor,
        inactiveTrackColor: _darkPrimaryColor.withOpacity(0.2),
        thumbColor: _darkPrimaryColor,
        overlayColor: _darkPrimaryColor.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        trackHeight: 4,
        valueIndicatorColor: _darkPrimaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: _darkTextOnPrimary,
          fontSize: 12,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _darkNeutralBorder,
        thickness: 1,
        space: spaceLG,
      ),
      
      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        color: _darkNeutralCard,
        textStyle: const TextStyle(
          color: _darkTextPrimary,
          fontSize: 14,
        ),
      ),
      
      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkTextPrimary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        textStyle: const TextStyle(
          color: _darkNeutralCard,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        contentTextStyle: const TextStyle(
          color: _darkTextPrimary,
          fontSize: 14,
        ),
        actionTextColor: _darkPrimaryColor,
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: _darkNeutralCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _darkTextSecondary,
        ),
      ),
      
      // BottomSheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkNeutralCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLG),
          ),
        ),
        elevation: 0,
        modalBackgroundColor: _darkNeutralCard,
        showDragHandle: true,
        dragHandleColor: _darkTextTertiary,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _darkNeutralCard,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        iconTheme: IconThemeData(
          color: _darkTextPrimary,
          size: 24,
        ),
        centerTitle: false,
        scrolledUnderElevation: 4,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: _darkPrimaryColor,
        unselectedLabelColor: _darkTextSecondary,
        indicatorColor: _darkPrimaryColor,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkNeutralCard,
        selectedItemColor: _darkPrimaryColor,
        unselectedItemColor: _darkTextSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Date Picker Theme
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _darkNeutralCard,
        headerBackgroundColor: _darkPrimaryColor,
        headerForegroundColor: _darkTextOnPrimary,
        dayBackgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor;
          }
          return null;
        }),
        dayForegroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _darkTextOnPrimary;
          }
          return _darkTextPrimary;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _darkNeutralSurface,
        disabledColor: _darkNeutralDisabled,
        selectedColor: _darkPrimaryColor.withOpacity(0.2),
        secondarySelectedColor: _darkPrimaryColor.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: _darkTextPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          color: _darkPrimaryColor,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCircular),
        ),
      ),
      
      // Segmented Button Theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return _darkPrimaryColor;
            }
            return _darkNeutralSurface;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return _darkTextOnPrimary;
            }
            return _darkTextPrimary;
          }),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
          ),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _darkPrimaryColor,
        circularTrackColor: _darkNeutralDisabled,
        linearTrackColor: _darkNeutralDisabled,
      ),
      
      // Additional properties
      splashColor: _darkPrimaryColor.withOpacity(0.1),
      highlightColor: _darkPrimaryColor.withOpacity(0.05),
      scaffoldBackgroundColor: _darkNeutralBg,
      dividerColor: _darkNeutralBorder,
      disabledColor: _darkNeutralDisabled,
      hintColor: _darkTextTertiary,
      iconTheme: const IconThemeData(
        color: _darkTextSecondary,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: _darkTextOnPrimary,
        size: 24,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // ========== UI UTILITY METHODS ==========
  // System UI Overlay style for light mode
  static SystemUiOverlayStyle get lightSystemOverlayStyle => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: _lightNeutralCard,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  
  // System UI Overlay style for dark mode
  static SystemUiOverlayStyle get darkSystemOverlayStyle => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _darkNeutralCard,
    systemNavigationBarIconBrightness: Brightness.light,
  );
  
  // Get appropriate system overlay style based on theme brightness
  static SystemUiOverlayStyle getSystemOverlayStyle(Brightness brightness) =>
      brightness == Brightness.dark ? darkSystemOverlayStyle : lightSystemOverlayStyle;
  
  // ========== COMPONENT STYLE UTILITIES ==========
  // Sidebar Item Decoration - with theme awareness
  static BoxDecoration getSidebarItemDecoration({
    required bool isSelected,
    required Brightness brightness,
  }) {
    final primaryColor = brightness == Brightness.dark ? _darkPrimaryColor : _lightPrimaryColor;
    return BoxDecoration(
      color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(radiusMD),
    );
  }
  
  // Sidebar Item Text Style - with theme awareness
  static TextStyle getSidebarItemTextStyle({
    required bool isSelected,
    required Brightness brightness,
  }) {
    final primaryColor = brightness == Brightness.dark ? _darkPrimaryColor : _lightPrimaryColor;
    final textSecondary = brightness == Brightness.dark ? _darkTextSecondary : _lightTextSecondary;
    return TextStyle(
      fontSize: 14,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: isSelected ? primaryColor : textSecondary,
    );
  }
  
  // Sidebar Item Icon Color - with theme awareness
  static Color getSidebarItemIconColor({
    required bool isSelected,
    required Brightness brightness,
  }) {
    final primaryColor = brightness == Brightness.dark ? _darkPrimaryColor : _lightPrimaryColor;
    final textSecondary = brightness == Brightness.dark ? _darkTextSecondary : _lightTextSecondary;
    return isSelected ? primaryColor : textSecondary;
  }
  
  // Card Decoration - with theme awareness
  static BoxDecoration getCardDecoration({
    required Brightness brightness,
    bool hasShadow = true,
    bool hasBorder = true,
    double radius = radiusLG,
  }) {
    final cardColor = brightness == Brightness.dark ? _darkNeutralCard : _lightNeutralCard;
    final borderColor = brightness == Brightness.dark ? _darkNeutralBorder : _lightNeutralBorder;
    final shadows = brightness == Brightness.dark ? shadowMediumDark : shadowMedium;
    
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: hasBorder ? Border.all(color: borderColor) : null,
      boxShadow: hasShadow ? shadows : null,
    );
  }
  
  // Status Color - with theme awareness
  static Color getStatusColor({
    required String status,
    required Brightness brightness,
  }) {
    final isLight = brightness == Brightness.light;
    switch (status.toLowerCase()) {
      case 'success':
      case 'complete':
      case 'completed':
      case 'active':
        return isLight ? _lightSuccess : _darkSuccess;
      case 'warning':
      case 'pending':
      case 'in progress':
        return isLight ? _lightWarning : _darkWarning;
      case 'error':
      case 'failed':
        return isLight ? _lightError : _darkError;
      case 'info':
      case 'draft':
        return isLight ? _lightInfo : _darkInfo;
      default:
        return isLight ? _lightTextSecondary : _darkTextSecondary;
    }
  }
  
  // Badge Decoration - with theme awareness
  static BoxDecoration getBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radiusCircular),
    );
  }
  
  // Elevation Surface - get a surface color with simulated elevation for dark mode
  static Color getElevatedSurfaceColor({
    required Brightness brightness,
    required int elevation,
  }) {
    if (brightness == Brightness.light) {
      return _lightNeutralCard;
    }
    
    // For dark mode, we apply a semi-transparent white overlay
    // The higher the elevation, the more intense the overlay
    final overlayLevel = elevation < _elevationOverlayPercentages.length
        ? _elevationOverlayPercentages[elevation]
        : _elevationOverlayPercentages.last;
        
    return Color.alphaBlend(
      Colors.white.withOpacity(overlayLevel),
      _darkNeutralCard,
    );
  }
}

// ========== EXTENSION METHODS ==========
// Extension to easily access colors from the theme
extension ThemeExtension on ThemeData {
  // Primary palette
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get tertiaryColor => colorScheme.tertiary;
  
  // Surface colors
  Color get backgroundColor => colorScheme.background;
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceVariantColor => colorScheme.surfaceVariant;
  
  // Text colors
  Color get textPrimaryColor => colorScheme.onSurface;
  Color get textSecondaryColor => colorScheme.onSurfaceVariant;
  Color get textTertiaryColor => 
      brightness == Brightness.light ? AppTheme._lightTextTertiary : AppTheme._darkTextTertiary;
  
  // Status colors
  Color get errorColor => colorScheme.error;
  Color get successColor => 
      brightness == Brightness.light ? AppTheme._lightSuccess : AppTheme._darkSuccess;
  Color get warningColor =>
      brightness == Brightness.light ? AppTheme._lightWarning : AppTheme._darkWarning;
  Color get infoColor =>
      brightness == Brightness.light ? AppTheme._lightInfo : AppTheme._darkInfo;
  
  // Utility colors
  Color get borderColor => colorScheme.outline;
  Color get disabledColor => colorScheme.outlineVariant;
  
  // Other useful accessors
  bool get isDarkMode => brightness == Brightness.dark;
  SystemUiOverlayStyle get systemOverlayStyle => 
      AppTheme.getSystemOverlayStyle(brightness);
      
  // Function to get appropriately themed status colors
  Color getStatusColor(String status) => 
      AppTheme.getStatusColor(status: status, brightness: brightness);
      
  // Function to get appropriately themed card decoration
  BoxDecoration getCardDecoration({
    bool hasShadow = true,
    bool hasBorder = true,
    double radius = AppTheme.radiusLG,
  }) => AppTheme.getCardDecoration(
    brightness: brightness,
    hasShadow: hasShadow,
    hasBorder: hasBorder,
    radius: radius,
  );
  
  // Function to get custom elevated surfaces for dark mode
  Color getElevatedSurfaceColor(int elevation) => 
      AppTheme.getElevatedSurfaceColor(
        brightness: brightness,
        elevation: elevation,
      );
}


/// Background painter for decorative curved backgrounds
/// Used throughout the app for consistent visual styling
class BackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double primaryOpacity;
  final double secondaryOpacity;

  BackgroundPainter({
    this.primaryColor = const Color(0xFFE0F2F1), // teal.shade50
    this.secondaryColor = const Color(0xFFB2DFDB), // teal.shade100
    this.primaryOpacity = 0.3,
    this.secondaryOpacity = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryPaint = Paint()
      ..color = primaryColor.withOpacity(primaryOpacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.2,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, primaryPaint);

    // Add a second decorative curve
    final path2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.8,
        0,
        size.height * 0.85,
      )
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    final secondaryPaint = Paint()
      ..color = secondaryColor.withOpacity(secondaryOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path2, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => 
    oldDelegate.primaryColor != primaryColor ||
    oldDelegate.secondaryColor != secondaryColor ||
    oldDelegate.primaryOpacity != primaryOpacity ||
    oldDelegate.secondaryOpacity != secondaryOpacity;
}