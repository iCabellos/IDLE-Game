import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game/game.dart' show EnemyKind, BgTheme;
import '../../core/game/server_game.dart';
import '../../core/inventory/inventory_model.dart' show RosterId, ItemShape;
import '../../core/pixel/backgrounds.dart';
import '../../core/pixel/item_sprites.dart';
import '../../core/pixel/pixel_art.dart';
import '../../core/pixel/sprites.dart';

const _pixelFont = 'monospace';

TextStyle _retro(double size,
        {Color color = const Color(0xFFF1F5F9), FontWeight w = FontWeight.w700}) =>
    TextStyle(
      fontFamily: _pixelFont,
      fontSize: size,
      color: color,
      fontWeight: w,
      letterSpacing: 1.3,
      height: 1.1,
    );

// server enum strings -> client sprites/themes
RosterId _roster(String a) => switch (a) {
      'defense' => RosterId.knight,
      'magic' => RosterId.mage,
      'physical' => RosterId.ranger,
      'support' => RosterId.cleric,
      'critDamage' => RosterId.rogue,
      'fury' => RosterId.berserker,
      _ => RosterId.ranger,
    };

EnemyKind _enemy(String k) => switch (k) {
      'slime' => EnemyKind.slime,
      'bat' => EnemyKind.bat,
      'goblin' => EnemyKind.goblin,
      'skeleton' => EnemyKind.skeleton,
      'orc' => EnemyKind.orc,
      'demon' => EnemyKind.demon,
      _ => EnemyKind.slime,
    };

BgTheme _theme(String t) => switch (t) {
      'meadow' => BgTheme.meadow,
      'crypt' => BgTheme.crypt,
      'forest' => BgTheme.forest,
      'cavern' => BgTheme.cavern,
      'volcano' => BgTheme.volcano,
      'citadel' => BgTheme.citadel,
      _ => BgTheme.meadow,
    };

ItemShape _reelShape(String kind) => switch (kind) {
      'mainWeapon' => ItemShape.sword,
      'secondaryWeapon' => ItemShape.shield,
      'amulet' => ItemShape.amulet,
      'earring1' || 'earring2' => ItemShape.ring,
      'ring1' || 'ring2' => ItemShape.ring,
      _ => ItemShape.relic,
    };

Color _comboColor(String c) => switch (c) {
      'JACKPOT' => const Color(0xFFFFD700),
      'SYNERGY' => const Color(0xFFA78BFA),
      'PAIR' => const Color(0xFF60A5FA),
      _ => const Color(0xFF5E7392),
    };

/// Landing screen: a dumb painter of the server-authoritative idle battle.
/// All combat logic, RNG, progression and persistence are server-side; this
/// screen only polls `/game/state` and renders it.
class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  final _api = GameApi();
  Timer? _timer;
  ServerSnapshot? _snap;
  bool _online = false;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final s = await _api.fetchState();
      if (!mounted) return;
      setState(() {
        _snap = s;
        _online = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _online = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1626), Color(0xFF080B12)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _snap == null
                ? const _Connecting()
                : _ArenaCard(snap: _snap!, online: _online),
          ),
        ),
      ),
    );
  }
}

class _Connecting extends StatelessWidget {
  const _Connecting();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('CONNECTING TO SERVER',
          style: _retro(12, color: const Color(0xFF8FB3D9))),
    );
  }
}

class _ArenaCard extends StatelessWidget {
  const _ArenaCard({required this.snap, required this.online});

