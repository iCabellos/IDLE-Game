import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_rpg/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('exposes the core palette', () {
      expect(AppColors.bg, const Color(0xFF0F1B2A));
      expect(AppColors.success, const Color(0xFF059669));
      expect(AppColors.danger, const Color(0xFFDC2626));
    });
  });

  group('RarityColors.forRarity', () {
    test('maps low tiers to their specific colors', () {
      expect(RarityColors.forRarity(1), RarityColors.broken);
      expect(RarityColors.forRarity(5), RarityColors.rare);
      expect(RarityColors.forRarity(10), RarityColors.relic);
    });

    test('maps Legendary and above to the golden glow', () {
      expect(RarityColors.forRarity(11), RarityColors.legendary);
      expect(RarityColors.forRarity(21), RarityColors.legendary);
    });
  });

  group('AppTheme', () {
    test('produces a dark theme with the scaffold background', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.bg);
    });
  });
}
