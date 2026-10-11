import 'package:flutter/material.dart';

/// CA brand — placeholder palette pending final brand sign-off (Phase 0 open item).
/// Deep green = money / farm / growth; gold accent = value. High contrast for outdoor use.
const caGreen = Color(0xFF14532D);
const caGold = Color(0xFFC5A04D);

ThemeData caTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: caGreen),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(backgroundColor: caGreen, foregroundColor: Colors.white),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: caGreen, foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
