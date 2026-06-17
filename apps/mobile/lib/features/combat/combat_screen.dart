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

// Fixed reel cell height (sized for the max buff list, never dynamic).
const double _cellHeight = 156;

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

Color _stepColor(String kind) => switch (kind) {
      'combo' => const Color(0xFFA78BFA),
      'crit' => const Color(0xFFFFD700),
      'info' => const Color(0xFF8FB3D9),
      _ => const Color(0xFFCFE3F5),
    };

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
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _poll());
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
            Expanded(child: _Stage(snap: snap)),
            _Reel(snap: snap),
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

/// Allies front-left, enemy wave back-right (a step higher, on the ground line).
class _Stage extends StatelessWidget {
  const _Stage({required this.snap});

  final ServerSnapshot snap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final w = c.maxWidth;
        final heroH = min(h * 0.30, w * 0.15);
        final bossH = min(h * 0.50, w * 0.32);
        final dmg = snap.reel.damage;

        return Stack(
          fit: StackFit.expand,
          children: [
            StageBackground(theme: _theme(snap.theme)),

            // Enemy wave: right side, a little above the allies' baseline.
            Align(
              alignment: const Alignment(0.96, 0.66),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final enemy in snap.enemies)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedOpacity(
                        opacity: enemy.alive ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: _Unit(
                          key: ValueKey(enemy.id),
                          art: Sprites.enemy(_enemy(enemy.kind)),
                          height: enemy.isBoss ? bossH : heroH * 0.92,
                          flipX: true,
                          hpFraction: enemy.hpFraction,
                          alive: enemy.alive,
                          level: null,
                          acting: false,
                          trigger: enemy.hit ? snap.tick : 0,
                          overlay: null,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Allies: front-left, on the ground.
            Align(
              alignment: const Alignment(-0.96, 0.98),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final hero in snap.heroes)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Unit(
                        key: ValueKey(hero.id),
                        art: ItemSprites.roster(_roster(hero.archetype)),
                        height: heroH,
                        flipX: false,
                        hpFraction: hero.hpFraction,
                        alive: hero.alive,
                        level: hero.level,
                        acting: hero.acting,
                        trigger: hero.acting ? snap.tick : 0,
                        overlay: (hero.acting && dmg != null)
                            ? _DamagePopup(key: ValueKey(snap.tick), dmg: dmg)
                            : null,
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
    required this.acting,
    required this.trigger,
    required this.overlay,
  });

  final PixelArt art;
  final double height;
  final bool flipX;
  final double hpFraction;
  final bool alive;
  final int? level;
  final bool acting;
  final int trigger;
  final Widget? overlay;

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
    final unit = AnimatedBuilder(
      animation: Listenable.merge([_bob, _flash]),
      builder: (context, _) {
        final bobY = widget.alive ? sin(_bob.value * pi) * 2.0 : 0.0;
        final shakeX = sin(_flash.value * pi * 3) * 4.0 * (1 - _flash.value);
        final flash = (1 - _flash.value) * 0.9;
        final lift = widget.acting ? 5.0 : 0.0;

        return Transform.translate(
          offset: Offset(shakeX, -bobY - lift),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.level != null) _LvBadge(level: widget.level!, acting: widget.acting),
              if (widget.level != null) const SizedBox(height: 2),
              _HpBar(fraction: widget.hpFraction, alive: widget.alive),
              const SizedBox(height: 3),
              Container(
                decoration: widget.acting
                    ? const BoxDecoration(
                        boxShadow: [BoxShadow(color: Color(0xAA34D399), blurRadius: 16, spreadRadius: 1)],
                      )
                    : null,
                child: Opacity(
                  opacity: widget.alive ? 1 : 0.22,
                  child: PixelSprite(
                    art: widget.art,
                    height: widget.height,
                    flipX: widget.flipX,
                    flash: widget.alive ? flash : 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.overlay == null) return unit;

    // Float the overlay above the unit's head without affecting layout.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        unit,
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(offset: const Offset(0, -52), child: widget.overlay),
            ),
          ),
        ),
      ],
    );
  }
}

class _LvBadge extends StatelessWidget {
  const _LvBadge({required this.level, required this.acting});

  final int level;
  final bool acting;

  @override
  Widget build(BuildContext context) {
    final c = acting ? const Color(0xFF34D399) : const Color(0xFF24334C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        border: Border.all(color: c, width: 1),
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
      width: 38,
      height: 6,
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

/// Above the acting hero's head: ONLY the running total (counts up 1-by-1),
/// with the just-applied contributions fading out as a small stack above it.
class _DamagePopup extends StatefulWidget {
  const _DamagePopup({super.key, required this.dmg});

  final ServerDamage dmg;

  @override
  State<_DamagePopup> createState() => _DamagePopupState();
}

class _DamagePopupState extends State<_DamagePopup> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // +0.5s slower overall, ~0.65s per applied step.
    final ms = 600 + widget.dmg.steps.length * 650;
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: ms))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.dmg.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final segs = steps.length;
        final pos = (_ctrl.value * (segs - 1)).clamp(0.0, (segs - 1).toDouble());
        final i = pos.floor().clamp(0, segs - 1);
        final frac = (pos - i).clamp(0.0, 1.0);
        final to = steps[min(i + 1, segs - 1)].total;
        final shown = (steps[i].total + (to - steps[i].total) * frac).round();

