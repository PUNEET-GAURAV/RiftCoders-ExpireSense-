import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cyber-Tech 2.0 Palette
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color electricPurple = Color(0xFFD500F9);
  static const Color deepCharcoal = Color(0xFF0A0E14); // Slightly bluer dark
  static const Color surfaceDark = Color(0xFF151920);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB0B0B0);
  
  // Legacy colors for compatibility (if needed during transition, but mapped to new scheme)
  static const Color softTeal = neonCyan;
  static const Color errorRed = Color(0xFFFF5252);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepCharcoal,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: neonCyan, 
        secondary: electricPurple,
        tertiary: neonCyan,
        surface: surfaceDark,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textWhite,
        error: errorRed,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: textWhite, fontWeight: FontWeight.w500), // Body remains legible
        titleSmall: GoogleFonts.outfit(color: textWhite, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.outfit(color: textWhite),
        bodyMedium: GoogleFonts.outfit(color: textWhite),
        bodySmall: GoogleFonts.outfit(color: textGrey),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2), // Neon glow effect
        ),
        labelStyle: const TextStyle(color: textGrey),
        prefixIconColor: neonCyan,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black, 
          elevation: 5,
          shadowColor: neonCyan.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: electricPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        splashColor: neonCyan,
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: neonCyan,
        inactiveTrackColor: Colors.white10,
        thumbColor: Colors.white,
        overlayColor: neonCyan.withOpacity(0.2),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return neonCyan;
            return Colors.grey[400];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
             if (states.contains(MaterialState.selected)) return neonCyan.withOpacity(0.3);
             return Colors.grey.withOpacity(0.1);
        }),
      ),
    );
  }
}
