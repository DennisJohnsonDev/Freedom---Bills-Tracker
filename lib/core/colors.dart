import 'package:flutter/material.dart';

/// Freedom palette — OLED-first, calm, premium.
class AppColors {
  AppColors._();

  // Surfaces
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF0C0C0E);
  static const surfaceElevated = Color(0xFF131316);
  static const surfaceTop = Color(0xFF1A1A1F);
  static const border = Color(0xFF1F1F24);
  static const borderSoft = Color(0xFF141418);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF5A5A60);
  static const textQuaternary = Color(0xFF3A3A40);

  // Brand / accent (freedom = lime)
  static const accent = Color(0xFFC7F462);
  static const accentDim = Color(0x33C7F462);
  static const accentInk = Color(0xFF0A1A00);

  // Semantic
  static const success = Color(0xFF34D399);
  static const info = Color(0xFF60A5FA);
  static const warning = Color(0xFFFBBF24);
  static const urgent = Color(0xFFFB923C);
  static const danger = Color(0xFFEF4444);

  // Per-loan accents (chosen by colorIndex)
  static const loanAccents = <Color>[
    Color(0xFFC7F462), // lime
    Color(0xFF60A5FA), // sky
    Color(0xFFF472B6), // pink
    Color(0xFFFBBF24), // amber
    Color(0xFFA78BFA), // violet
    Color(0xFF34D399), // emerald
    Color(0xFFFB923C), // orange
    Color(0xFF22D3EE), // cyan
  ];

  static Color loanAccent(int index) =>
      loanAccents[index.abs() % loanAccents.length];
}
