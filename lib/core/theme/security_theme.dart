import 'package:flutter/material.dart';

class SecurityTheme {
  // SOC Dark Theme Colors
  static const Color socBackground = Color(0xFF0A0A0B);
  static const Color socSurface = Color(0xFF1A1A1C);
  static const Color socCard = Color(0xFF2A2A2E);
  static const Color socBorder = Color(0xFF3A3A3F);
  
  // Threat Level Colors
  static const Color criticalRed = Color(0xFFFF4444);
  static const Color highOrange = Color(0xFFFF8800);
  static const Color mediumYellow = Color(0xFFFFBB33);
  static const Color lowGreen = Color(0xFF00CC44);
  static const Color infoBlue = Color(0xFF0088FF);
  
  // Security Status Colors
  static const Color secureGreen = Color(0xFF00FF88);
  static const Color warningAmber = Color(0xFFFFAA00);
  static const Color dangerRed = Color(0xFFFF3366);
  static const Color unknownGray = Color(0xFF888888);
  
  // Accent Colors
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color neonBlue = Color(0xFF00CCFF);
  static const Color neonPurple = Color(0xFF8844FF);
  static const Color neonPink = Color(0xFFFF44AA);

  static ThemeData get socDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: socBackground,
        surfaceContainer: socSurface,
        surfaceContainerHighest: socCard,
        outline: socBorder,
        primary: neonGreen,
        secondary: neonBlue,
        tertiary: neonPurple,
        error: criticalRed,
        onSurface: Colors.white,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      ),
      scaffoldBackgroundColor: socBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: socSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
      ),
      cardTheme: CardThemeData(
        color: socCard,
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: socBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonBlue,
          side: const BorderSide(color: neonBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonPurple,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: socSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: socBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: socBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: criticalRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Roboto Mono',
        ),
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontFamily: 'Roboto Mono',
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonGreen;
          }
          return Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonGreen.withValues(alpha: 0.3);
          }
          return Colors.white24;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonGreen;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: Colors.white54, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonGreen;
          }
          return Colors.white54;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonGreen,
        inactiveTrackColor: Colors.white24,
        thumbColor: neonGreen,
        overlayColor: neonGreen.withValues(alpha: 0.2),
        valueIndicatorColor: neonGreen,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonGreen,
        linearTrackColor: Colors.white24,
        circularTrackColor: Colors.white24,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: neonGreen,
        unselectedLabelColor: Colors.white54,
        indicatorColor: neonGreen,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: socSurface,
        selectedItemColor: neonGreen,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: socSurface,
        selectedIconTheme: IconThemeData(color: neonGreen),
        unselectedIconTheme: IconThemeData(color: Colors.white54),
        selectedLabelTextStyle: TextStyle(
          color: neonGreen,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white54,
          fontFamily: 'Roboto Mono',
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: socSurface,
        scrimColor: Colors.black54,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
        selectedColor: neonGreen,
        selectedTileColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: socBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: socCard,
        selectedColor: neonGreen.withValues(alpha: 0.2),
        disabledColor: Colors.white24,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto Mono',
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'Roboto Mono',
        ),
        side: const BorderSide(color: socBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: socCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: socBorder),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto Mono',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: socCard,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto Mono',
        ),
        actionTextColor: neonGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: socSurface,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontFamily: 'Roboto Mono',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: socBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: socSurface,
        modalBackgroundColor: socSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w300,
          fontFamily: 'Roboto Mono',
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto Mono',
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto Mono',
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto Mono',
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto Mono',
        ),
        titleSmall: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto Mono',
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto Mono',
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto Mono',
        ),
        bodySmall: TextStyle(
          color: Colors.white70,
          fontFamily: 'Roboto Mono',
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto Mono',
        ),
        labelMedium: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto Mono',
        ),
        labelSmall: TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto Mono',
        ),
      ),
    );
  }

  // Threat Level Color Helpers
  static Color getThreatLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return criticalRed;
      case 'high':
        return highOrange;
      case 'medium':
        return mediumYellow;
      case 'low':
        return lowGreen;
      case 'info':
        return infoBlue;
      default:
        return unknownGray;
    }
  }

  static Color getSecurityStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'secure':
      case 'healthy':
      case 'good':
        return secureGreen;
      case 'warning':
      case 'caution':
        return warningAmber;
      case 'danger':
      case 'critical':
      case 'bad':
        return dangerRed;
      default:
        return unknownGray;
    }
  }

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Security-specific gradients
  static const LinearGradient criticalGradient = LinearGradient(
    colors: [criticalRed, Color(0xFFCC0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secureGradient = LinearGradient(
    colors: [secureGreen, Color(0xFF00AA66)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonGreen, neonBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box shadows for SOC theme
  static const List<BoxShadow> socCardShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> socElevatedShadow = [
    BoxShadow(
      color: Colors.black38,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  // Text styles for security metrics
  static const TextStyle metricValueStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: neonGreen,
    fontFamily: 'Roboto Mono',
  );

  static const TextStyle metricLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    fontFamily: 'Roboto Mono',
  );

  static const TextStyle alertTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: 'Roboto Mono',
  );

  static const TextStyle codeStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: neonGreen,
    fontFamily: 'Roboto Mono',
    letterSpacing: 0.5,
  );
}

// Extension for easy theme access
extension SecurityThemeExtension on BuildContext {
  SecurityTheme get securityTheme => SecurityTheme();
  
  Color getThreatColor(String level) => SecurityTheme.getThreatLevelColor(level);
  Color getStatusColor(String status) => SecurityTheme.getSecurityStatusColor(status);
}
