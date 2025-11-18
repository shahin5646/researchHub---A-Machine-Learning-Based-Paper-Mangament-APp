import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern, neutral color palette - professional and subtle
  static const Color primaryBlue = Color(0xFF3B82F6); // Muted blue
  static const Color primaryPurple = Color(0xFF4F46E5); // Muted indigo
  static const Color accentOrange = Color(0xFF9C4221); // Muted orange
  static const Color accentGreen = Color(0xFF047857); // Muted green
  static const Color accentPink = Color(0xFF9D174D); // Muted pink
  static const Color warningAmber = Color(0xFFB45309); // Muted amber

  // Neutral colors
  static const Color darkSlate = Color(0xFF1F2937); // Dark slate
  static const Color lightGray = Color(0xFFE5E7EB); // Light gray
  static const Color offWhite = Color(0xFFF9FAFB); // Off white
  static const Color mediumGray = Color(0xFF6B7280); // Medium gray

  // Gradient colors
  static const List<Color> primaryGradient = [primaryBlue, primaryPurple];
  static const List<Color> secondaryGradient = [accentOrange, accentPink];
  static const List<Color> successGradient = [accentGreen, Color(0xFF4CAF50)];
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: darkSlate,
      secondary: primaryBlue,
      tertiary: accentGreen,
      surface: offWhite, // Subtle off-white background
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkSlate,
    ),
    scaffoldBackgroundColor: offWhite,
    cardTheme: CardThemeData(
      elevation: 0.5, // Very subtle elevation for professional look
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Less rounded corners
        side: BorderSide(color: lightGray, width: 1), // Subtle border
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: darkSlate,
      centerTitle: false, // Left-aligned titles for modern design
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, // Slightly smaller for sleeker look
        fontWeight: FontWeight.w600,
        color: darkSlate,
        letterSpacing: -0.2, // Tighter letter spacing for modern typography
      ),
      iconTheme: IconThemeData(color: darkSlate, size: 20),
      scrolledUnderElevation: 0.5, // Very subtle elevation when scrolled
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -1.0, // Tighter spacing for modern look
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: const Color(0xFF2D3748),
        height: 1.5, // Improved readability for body text
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: const Color(0xFF4A5568),
        height: 1.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0, // Completely flat for professional look
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // Less rounded corners
          side: BorderSide(
              color: primaryBlue.withValues(alpha: 0.5),
              width: 1), // Subtle border
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        shadowColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0, // Completely flat for modern design
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // Less rounded corners
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide:
            BorderSide(color: primaryBlue.withValues(alpha: 0.7), width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        color: mediumGray,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.inter(
        color: mediumGray.withValues(alpha: 0.7),
        fontSize: 14,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: primaryBlue,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightGray,
      selectedColor: darkSlate,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(4), // Less rounded for professional look
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
    dividerColor: lightGray,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: mediumGray,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
      ),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryBlue,
      secondary: primaryBlue.withValues(alpha: 0.8),
      tertiary: accentGreen,
      surface: const Color(0xFF111827), // Dark slate background, more neutral
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFFE5E7EB),
    ),
    scaffoldBackgroundColor: const Color(0xFF111827),
    cardTheme: CardThemeData(
      elevation: 1, // Subtle elevation
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E293B), // Slightly lighter for cards
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 22),
      scrolledUnderElevation: 1.5,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -1.0,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: const Color(0xFFE2E8F0),
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: const Color(0xFFCBD5E1),
        height: 1.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: const Color(0xFF94A3B8),
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF64748B),
        fontSize: 14,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: primaryBlue,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryBlue.withValues(alpha: 0.2),
      selectedColor: primaryBlue,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
    dividerColor: const Color(0xFF334155),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
      selectedItemColor: primaryBlue,
      unselectedItemColor: const Color(0xFF94A3B8),
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
      ),
      elevation: 8,
    ),
  );

  // Helper methods to get theme-aware colors
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color textColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color secondaryTextColor(BuildContext context) =>
      isDark(context) ? const Color(0xFFB0B0B0) : const Color(0xFF4A5568);

  // Professional subtle gradient helpers
  static LinearGradient primaryGradientWidget = LinearGradient(
    colors: [primaryBlue, primaryBlue.withValues(alpha: 0.85)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: const [0.0, 1.0], // Subtle gradient distribution
  );

  static LinearGradient secondaryGradientWidget = LinearGradient(
    colors: [darkSlate, darkSlate.withValues(alpha: 0.85)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: const [0.0, 1.0],
  );

  static LinearGradient successGradientWidget = LinearGradient(
    colors: [accentGreen, accentGreen.withValues(alpha: 0.85)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: const [0.0, 1.0],
  );

  // Subtle gradient for backgrounds
  static LinearGradient subtleBackgroundGradient = const LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFF9FAFB),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );

  // Subtle dark gradient for backgrounds
  static LinearGradient subtleDarkBackgroundGradient = const LinearGradient(
    colors: [
      Color(0xFF111827),
      Color(0xFF1F2937),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );

  // Professional shadow helpers
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> floatingActionButtonShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}
