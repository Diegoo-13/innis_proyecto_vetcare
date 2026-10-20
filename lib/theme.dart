import 'package:flutter/material.dart';

/// Paleta VetCare. Desde el prototipo v24 el acento principal es un azul más fuerte
/// (pedido del cliente: "azul más fuerte").
class C {
  static const Color primary = Color(0xFF1F5FD9);
  static const Color primaryDark = Color(0xFF143FA3);
  static const Color primarySoft = Color(0xFFE2EBFC);
  static const Color brand1 = Color(0xFF1D4FC4);
  static const Color brand2 = Color(0xFF0B1240);
  static const Color ink = Color(0xFF16213E);
  static const Color inkSoft = Color(0xFF5B6478);
  static const Color muted = Color(0xFF9299AE);
  static const Color line = Color(0xFFE7EAF4);
  static const Color surface2 = Color(0xFFF1F4FA);
  static const Color accent = Color(0xFFF0568E);
  static const Color accentSoft = Color(0xFFFCE3ED);
  static const Color good = Color(0xFF22A06B);
  static const Color goodSoft = Color(0xFFE1F5EA);
  static const Color warn = Color(0xFFC98A2C);
  static const Color warnSoft = Color(0xFFFBEED9);
  static const Color bad = Color(0xFFD6483B);
  static const Color badSoft = Color(0xFFFBE1DE);
  static const Color cat1Soft = Color(0xFFFDEDCC);
  static const Color cat2Soft = Color(0xFFFCE3ED);
  static const Color cat3Soft = Color(0xFFE4E9FE);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand1, brand2],
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.primary,
      primary: C.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
    ),
    dividerColor: C.line,
  );
}
