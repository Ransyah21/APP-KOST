import 'package:flutter/material.dart';

/// Nama aplikasi (default, ganti kapan saja).
class AppInfo {
  static const String name = 'Aplikasi Kost';
}

/// Tema default (ganti warna cukup lewat [seed]).
class AppTheme {
  static const Color seed = Color(0xFF0F766E);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