        final atCrit = steps[i].kind == 'crit' || (i + 1 < segs && steps[i + 1].kind == 'crit' && frac > 0.4);
        final finalCrit = widget.dmg.crit && _ctrl.value > 0.92;
        final numColor = (atCrit || finalCrit) ? const Color(0xFFFFD700) : const Color(0xFFF1F5F9);

        // The contributions applied so far, newest first, fading with age.
        final appliedUpTo = (i + (frac > 0.5 ? 1 : 0)).clamp(0, segs - 1);
        final chips = <Widget>[];
        for (var k = appliedUpTo; k >= 1 && chips.length < 3; k--) {
          final age = chips.length;
          chips.add(Opacity(
            opacity: [1.0, 0.5, 0.25][age],
            child: Text(steps[k].label,
                style: _retro(7.5, color: _stepColor(steps[k].kind), w: FontWeight.w900),
                maxLines: 1),
          ));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...chips,
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xE60A0F18),
                border: Border.all(color: numColor, width: 2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: numColor.withValues(alpha: 0.55), blurRadius: finalCrit ? 16 : 7)],
              ),
              child: Text('$shown',
                  style: _retro(finalCrit ? 20 : 16, color: numColor, w: FontWeight.w900)),
            ),
            if (finalCrit)
              Text('CRIT!!', style: _retro(11, color: const Color(0xFFFFD700), w: FontWeight.w900)),
          ],
        );
      },
    );
  }
}

/// Fixed-size 1x3 reel. Items roll in, dissolve into their full buff list, and a
/// scan light sweeps each sub-attribute.
class _Reel extends StatefulWidget {
  const _Reel({required this.snap});

  final ServerSnapshot snap;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with TickerProviderStateMixin {
  late final AnimationController _roll;
  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _roll = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  }

  @override
  void didUpdateWidget(_Reel old) {
    super.didUpdateWidget(old);
    if (widget.snap.tick != old.snap.tick) {
      _roll.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.snap.reel;
    final items = reel.items;
    final dmg = reel.damage;
    final isPrize = reel.combo != 'MIXED' && items.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
      decoration: const BoxDecoration(
        color: Color(0xFF0A111E),
        border: Border(top: BorderSide(color: Color(0xFF1F2D44), width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dmg != null ? 'TURN  ${dmg.heroName.toUpperCase()}' : 'SLOT REEL',
                  style: _retro(9, color: const Color(0xFF6EE7B7))),
              Text(isPrize ? '${reel.combo}  x${reel.multiplier.toStringAsFixed(0)}' : 'ROLLING',
                  style: _retro(10,
                      color: isPrize ? _rarityColor(reel.maxRarityTier) : const Color(0xFF5E7392),
                      w: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _cellHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([_roll, _scan]),
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: _Cell(
                        item: i < items.length ? items[i] : null,
                        roll: _roll.value,
                        scan: _scan.value,
                        index: i,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.roll, required this.scan, required this.index});

  final ServerReelItem? item;
  final double roll;
  final double scan;
  final int index;

  static const _appearStagger = 0.16;
  static const _appearDur = 0.18;
  static const _textStart = 0.55;
  static const _textEnd = 0.74;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final color = it == null ? const Color(0xFF1F2D44) : _rarityColor(it.rarityTier);

    final ci = ((roll - index * _appearStagger) / _appearDur).clamp(0.0, 1.0);
    final textT = ((roll - _textStart) / (_textEnd - _textStart)).clamp(0.0, 1.0);
    final iconOpacity = ci * (1 - textT);
    final iconScale = 0.55 + 0.45 * ci;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: ci > 0.9 ? color : const Color(0xFF1F2D44), width: ci > 0.9 ? 2 : 1),
        boxShadow: ci > 0.9 ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6)] : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: it == null
          ? const SizedBox.shrink()
          : Stack(
              children: [
                // Benefit list (fills the fixed cell).
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Opacity(opacity: textT, child: _Benefit(item: it, color: color)),
                ),
                // Scan light sweeping the sub-attributes.
                if (textT > 0.6)
                  Positioned(
                    top: scan * (_cellHeight - 14),
                    left: 0,
                    right: 0,
                    height: 14,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.0),
                              color.withValues(alpha: 0.35),
                              color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Icon rolls in over the benefit area.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: iconOpacity,
                      child: Center(
                        child: Transform.scale(
                          scale: iconScale,
                          child: PixelSprite(
                            art: ItemSprites.shape(_shape(it.shape)),
                            height: 36,
                            recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
                          ),
                        ),
                      ),
                    ),
                  ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.rarity.toUpperCase(), style: _retro(7, color: color, w: FontWeight.w900), maxLines: 1),
        const SizedBox(height: 1),
        Text(item.primary.toUpperCase(),
            style: _retro(8.5, color: const Color(0xFFF1F5F9), w: FontWeight.w900), maxLines: 2),
        const SizedBox(height: 2),
        for (final b in item.passives)
          Text(b, style: _retro(6.5, color: const Color(0xFF9FB3CC)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
