import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta inspirada en la imagen
  static const Color primaryColor = Color(0xFF7D91FF);
  static const Color secondaryColor = Color(0xFF2C2C2C); // Gris oscuro
  static const Color backgroundColor = Color(0xFF121212); // Negro casi puro
  static const Color cardColor = Color(0xFF1E1E1E); // Para componentes
  static const Color textColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white70,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        centerTitle: true,
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.merriweather(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
        titleLarge: GoogleFonts.merriweather(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
      ),
      iconTheme: const IconThemeData(color: primaryColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: Colors.white60),
        labelStyle: TextStyle(color: primaryColor),
      ),
      cardColor: cardColor,
    );
  }
}
