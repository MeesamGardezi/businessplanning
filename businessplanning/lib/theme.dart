// lib/theme/theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation
  
  // ========== COLORS ==========
  static const Color _primaryColor = Color(0xFF00796B); // teal.shade700
  static const Color _secondaryColor = Color(0xFF009688); // teal.shade500
  static const Color _tertiaryColor = Color(0xFF4DB6AC); // teal.shade300
  
  // Neutrals
  static const Color _neutralBg = Color(0xFFFAFAFA); // grey.shade50
  static const Color _neutralCard = Color(0xFFFFFFFF); // white
  static const Color _neutralSurface = Color(0xFFF5F5F5); // grey.shade100
  static const Color _neutralBorder = Color(0xFFEEEEEE); // grey.shade200
  static const Color _neutralDisabled = Color(0xFFE0E0E0); // grey.shade300
  
  // Text
  static const Color _textPrimary = Color(0xFF212121); // grey.shade900
  static const Color _textSecondary = Color(0xFF616161); // grey.shade700
  static const Color _textTertiary = Color(0xFF9E9E9E); // grey.shade500
  static const Color _textOnPrimary = Color(0xFFFFFFFF); // white
  
  // Status
  static const Color _error = Color(0xFFEF5350); // red.shade400
  static const Color _success = Color(0xFF66BB6A); // green.shade400
  static const Color _warning = Color(0xFFFFB74D); // orange.shade300
  static const Color _info = Color(0xFF4FC3F7); // lightBlue.shade300
  
  // Additional palette
  static const Color _accentBlue = Color(0xFF42A5F5); // blue.shade400
  static const Color _accentPurple = Color(0xFFAB47BC); // purple.shade400
  static const Color _accentAmber = Color(0xFFFFCA28); // amber.shade400
  
  // ========== SPACING SYSTEM ==========
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  static const double spaceXXXL = 64.0;
  
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
  
  // ========== MAIN THEME ==========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        primary: _primaryColor,
        onPrimary: _textOnPrimary,
        primaryContainer: _primaryColor.withOpacity(0.1),
        onPrimaryContainer: _primaryColor,
        secondary: _secondaryColor,
        onSecondary: _textOnPrimary,
        secondaryContainer: _secondaryColor.withOpacity(0.1),
        onSecondaryContainer: _secondaryColor,
        tertiary: _tertiaryColor,
        onTertiary: _textOnPrimary,
        tertiaryContainer: _tertiaryColor.withOpacity(0.1),
        onTertiaryContainer: _tertiaryColor,
        error: _error,
        onError: _textOnPrimary,
        errorContainer: _error.withOpacity(0.1),
        onErrorContainer: _error,
        background: _neutralBg,
        onBackground: _textPrimary,
        surface: _neutralCard,
        onSurface: _textPrimary,
        surfaceVariant: _neutralSurface,
        onSurfaceVariant: _textSecondary,
        outline: _neutralBorder,
        outlineVariant: _neutralDisabled,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: _textPrimary,
        onInverseSurface: _neutralCard,
        inversePrimary: _tertiaryColor,
        brightness: Brightness.light,
      ),
      
      // ========== TYPOGRAPHY ==========
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
          height: 1.2,
          letterSpacing: -0.25,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: _textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: _textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
          height: 1.4,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
          height: 1.4,
          letterSpacing: 0.5,
        ),
      ),
      
      // ========== COMPONENT THEMES ==========
      // Card Theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: _neutralBorder, width: 1),
        ),
        color: _neutralCard,
        margin: const EdgeInsets.all(spaceMD),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _textOnPrimary,
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
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1.5),
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
          foregroundColor: _primaryColor,
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
        fillColor: _neutralSurface,
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
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: _textTertiary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: _textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: _textTertiary,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: _error,
          fontSize: 12,
        ),
        prefixIconColor: _textSecondary,
        suffixIconColor: _textSecondary,
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXS),
        ),
        side: const BorderSide(color: _textSecondary, width: 1.5),
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return _neutralDisabled;
          }
          if (states.contains(MaterialState.selected)) {
            return _primaryColor;
          }
          return Colors.transparent;
        }),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _neutralBorder,
        thickness: 1,
        space: spaceLG,
      ),
      
      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        color: _neutralCard,
        textStyle: const TextStyle(
          color: _textPrimary,
          fontSize: 14,
        ),
      ),
      
      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _textPrimary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        textStyle: const TextStyle(
          color: _neutralCard,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        contentTextStyle: const TextStyle(
          color: _neutralCard,
          fontSize: 14,
        ),
        actionTextColor: _tertiaryColor,
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        elevation: 0,
        backgroundColor: _neutralCard,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: _textSecondary,
        ),
      ),
      
      // BottomSheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLG),
          ),
        ),
        elevation: 0,
        backgroundColor: _neutralCard,
        modalBackgroundColor: _neutralCard,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _neutralCard,
        foregroundColor: _textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        iconTheme: IconThemeData(
          color: _textPrimary,
          size: 24,
        ),
        centerTitle: false,
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: _primaryColor,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _primaryColor,
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
        backgroundColor: _neutralCard,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondary,
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
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _neutralSurface,
        disabledColor: _neutralDisabled,
        selectedColor: _primaryColor.withOpacity(0.1),
        secondarySelectedColor: _primaryColor.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: _textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          color: _primaryColor,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCircular),
        ),
      ),
      
      // Additional properties
      splashColor: _primaryColor.withOpacity(0.1),
      highlightColor: _primaryColor.withOpacity(0.05),
      scaffoldBackgroundColor: _neutralBg,
      dividerColor: _neutralBorder,
      disabledColor: _neutralDisabled,
      hintColor: _textTertiary,
      iconTheme: const IconThemeData(
        color: _textSecondary,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: _textOnPrimary,
        size: 24,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // UI Utility Methods
  static SystemUiOverlayStyle get systemOverlayStyle => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: _neutralCard,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  
  // ========== CUSTOM COMPONENT STYLES ==========
  // Claude-style Sidebar Item
  static BoxDecoration getSidebarItemDecoration({required bool isSelected}) {
    return BoxDecoration(
      color: isSelected ? _primaryColor.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(radiusMD),
    );
  }
  
  static TextStyle getSidebarItemTextStyle({required bool isSelected}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: isSelected ? _primaryColor : _textSecondary,
    );
  }
  
  static Color getSidebarItemIconColor({required bool isSelected}) {
    return isSelected ? _primaryColor : _textSecondary;
  }
  
  // Card variants
  static BoxDecoration getCardDecoration({
    bool hasShadow = true,
    bool hasBorder = true,
    double radius = radiusLG,
  }) {
    return BoxDecoration(
      color: _neutralCard,
      borderRadius: BorderRadius.circular(radius),
      border: hasBorder ? Border.all(color: _neutralBorder) : null,
      boxShadow: hasShadow ? shadowMedium : null,
    );
  }
  
  // Status indicators
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'complete':
      case 'completed':
      case 'active':
        return _success;
      case 'warning':
      case 'pending':
      case 'in progress':
        return _warning;
      case 'error':
      case 'failed':
        return _error;
      case 'info':
      case 'draft':
        return _info;
      default:
        return _textSecondary;
    }
  }
  
  // Badge styles
  static BoxDecoration getBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radiusCircular),
    );
  }
}

// Extension to easily access colors from the theme
extension ThemeExtension on ThemeData {
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get tertiaryColor => colorScheme.tertiary;
  Color get backgroundColor => colorScheme.background;
  Color get surfaceColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;
  Color get textPrimaryColor => colorScheme.onSurface;
  Color get textSecondaryColor => colorScheme.onSurfaceVariant;
  Color get borderColor => colorScheme.outline;
  Color get disabledColor => colorScheme.outlineVariant;
}