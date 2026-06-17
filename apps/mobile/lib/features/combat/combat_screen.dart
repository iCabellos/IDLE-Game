import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game/game.dart' show EnemyKind, BgTheme;
import '../../core/game/server_game.dart';
import '../../core/inventory/inventory_model.dart' show RosterId, ItemShape, Rarity, RarityX;
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
      letterSpacing: 1.0,
      height: 1.15,
    );

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

ItemShape _shape(String s) => switch (s) {
      'sword' => ItemShape.sword,
      'shield' => ItemShape.shield,
      'staff' => ItemShape.staff,
      'bow' => ItemShape.bow,
      'amulet' => ItemShape.amulet,
      'earring' => ItemShape.ring,
      'ring' => ItemShape.ring,
      'relic' => ItemShape.relic,
      _ => ItemShape.sword,
    };

Color _rarityColor(int tier) =>
    Rarity.values[(tier - 1).clamp(0, Rarity.values.length - 1)].color;

/// Landing screen: a dumb painter of the server-authoritative idle battle.
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
            Expanded(flex: 58, child: _Stage(snap: snap)),
            Expanded(flex: 42, child: _Reel(snap: snap)),
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
        final heroH = min(h * 0.34, w * 0.13);
        final bossH = min(h * 0.58, w * 0.34);

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
    required this.trigger,
  });

  final PixelArt art;
  final double height;
  final bool flipX;
  final double hpFraction;
  final bool alive;
  final int? level;
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

/// The 1x3 slot reel. Each spin: items roll in one by one, then dissolve into
/// their resolved benefit (primary stat + rarity buff list); on a combo, the
/// multiplier total bursts in, flashier the higher the rarity.
class _Reel extends StatefulWidget {
  const _Reel({required this.snap});

  final ServerSnapshot snap;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
      ..forward();
  }

  @override
  void didUpdateWidget(_Reel old) {
    super.didUpdateWidget(old);
    if (widget.snap.tick != old.snap.tick) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.snap.reel;
    final items = reel.items;
    final isPrize = reel.combo != 'MIXED' && items.isNotEmpty;
    final prizeColor = _rarityColor(reel.maxRarityTier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0A111E),
        border: Border(top: BorderSide(color: Color(0xFF1F2D44), width: 2)),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final v = _ctrl.value;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SLOT REEL', style: _retro(9, color: const Color(0xFF5E7392))),
                  Text(
                    isPrize ? reel.combo : 'ROLLING',
                    style: _retro(11, color: isPrize ? prizeColor : const Color(0xFF5E7392), w: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: _Cell(
                              item: i < items.length ? items[i] : null,
                              v: v,
                              index: i,
                            ),
                          ),
                      ],
                    ),
                    if (isPrize) _PrizeBurst(combo: reel.combo, multiplier: reel.multiplier, color: prizeColor, v: v),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.v, required this.index});

  final ServerReelItem? item;
  final double v;
  final int index;

  static const _appearStagger = 0.13;
  static const _appearDur = 0.16;
  static const _textStart = 0.50;
  static const _textEnd = 0.66;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final color = it == null ? const Color(0xFF1F2D44) : _rarityColor(it.rarityTier);

    final ci = ((v - index * _appearStagger) / _appearDur).clamp(0.0, 1.0);
    final textT = ((v - _textStart) / (_textEnd - _textStart)).clamp(0.0, 1.0);
    final iconOpacity = ci * (1 - textT);
    final iconScale = 0.55 + 0.45 * ci;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: ci > 0.9 ? color : const Color(0xFF1F2D44), width: ci > 0.9 ? 2 : 1),
        boxShadow: ci > 0.9 ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 9)] : null,
      ),
      child: it == null
          ? const SizedBox.shrink()
          : Stack(
              fit: StackFit.expand,
              children: [
                // Phase 1: the item icon rolls in.
                Opacity(
                  opacity: iconOpacity,
                  child: Center(
                    child: Transform.scale(
                      scale: iconScale,
                      child: LayoutBuilder(
                        builder: (context, c) => PixelSprite(
                          art: ItemSprites.shape(_shape(it.shape)),
                          height: min(c.maxWidth, c.maxHeight) * 0.62,
                          recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
                        ),
                      ),
                    ),
                  ),
                ),
                // Phase 2: it dissolves into its benefit.
                Opacity(
                  opacity: textT,
                  child: _Benefit(item: it, color: color),
                ),
              ],
            ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.item, required this.color});

  final ServerReelItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const maxBuffs = 5;
    final buffs = item.passives.take(maxBuffs).toList();
    final extra = item.passives.length - buffs.length;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.rarity.toUpperCase(), style: _retro(7, color: color, w: FontWeight.w900), maxLines: 1),
          const SizedBox(height: 2),
          Text(item.primary.toUpperCase(),
              style: _retro(8.5, color: const Color(0xFFF1F5F9), w: FontWeight.w900), maxLines: 2),
          const SizedBox(height: 3),
          for (final b in buffs)
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(b, style: _retro(6.5, color: const Color(0xFF9FB3CC)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          if (extra > 0)
            Text('+$extra more', style: _retro(6.5, color: color), maxLines: 1),
        ],
      ),
    );
  }
}

class _PrizeBurst extends StatelessWidget {
  const _PrizeBurst({required this.combo, required this.multiplier, required this.color, required this.v});

  final String combo;
  final double multiplier;
  final Color color;
  final double v;

  @override
  Widget build(BuildContext context) {
    const start = 0.66;
    final t = ((v - start) / (1 - start)).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    // Overshoot pop, then settle.
    final scale = 0.5 + 1.1 * (t < 0.6 ? t / 0.6 : 1 - (t - 0.6) / 0.4 * 0.18);
    final glow = combo == 'JACKPOT' ? 26.0 : 16.0;

    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: (t * 1.4).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCC0A0F18),
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: glow)],
              ),
              child: Text(
                '${combo == 'JACKPOT' ? 'JACKPOT  ' : ''}x${multiplier.toStringAsFixed(0)}',
                style: _retro(combo == 'JACKPOT' ? 20 : 16, color: color, w: FontWeight.w900).copyWith(
                  shadows: const [Shadow(color: Colors.black, offset: Offset(1.5, 1.5))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
