import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/character_status.dart';
import '../../core/models/loot_drop_view.dart';
import '../../core/pixel/pixel_anim.dart';
import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';
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
                const _PartyRow().animate().fadeIn(duration: 400.ms),
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

class _PartyRow extends StatelessWidget {
  const _PartyRow();

  static const _party = [
    (frames: Sprites.warriorFrames, name: 'VANGUARD', role: 'TANK'),
    (frames: Sprites.berserkerFrames, name: 'EMBER', role: 'DPS'),
    (frames: Sprites.clericFrames, name: 'LUMEN', role: 'HEALER'),
    (frames: Sprites.mageFrames, name: 'FROST', role: 'DPS'),
  ];

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PixelText('YOUR PARTY', size: 11, color: AppColors.muted),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, member) in _party.indexed)
                Expanded(
                  child: Column(
                    children: [
                      // Two hand-drawn poses stepped slowly, staggered so
                      // the line breathes without moving in lockstep.
                      AnimatedPixelArt(
                        member.frames,
                        size: 56,
                        stepMs: 600,
                        startFrame: i % 2,
                      ),
                      const SizedBox(height: 6),
                      PixelText(member.name, size: 9, maxLines: 1),
                      PixelText(member.role, size: 8, color: AppColors.muted),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tiny animated battle scene: the vanguard trading blows with the
/// current wave. Pure flavor — outcomes come from the readable status.
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
          _BattleLoop(bossFight: danger || stuck),
        ],
      ),
    );
  }
}

/// Hand-choreographed strike loop on a 2s cycle of discrete steps:
/// idle breathing -> the vanguard steps in -> a three-frame slash lands ->
/// the enemy is knocked back a few pixels -> everyone resets. No easing,
/// no continuous motion; every pose is a drawn frame.
class _BattleLoop extends StatefulWidget {
  const _BattleLoop({required this.bossFight});

  final bool bossFight;

  @override
  State<_BattleLoop> createState() => _BattleLoopState();
}

class _BattleLoopState extends State<_BattleLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enemyFrames = widget.bossFight ? Sprites.bossFrames : Sprites.slimeFrames;

    return AnimatedBuilder(
      animation: _cycle,
      builder: (context, _) {
        final t = _cycle.value;

        // Discrete choreography windows (fractions of the 2s cycle).
        final lunging = t >= 0.50 && t < 0.66;
        final striking = t >= 0.55 && t < 0.70;
        final recoiling = t >= 0.58 && t < 0.74;

        final slashFrame = striking
            ? (((t - 0.55) / 0.15) * 3).floor().clamp(0, 2)
            : -1;
        final idleFrame = (t * 4).floor() % 2;

        return SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Transform.translate(
                offset: Offset(lunging ? 8 : 0, 0),
                child: PixelArt(
                  lunging ? Sprites.warrior : Sprites.warriorFrames[idleFrame],
                  size: 64,
                ),
              ),
              const PixelText('VS', size: 14, color: AppColors.danger),
              Transform.translate(
                offset: Offset(recoiling ? 5 : 0, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PixelArt(
                      recoiling
                          ? enemyFrames[1]
                          : enemyFrames[idleFrame % enemyFrames.length],
                      size: 64,
                      flipX: true,
                    ),
                    if (slashFrame >= 0)
                      PixelArt(Sprites.slashFrames[slashFrame], size: 64),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
