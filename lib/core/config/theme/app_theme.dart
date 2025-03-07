import 'package:flutter/material.dart';

import '../helpers/font_family.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    cardColor: Colors.grey[100],
    cardTheme: CardTheme(
      color: Colors.grey[100],
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      bodyMedium: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      bodySmall: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      displayLarge: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      displayMedium: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      displaySmall: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      labelLarge: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      labelMedium: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      labelSmall: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      headlineLarge: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      headlineMedium: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      headlineSmall: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      titleLarge: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      titleMedium: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
      titleSmall: TextStyle(
        color: Colors.black,
        fontFamily: FontFamily.afacadFlux,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        backgroundColor: Colors.black,
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.blue, width: 2.0),
      ),
      hintStyle: TextStyle(color: Colors.grey),
    ),
  );

  static final darkTheme = ThemeData(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.grey[900],
    brightness: Brightness.dark,
    cardColor: Color(0xFF2A2D37),
    cardTheme: CardTheme(
      color: Color(0xFF2A2D37),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      bodySmall: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      displayLarge: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      labelMedium: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      labelSmall: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      headlineLarge: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontFamily: FontFamily.afacadFlux,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        backgroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.white, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.blue, width: 2.0),
      ),
      hintStyle: TextStyle(color: Colors.white70),
    ),
  );
}
