import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/character_status.dart';
import '../../core/models/loot_drop_view.dart';
import '../../core/pixel/pixel_anim.dart';
import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/battle_stage.dart';
import 'widgets/character_status_card.dart';

/// The guild hall: party lineup, live battle diorama, adventure log.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CharacterStatus _status = CharacterStatus.winning;

  void _cycleStatus() {
    setState(() {
      _status = CharacterStatus.values
          .elementAt((_status.index + 1) % CharacterStatus.values.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HallHeader(onCycle: _cycleStatus),
                const SizedBox(height: 16),
                _BattleDiorama(status: _status)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 16),
                CharacterStatusCard(
                  status: _status,
                  zoneName: 'Emberfall Outskirts',
                ),
                const SizedBox(height: 16),
                _AdventureLog(status: _status)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 16),
                const _LootFeed()
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms),
                const SizedBox(height: 16),
                const _SetBonusPanel()
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HallHeader extends StatelessWidget {
  const _HallHeader({required this.onCycle});

  final VoidCallback onCycle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PixelArt(Sprites.castle, size: 34),
        const SizedBox(width: 10),
        const Expanded(child: PixelText('GUILD HALL', size: 18)),
        // Demo-only: cycles through the readable statuses.
        SizedBox(
          width: 56,
          child: PixelButton(
            label: 'DEMO',
            height: 34,
            color: AppColors.surface,
            onPressed: onCycle,
          ),
        ),
      ],
    );
  }
}

/// The live battle scene: the whole party fighting the current wave with
/// clear turn indicators and always-visible health. Outcomes come from the
/// readable status.
class _BattleDiorama extends StatelessWidget {
  const _BattleDiorama({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    final stuck = status == CharacterStatus.stuck;
    final danger = status == CharacterStatus.danger;

    return PixelPanel(
      fill: const Color(0xFF14243A),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PixelText('WAVE 7/10', size: 10, color: AppColors.muted),
              PixelBadge(
                label: stuck ? 'WALL' : 'FIGHTING',
                color: stuck ? AppColors.amber : AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const PixelProgressBar(filled: 7, total: 10, color: AppColors.accent),
          const SizedBox(height: 10),
          // Enemy weaknesses guide gear choice (mirrors EnemyPreview).
          Row(
            children: [
              const PixelText('WEAK TO', size: 8, color: AppColors.muted),
              const SizedBox(width: 8),
              for (final element in danger || stuck
                  ? const ['Ice', 'Poison', 'Physical']
                  : const ['Fire', 'Lightning'])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: PixelArt(SpriteLibrary.forElement(element), size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          BattleStage(bossFight: danger || stuck),
        ],
      ),
    );
  }
}

class _AdventureLog extends StatefulWidget {
  const _AdventureLog({required this.status});

  final CharacterStatus status;

  @override
  State<_AdventureLog> createState() => _AdventureLogState();
}

class _AdventureLogState extends State<_AdventureLog> {
  int _sparkTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final ready = widget.status == CharacterStatus.rewardsReady;

    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PixelText('ADVENTURE LOG', size: 11, color: AppColors.muted),
          const SizedBox(height: 10),
          const _LogRow(sprite: Sprites.hourglass, label: 'TIME AWAY', value: '6H 42M'),
          const _LogRow(sprite: Sprites.skull, label: 'ENEMIES DEFEATED', value: 'DOZENS'),
          const _LogRow(sprite: Sprites.loot, label: 'LOOT FOUND', value: '3 ITEMS'),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              PixelButton(
                label: ready ? 'Claim rewards' : 'No rewards yet',
                color: AppColors.success,
                onPressed: ready
                    ? () => setState(() => _sparkTrigger++)
                    : null,
                icon: const PixelArt(Sprites.chest, size: 22),
              ),
              // One-shot gold sparks on claim; dormant otherwise.
              IgnorePointer(
                child: SparkBurst(trigger: _sparkTrigger, size: 56),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.sprite, required this.label, required this.value});

  final PixelSprite sprite;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          PixelArt(sprite, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: PixelText(label, size: 10, color: AppColors.muted),
          ),
          PixelText(value, size: 10),
        ],
      ),
    );
  }
}

/// ARPG drop feed: the latest generated items, named and color-coded by
/// rarity with their archetype identity (mirrors RecentLoot from the API).
class _LootFeed extends StatelessWidget {
  const _LootFeed();

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PixelText('LATEST LOOT', size: 11, color: AppColors.muted),
          const SizedBox(height: 10),
          for (final drop in mockLootFeed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  PixelArt(SpriteLibrary.forSlot(drop.slot), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PixelText(
                          drop.name.toUpperCase(),
                          size: 9,
                          color: RarityColors.forRarity(drop.rarityTier),
                          maxLines: 1,
                        ),
                        PixelText(
                          '${drop.rarity.toUpperCase()} · ${drop.archetype.toUpperCase()}',
                          size: 7,
                          color: AppColors.muted,
                          shadow: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SetBonusPanel extends StatelessWidget {
  const _SetBonusPanel();

  @override
  Widget build(BuildContext context) {
    return const PixelPanel(
      border: RarityColors.superior,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelArt(Sprites.chestplate, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: PixelText('IRONCLAD SET — 4/4',
                    size: 12, color: RarityColors.superior),
              ),
            ],
          ),
          SizedBox(height: 8),
          PixelProgressBar(
            filled: 4,
            total: 4,
            color: RarityColors.superior,
            height: 10,
          ),
          SizedBox(height: 8),
          PixelText(
            '2-PIECE: DEFENSE BOOST\n4-PIECE: UNBREAKABLE — IMMUNE TO ONE-SHOT DEFEATS',
            size: 9,
            color: AppColors.muted,
            shadow: false,
          ),
        ],
      ),
    );
  }
}
