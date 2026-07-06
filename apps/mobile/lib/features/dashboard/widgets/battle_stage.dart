import 'package:flutter/material.dart';

import '../../../core/pixel/pixel_hp_bar.dart';
import '../../../core/pixel/pixel_sprite.dart';
import '../../../core/pixel/pixel_widgets.dart';
import '../../../core/pixel/sprites.dart';
import '../../../core/theme/app_theme.dart';

/// The whole party fighting on one stage, JRPG style.
///
/// An 8-phase, hand-choreographed turn loop makes it obvious WHO does WHAT:
/// the gold cursor marks the actor, the banner names the action
/// ("EMBER > SKILL"), the actor steps toward its target in discrete pixels
/// and the victim reacts (slash frames / squash / HP dip). Health bars for
/// every combatant stay on screen at all times — fractions only, never
/// numbers. Skill-point pips track the shared HSR pool.
class BattleStage extends StatefulWidget {
  const BattleStage({super.key, required this.bossFight});

  final bool bossFight;

  @override
  State<BattleStage> createState() => _BattleStageState();
}

class _Phase {
  const _Phase({
    required this.banner,
    this.actor,
    this.enemyActs = false,
    this.strikesEnemy = false,
    this.victimHero,
    required this.heroHp,
    required this.enemyHp,
    required this.sp,
  });

  final String banner;
  final int? actor; // hero index acting this phase
  final bool enemyActs;
  final bool strikesEnemy; // slash lands on the enemy this phase
  final int? victimHero; // hero hit when the enemy acts
  final List<double> heroHp; // 4 fractions, shown constantly
  final double enemyHp;
  final int sp; // shared skill points (0..5)
}

class _BattleStageState extends State<BattleStage>
    with SingleTickerProviderStateMixin {
  // 8 phases x 800ms = 6.4s loop.
  static const _phases = [
    _Phase(
      banner: 'ENEMY APPROACHES',
      heroHp: [0.85, 0.62, 0.95, 0.72],
      enemyHp: 1.0,
      sp: 3,
    ),
    _Phase(
      banner: 'VANGUARD > BASIC',
      actor: 0,
      strikesEnemy: true,
      heroHp: [0.85, 0.62, 0.95, 0.72],
      enemyHp: 0.88,
      sp: 4,
    ),
    _Phase(
      banner: 'EMBER > SKILL',
      actor: 1,
      strikesEnemy: true,
      heroHp: [0.85, 0.62, 0.95, 0.72],
      enemyHp: 0.66,
      sp: 3,
    ),
    _Phase(
      banner: 'ENEMY > ATTACK',
      enemyActs: true,
      victimHero: 0,
      heroHp: [0.58, 0.62, 0.95, 0.72],
      enemyHp: 0.66,
      sp: 3,
    ),
    _Phase(
      banner: 'LUMEN > HEAL',
      actor: 2,
      heroHp: [0.85, 0.62, 0.95, 0.72],
      enemyHp: 0.66,
      sp: 2,
    ),
    _Phase(
      banner: 'FROST > ULTIMATE!',
      actor: 3,
      strikesEnemy: true,
      heroHp: [0.85, 0.62, 0.95, 0.72],
      enemyHp: 0.28,
      sp: 2,
    ),
    _Phase(
      banner: 'ENEMY > ATTACK',
      enemyActs: true,
      victimHero: 1,
      heroHp: [0.85, 0.44, 0.95, 0.72],
      enemyHp: 0.28,
      sp: 2,
    ),
    _Phase(
      banner: 'VANGUARD > BASIC',
      actor: 0,
      strikesEnemy: true,
      heroHp: [0.85, 0.44, 0.95, 0.72],
      enemyHp: 0.08,
      sp: 3,
    ),
  ];

  static const _heroes = [
    (frames: Sprites.warriorFrames, name: 'VANGUARD'),
    (frames: Sprites.berserkerFrames, name: 'EMBER'),
    (frames: Sprites.clericFrames, name: 'LUMEN'),
    (frames: Sprites.mageFrames, name: 'FROST'),
  ];

  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6400),
  )..repeat();

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enemyFrames =
        widget.bossFight ? Sprites.bossFrames : Sprites.slimeFrames;

    return AnimatedBuilder(
      animation: _cycle,
      builder: (context, _) {
        final t = _cycle.value * _phases.length;
        final phaseIndex = t.floor() % _phases.length;
        final phaseT = t - t.floor(); // 0..1 inside the phase
        final phase = _phases[phaseIndex];
        final idleFrame = (t * 2).floor() % 2;

        // Strike lands mid-phase; recoil follows right after.
        final striking = phase.strikesEnemy && phaseT >= 0.35 && phaseT < 0.75;
        final slashFrame =
            striking ? (((phaseT - 0.35) / 0.40) * 3).floor().clamp(0, 2) : -1;
        final enemyRecoil = phase.strikesEnemy && phaseT >= 0.45 && phaseT < 0.85;
        final enemyLunge = phase.enemyActs && phaseT >= 0.30 && phaseT < 0.70;
        final victimFlash =
            phase.enemyActs && phaseT >= 0.45 && phaseT < 0.75 ? phase.victimHero : null;

        return Column(
          children: [
            // Action banner + shared skill-point pips.
            Row(
              children: [
                Expanded(
                  child: PixelText(phase.banner, size: 10, color: AppColors.accent),
                ),
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i < phase.sp ? AppColors.accent : AppColors.surface,
                        border: Border.all(color: const Color(0xFF0B1220), width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // The full party, in formation, HP always visible.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, hero) in _heroes.indexed)
                      Padding(
                        padding: EdgeInsets.only(bottom: i < 3 ? 6 : 0),
                        child: Transform.translate(
                          offset: Offset(phase.actor == i ? 10 : 0, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                child: phase.actor == i
                                    ? const PixelArt(Sprites.turnCursor, size: 10)
                                    : null,
                              ),
                              Opacity(
                                opacity: victimFlash == i ? 0.4 : 1.0,
                                child: PixelArt(hero.frames[idleFrame], size: 36),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PixelText(hero.name, size: 7,
                                      color: AppColors.muted, shadow: false),
                                  const SizedBox(height: 2),
                                  PixelHpBar(fraction: phase.heroHp[i]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // The enemy, with its own always-on HP bar and turn cursor.
                Transform.translate(
                  offset: Offset(
                    enemyLunge ? -10.0 : (enemyRecoil ? 6.0 : 0.0),
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 10,
                        child: phase.enemyActs && phaseT < 0.30
                            ? const PixelArt(Sprites.turnCursor, size: 10)
                            : null,
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          PixelArt(
                            enemyRecoil ? enemyFrames[1] : enemyFrames[idleFrame],
                            size: 70,
                            flipX: true,
                          ),
                          if (slashFrame >= 0)
                            PixelArt(Sprites.slashFrames[slashFrame], size: 70),
                        ],
                      ),
                      const SizedBox(height: 4),
                      PixelHpBar(fraction: phase.enemyHp, width: 64, height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        );
      },
    );
  }
}