  final ServerSnapshot snap;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1320),
        border: Border.all(color: const Color(0xFF1F2D44), width: 3),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: [
            _Banner(snap: snap, online: online),
            Expanded(flex: 62, child: _Stage(snap: snap)),
            Expanded(flex: 38, child: _Reel(snap: snap)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.snap, required this.online});

  final ServerSnapshot snap;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF111B2C),
        border: Border(bottom: BorderSide(color: Color(0xFF1F2D44), width: 2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('LEVEL ${snap.levelIndex + 1} / 10',
                      style: _retro(9, color: const Color(0xFF5E7392))),
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? const Color(0xFF34D399) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(online ? 'SERVER · LIVE' : 'RECONNECTING',
                      style: _retro(8, color: const Color(0xFF5E7392))),
                ],
              ),
              const SizedBox(height: 3),
              Text(snap.levelName.toUpperCase(), style: _retro(13)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pips(count: snap.phaseCount, filled: snap.phaseIndex, label: 'PHASE', color: const Color(0xFF0EA5E9)),
              const SizedBox(height: 5),
              _Pips(count: snap.wavesPerPhase, filled: snap.waveIndex, label: 'WAVE', color: const Color(0xFFE3B341)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.count, required this.filled, required this.label, required this.color});

  final int count;
  final int filled;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: _retro(8, color: const Color(0xFF5E7392))),
        const SizedBox(width: 6),
        for (var i = 0; i < count; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: i <= filled ? color : const Color(0xFF24334C),
              border: Border.all(color: const Color(0xFF0A0F18), width: 1),
            ),
          ),
      ],
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.snap});

  final ServerSnapshot snap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final w = c.maxWidth;
        final heroH = min(h * 0.32, w * 0.13);
        final bossH = min(h * 0.55, w * 0.34);

        return Stack(
          fit: StackFit.expand,
          children: [
            StageBackground(theme: _theme(snap.theme)),
            Positioned(
              left: 10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final hero in snap.heroes)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Unit(
                        key: ValueKey(hero.id),
                        art: ItemSprites.roster(_roster(hero.archetype)),
                        height: heroH,
                        flipX: false,
                        hpFraction: hero.hpFraction,
                        alive: hero.alive,
                        level: hero.level,
                        accent: const Color(0xFF34D399),
                        trigger: hero.acting ? snap.tick : 0,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final enemy in snap.enemies)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: AnimatedOpacity(
                        opacity: enemy.alive ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: _Unit(
                          key: ValueKey(enemy.id),
                          art: Sprites.enemy(_enemy(enemy.kind)),
                          height: enemy.isBoss ? bossH : heroH,
                          flipX: true,
                          hpFraction: enemy.hpFraction,
                          alive: enemy.alive,
                          level: null,
                          accent: enemy.isBoss ? const Color(0xFFEF6B6B) : const Color(0xFFE3B341),
                          trigger: enemy.hit ? snap.tick : 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Unit extends StatefulWidget {
  const _Unit({
    super.key,
    required this.art,
    required this.height,
    required this.flipX,
    required this.hpFraction,
    required this.alive,
    required this.level,
    required this.accent,
    required this.trigger,
  });

  final PixelArt art;
  final double height;
  final bool flipX;
  final double hpFraction;
  final bool alive;
  final int? level;
  final Color accent;
  final int trigger;

  @override
  State<_Unit> createState() => _UnitState();
}

class _UnitState extends State<_Unit> with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _flash;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  }

  @override
  void didUpdateWidget(_Unit old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger != 0) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _flash]),
      builder: (context, _) {
        final bobY = widget.alive ? sin(_bob.value * pi) * 2.0 : 0.0;
        final shakeX = sin(_flash.value * pi * 3) * 4.0 * (1 - _flash.value);
        final flash = (1 - _flash.value) * 0.9;

        return Transform.translate(
          offset: Offset(shakeX, -bobY),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.level != null) _LvBadge(level: widget.level!),
              if (widget.level != null) const SizedBox(height: 2),
              _HpBar(fraction: widget.hpFraction, alive: widget.alive),
              const SizedBox(height: 3),
              Opacity(
                opacity: widget.alive ? 1 : 0.22,
                child: PixelSprite(
                  art: widget.art,
                  height: widget.height,
                  flipX: widget.flipX,
                  flash: widget.alive ? flash : 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LvBadge extends StatelessWidget {
  const _LvBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        border: Border.all(color: const Color(0xFF34D399), width: 1),
      ),
      child: Text('LV $level', style: _retro(8, color: const Color(0xFF6EE7B7))),
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({required this.fraction, required this.alive});

  final double fraction;
  final bool alive;

  @override
  Widget build(BuildContext context) {
    final f = alive ? fraction.clamp(0.0, 1.0) : 0.0;
    final color = !alive
        ? const Color(0xFF4B5563)
        : f > 0.5
            ? const Color(0xFF34D399)
            : f > 0.25
                ? const Color(0xFFE3B341)
                : const Color(0xFFEF4444);
    return Container(
      width: 40,
      height: 7,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F18),
        border: Border.all(color: const Color(0xFF1F2D44), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f <= 0 ? 0.001 : f,
          child: Container(color: color),
        ),
      ),
    );
  }
}

/// The 1x3 slot reel, server-driven. Shows the three equipped items the server
/// rolled this turn, the combo, and the multiplier.
class _Reel extends StatelessWidget {
  const _Reel({required this.snap});

  final ServerSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final reel = snap.reel;
    final color = _comboColor(reel.combo);
    final items = reel.items;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0A111E),
        border: Border(top: BorderSide(color: Color(0xFF1F2D44), width: 2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SLOT REEL', style: _retro(9, color: const Color(0xFF5E7392))),
              Text(
                reel.combo == 'MIXED'
                    ? 'x1'
                    : '${reel.combo}  x${reel.multiplier.toStringAsFixed(0)}',
                style: _retro(12, color: color, w: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: _ReelCell(
                      kind: i < items.length ? items[i] : null,
                      color: color,
                      lit: reel.combo != 'MIXED' && i < items.length,
                      tick: snap.tick,
                      index: i,
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

class _ReelCell extends StatelessWidget {
  const _ReelCell({
    required this.kind,
    required this.color,
    required this.lit,
    required this.tick,
    required this.index,
  });

  final String? kind;
  final Color color;
  final bool lit;
  final int tick;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(
          color: lit ? color : const Color(0xFF1F2D44),
          width: lit ? 2 : 1,
        ),
        boxShadow: lit ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)] : null,
      ),
      child: Center(
        child: kind == null
            ? const SizedBox.shrink()
            : LayoutBuilder(
                builder: (context, c) {
                  final side = min(c.maxWidth, c.maxHeight);
                  return PixelSprite(
                    art: ItemSprites.shape(_reelShape(kind!)),
                    height: side * 0.74,
                    recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
                  );
                },
              ),
      ),
    );
  }
}
