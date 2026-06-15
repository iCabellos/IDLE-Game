import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// High-level character states surfaced to the player.
///
/// Per the F7 UX rule, raw combat numbers (HP, attack, defense, %s) are
/// NEVER shown directly — only one of these descriptive states.
enum CharacterStatus {
  winning,
  danger,
  stuck,
  rewardsReady,
  steamDesynced,
}

extension CharacterStatusX on CharacterStatus {
  String get label => switch (this) {
        CharacterStatus.winning => 'Winning',
        CharacterStatus.danger => 'Danger',
        CharacterStatus.stuck => 'Stuck',
        CharacterStatus.rewardsReady => 'Rewards Ready',
        CharacterStatus.steamDesynced => 'Steam Desynced',
      };

  String get description => switch (this) {
        CharacterStatus.winning =>
          'Your character is holding its own and gaining ground.',
        CharacterStatus.danger =>
          'Your character is close to defeat. Consider gearing up.',
        CharacterStatus.stuck =>
          'Progress has stalled in this zone. Try upgrading gear or moving on.',
        CharacterStatus.rewardsReady =>
          'Idle rewards are waiting to be claimed.',
        CharacterStatus.steamDesynced =>
          'We could not verify your Steam inventory. Reconnect to resync.',
      };

  Color get color => switch (this) {
        CharacterStatus.winning => AppColors.success,
        CharacterStatus.danger => AppColors.danger,
        CharacterStatus.stuck => AppColors.amber,
        CharacterStatus.rewardsReady => AppColors.accent,
        CharacterStatus.steamDesynced => AppColors.muted,
      };

  IconData get icon => switch (this) {
        CharacterStatus.winning => Icons.trending_up,
        CharacterStatus.danger => Icons.warning_amber_rounded,
        CharacterStatus.stuck => Icons.hourglass_bottom,
        CharacterStatus.rewardsReady => Icons.card_giftcard,
        CharacterStatus.steamDesynced => Icons.sync_problem,
      };
}
