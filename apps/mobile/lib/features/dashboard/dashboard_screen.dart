import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/character_status.dart';
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
    (sprite: Sprites.warrior, name: 'VANGUARD', role: 'TANK'),
    (sprite: Sprites.berserker, name: 'EMBER', role: 'DPS'),
    (sprite: Sprites.cleric, name: 'LUMEN', role: 'HEALER'),
    (sprite: Sprites.mage, name: 'FROST', role: 'DPS'),
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
                      PixelArt(member.sprite, size: 56)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                            begin: 0,
                            end: -3,
                            delay: (i * 200).ms,
                            duration: 800.ms,
                            curve: Curves.easeInOut,
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
    final enemy = danger || stuck ? Sprites.boss : Sprites.slime;

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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const PixelArt(Sprites.warrior, size: 64)
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(begin: 0, end: 10, duration: 500.ms, curve: Curves.easeIn)
                  .then()
                  .moveX(begin: 10, end: 0, duration: 300.ms)
                  .then(delay: 600.ms),
              const PixelText('VS', size: 14, color: AppColors.danger),
              PixelArt(enemy, size: 64, flipX: true)
                  .animate(onPlay: (c) => c.repeat())
                  .shake(hz: 3, offset: const Offset(2, 0), duration: 400.ms)
                  .then(delay: 1000.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdventureLog extends StatelessWidget {
  const _AdventureLog({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    final ready = status == CharacterStatus.rewardsReady;

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
          PixelButton(
            label: ready ? 'Claim rewards' : 'No rewards yet',
            color: AppColors.success,
            onPressed: ready ? () {} : null,
            icon: const PixelArt(Sprites.chest, size: 22),
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
