import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/inventory_item.dart';
import '../../core/pixel/pixel_anim.dart';
import '../../core/pixel/pixel_hp_bar.dart';
import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';
import '../inventory/widgets/item_detail_sheet.dart';

/// Team management: every hero with role, level, always-visible health and
/// their equipment loadout. Tapping equipped gear opens the shared item
/// sheet; the Loot Bag stays a pure inventory.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  static const _roster = [
    (
      frames: Sprites.warriorFrames,
      name: 'VANGUARD',
      job: 'WARRIOR · TANK',
      level: 'LV 12',
      hp: 0.85,
      element: 'Physical',
      gearIds: ['ironclad-helm', 'ironclad-cuirass', 'ironclad-greaves', 'rare-sword-1', 'common-ring-1'],
    ),
    (
      frames: Sprites.berserkerFrames,
      name: 'EMBER',
      job: 'BERSERKER · DPS',
      level: 'LV 11',
      hp: 0.62,
      element: 'Fire',
      gearIds: <String>[],
    ),
    (
      frames: Sprites.clericFrames,
      name: 'LUMEN',
      job: 'CLERIC · HEALER',
      level: 'LV 12',
      hp: 0.95,
      element: 'Lightning',
      gearIds: <String>[],
    ),
    (
      frames: Sprites.mageFrames,
      name: 'FROST',
      job: 'MAGE · DPS',
      level: 'LV 10',
      hp: 0.72,
      element: 'Ice',
      gearIds: <String>[],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    PixelArt(Sprites.helmet, size: 34),
                    SizedBox(width: 10),
                    PixelText('YOUR TEAM', size: 18),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _roster.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final hero = _roster[index];
                    return _HeroPanel(
                      frames: hero.frames,
                      name: hero.name,
                      job: hero.job,
                      level: hero.level,
                      hp: hero.hp,
                      element: hero.element,
                      gearIds: hero.gearIds,
                    )
                        .animate()
                        .fadeIn(delay: (70 * index).ms, duration: 300.ms)
                        .slideY(begin: 0.06, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.frames,
    required this.name,
    required this.job,
    required this.level,
    required this.hp,
    required this.element,
    required this.gearIds,
  });

  final List<PixelSprite> frames;
  final String name;
  final String job;
  final String level;
  final double hp;
  final String element;
  final List<String> gearIds;

  @override
  Widget build(BuildContext context) {
    final gear = mockInventory.where((i) => gearIds.contains(i.id)).toList();

    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedPixelArt(frames, size: 52, stepMs: 650),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: PixelText(name, size: 12, maxLines: 1)),
                        PixelBadge(label: level, color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        PixelArt(SpriteLibrary.forElement(element), size: 14),
                        const SizedBox(width: 5),
                        PixelText(job, size: 8, color: AppColors.muted, shadow: false),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PixelHpBar(fraction: hp, width: 150, height: 9),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Equipment loadout: filled cells open the item sheet, empties are
          // dim slots to fill.
          Row(
            children: [
              for (final item in gear)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => showItemDetailSheet(context, item),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        border: Border.all(
                          color: RarityColors.forRarity(item.rarityTier),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: PixelArt(SpriteLibrary.forSlot(item.slot), size: 28),
                      ),
                    ),
                  ),
                ),
              for (var i = gear.length; i < 6; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      border: Border.all(
                        color: AppColors.muted.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: PixelText('·', size: 12,
                          color: AppColors.muted, shadow: false),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
