import 'package:flutter/material.dart';

/// Core color palette for the IdleRPG dark theme.
/// Defined in Section F7 of the implementation plan.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0F2740);
  static const blue = Color(0xFF1A56A0);
  static const accent = Color(0xFF0EA5E9);
  static const success = Color(0xFF059669);
  static const danger = Color(0xFFDC2626);
  static const amber = Color(0xFFD97706);
  static const surface = Color(0xFF1E2D3D);
  static const bg = Color(0xFF0F1B2A);
  static const text = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
}

/// Border / glow color for each item rarity tier.
/// Index aligns with the ItemRarity enum (1-based in the backend).
class RarityColors {
  RarityColors._();

  static const broken = Color(0xFF6B7280);
  static const worn = Color(0xFF9CA3AF);
  static const common = Color(0xFFFFFFFF);
  static const uncommon = Color(0xFF34D399);
  static const rare = Color(0xFF60A5FA);
  static const superior = Color(0xFF818CF8);
  static const epic = Color(0xFFA78BFA);
  static const mythic = Color(0xFFF472B6);
  static const ancient = Color(0xFFFBBF24);
  static const relic = Color(0xFFF97316);
  static const legendary = Color(0xFFFFD700); // + particle animation

  /// Resolve a rarity color by its 1-based enum value.
  static Color forRarity(int rarity) {
    return switch (rarity) {
      1 => broken,
      2 => worn,
      3 => common,
      4 => uncommon,
      5 => rare,
      6 => superior,
      7 => epic,
      8 => mythic,
      9 => ancient,
      10 => relic,
      _ => legendary, // Legendary (11) and above all use the golden glow.
    };
  }
}

/// Builds the application-wide dark theme.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.blue,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
  }
}
