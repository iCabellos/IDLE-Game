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
const double _cellHeight = 168;
const int _turnMs = 2400;

// Animation timeline (fractions of the turn), tuned to feel compensated.
const double _settleBase = 0.26; // first reel cell settles here
const double _settleStep = 0.13; // stagger between cells
const double _countStart = 0.42; // total starts counting here
const double _countEnd = 0.96;
const double _projStart = 0.70;
const double _projEnd = 0.92;

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

double _ease(Curve c, double x) => c.transform(x.clamp(0.0, 1.0));

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
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _poll());
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
  Widget build(BuildContext context) => Center(
        child: Text('CONNECTING TO SERVER',
            style: _retro(12, color: const Color(0xFF8FB3D9))),
      );
}

/// Single per-turn clock driving the whole animation, restarted each turn.
class _ArenaCard extends StatefulWidget {
  const _ArenaCard({required this.snap, required this.online});

  final ServerSnapshot snap;
  final bool online;

  @override
  State<_ArenaCard> createState() => _ArenaCardState();
}

class _ArenaCardState extends State<_ArenaCard> with SingleTickerProviderStateMixin {
  late final AnimationController _turn;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: _turnMs))..forward();
  }

  @override
  void didUpdateWidget(_ArenaCard old) {
    super.didUpdateWidget(old);
    if (widget.snap.tick != old.snap.tick) _turn.forward(from: 0);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1320),
        border: Border.all(color: const Color(0xFF1F2D44), width: 3),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) {
            final t = _turn.value;
            return Column(
              children: [
                _Banner(snap: widget.snap, online: widget.online),
                Expanded(child: _Stage(snap: widget.snap, t: t)),
                _Reel(snap: widget.snap, t: t),
              ],
            );
          },
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
                  Text('LEVEL ${snap.levelIndex + 1} / 10', style: _retro(9, color: const Color(0xFF5E7392))),
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
                  Text(online ? 'SERVER · LIVE' : 'RECONNECTING', style: _retro(8, color: const Color(0xFF5E7392))),
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
  const _Stage({required this.snap, required this.t});

  final ServerSnapshot snap;
  final double t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final w = c.maxWidth;
        final heroH = min(h * 0.30, w * 0.15);
        final bossH = min(h * 0.50, w * 0.32);
        final dmg = snap.reel.damage;
        final comboColor = _rarityColor(snap.reel.maxRarityTier);
        final hitting = t > _projEnd - 0.02;

        return Stack(
          fit: StackFit.expand,
          children: [
            StageBackground(theme: _theme(snap.theme)),

            // Enemy wave: right, a step higher.
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
                          glow: false,
                          // Impact lands as the projectile arrives.
                          trigger: (enemy.hit && hitting) ? snap.tick : 0,
                          lungeDir: 0,
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
                        glow: hero.acting,
                        // Acting hero lunges as it releases the strike.
                        trigger: (hero.acting && t > _projStart) ? snap.tick : 0,
                        lungeDir: 1,
                        overlay: (hero.acting && dmg != null) ? _TotalPopup(dmg: dmg, t: t) : null,
                      ),
                    ),
                ],
              ),
            ),

            // Projectile from the acting hero to the targeted enemy.
            if (dmg != null && t >= _projStart && t <= _projEnd)
              _Projectile(t: t, color: comboColor, crit: dmg.crit),
          ],
        );
      },
    );
  }
}

class _Projectile extends StatelessWidget {
  const _Projectile({required this.t, required this.color, required this.crit});

  final double t;
  final Color color;
  final bool crit;

  @override
  Widget build(BuildContext context) {
    final p = _ease(Curves.easeInCubic, (t - _projStart) / (_projEnd - _projStart));
    final a = Alignment.lerp(const Alignment(-0.6, 0.55), const Alignment(0.85, 0.18), p)!;
    final c = crit ? const Color(0xFFFFD700) : color;
    return Align(
      alignment: a,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c, blurRadius: 12, spreadRadius: 2)],
        ),
      ),
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
    required this.glow,
    required this.trigger,
    required this.lungeDir,
    required this.overlay,
  });

  final PixelArt art;
  final double height;
  final bool flipX;
  final double hpFraction;
  final bool alive;
  final int? level;
  final bool glow;
  final int trigger;
  final double lungeDir;
  final Widget? overlay;

  @override
  State<_Unit> createState() => _UnitState();
}

class _UnitState extends State<_Unit> with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _hit;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _hit = AnimationController(vsync: this, duration: const Duration(milliseconds: 360), value: 1);
  }

  @override
  void didUpdateWidget(_Unit old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger != 0) _hit.forward(from: 0);
  }

  @override
  void dispose() {
    _bob.dispose();
    _hit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = AnimatedBuilder(
      animation: Listenable.merge([_bob, _hit]),
      builder: (context, _) {
        final bobY = widget.alive ? sin(_bob.value * pi) * 2.0 : 0.0;
        final e = 1 - _hit.value; // 1 at hit -> 0
        final lungeX = widget.lungeDir != 0 ? sin(e * pi) * 9.0 * widget.lungeDir : 0.0;
        final shakeX = widget.lungeDir == 0 ? sin(e * pi * 3) * 4.0 * e : 0.0;
        final flash = e * 0.9;

        return Transform.translate(
          offset: Offset(lungeX + shakeX, -bobY - (widget.glow ? 5 : 0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.level != null) _LvBadge(level: widget.level!, glow: widget.glow),
              if (widget.level != null) const SizedBox(height: 2),
              _HpBar(fraction: widget.hpFraction, alive: widget.alive),
              const SizedBox(height: 3),
              Container(
                decoration: widget.glow
                    ? const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x9934D399), blurRadius: 16, spreadRadius: 1)])
                    : null,
                child: Opacity(
                  opacity: widget.alive ? 1 : 0.22,
                  child: PixelSprite(art: widget.art, height: widget.height, flipX: widget.flipX, flash: widget.alive ? flash : 0),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.overlay == null) return unit;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        unit,
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: OverflowBox(
                minHeight: 0,
                maxHeight: double.infinity,
                alignment: Alignment.bottomCenter,
                child: Transform.translate(offset: const Offset(0, -6), child: widget.overlay),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LvBadge extends StatelessWidget {
  const _LvBadge({required this.level, required this.glow});

  final int level;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = glow ? const Color(0xFF34D399) : const Color(0xFF24334C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFF101A2A), border: Border.all(color: c, width: 1)),
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
      decoration: BoxDecoration(color: const Color(0xFF0A0F18), border: Border.all(color: const Color(0xFF1F2D44), width: 1)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(widthFactor: f <= 0 ? 0.001 : f, child: Container(color: color)),
      ),
    );
  }
}

/// Just the running total over the acting hero: smooth count-up + a pulse and
/// a gold CRIT! pop on the last beat. No card, no clutter.
class _TotalPopup extends StatelessWidget {
  const _TotalPopup({required this.dmg, required this.t});

  final ServerDamage dmg;
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = _ease(Curves.easeOutCubic, (t - _countStart) / (_countEnd - _countStart));
    final shown = (dmg.total * p).round();
    final crit = dmg.crit && p >= 0.999;
    final color = crit ? const Color(0xFFFFD700) : const Color(0xFFF1F5F9);

    // Gentle float up + a small overshoot pulse as it lands.
    final rise = 16.0 * _ease(Curves.easeOutCubic, (t - _countStart) / 0.5);
    final landPulse = p > 0.85 ? 1 + 0.18 * sin((p - 0.85) / 0.15 * pi) : 1.0;

    return Transform.translate(
      offset: Offset(0, -rise),
      child: Transform.scale(
        scale: landPulse,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$shown',
                style: _retro(crit ? 24 : 18, color: color, w: FontWeight.w900).copyWith(shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                  Shadow(color: Colors.black, blurRadius: 10),
                ])),
            if (crit) Text('CRIT!', style: _retro(12, color: const Color(0xFFFFD700), w: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

/// The 1x3 reel: a slot-machine spin that settles cell by cell, then reveals
/// each item (icon, rarity + level, sub-stats). Smooth + staggered.
class _Reel extends StatelessWidget {
  const _Reel({required this.snap, required this.t});

  final ServerSnapshot snap;
  final double t;

  @override
  Widget build(BuildContext context) {
    final reel = snap.reel;
    final items = reel.items;
    final dmg = reel.damage;
    final settled = t > _settleBase + _settleStep * 2 + 0.10;
    final isPrize = reel.combo != 'MIXED' && items.isNotEmpty && settled;

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
              _ComboBadge(
                  label: isPrize ? '${reel.combo}  x${reel.multiplier.toStringAsFixed(0)}' : 'SPIN',
                  color: isPrize ? _rarityColor(reel.maxRarityTier) : const Color(0xFF5E7392),
                  prize: isPrize),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _cellHeight,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(child: _Cell(item: i < items.length ? items[i] : null, t: t, index: i)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.label, required this.color, required this.prize});

  final String label;
  final Color color;
  final bool prize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: prize
          ? BoxDecoration(
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
            )
          : null,
      child: Text(label, style: _retro(10, color: color, w: FontWeight.w900)),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.t, required this.index});

  final ServerReelItem? item;
  final double t;
  final int index;

  static const _spinShapes = ItemShape.values;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final color = it == null ? const Color(0xFF1F2D44) : _rarityColor(it.rarityTier);
    final settleAt = _settleBase + index * _settleStep;
    final spinning = t < settleAt;
    // Settle overshoot.
    final settleP = _ease(Curves.easeOutBack, ((t - settleAt) / 0.16).clamp(0.0, 1.0));
    // Stats fade in shortly after the item lands.
    final reveal = _ease(Curves.easeOutCubic, ((t - settleAt - 0.06) / 0.20).clamp(0.0, 1.0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: spinning ? const Color(0xFF1F2D44) : color, width: spinning ? 1 : 2),
        boxShadow: spinning ? null : [BoxShadow(color: color.withValues(alpha: 0.35 * reveal), blurRadius: 8)],
      ),
      clipBehavior: Clip.hardEdge,
      child: it == null
          ? const SizedBox.shrink()
          : (spinning ? _spinFace(it, color) : _itemFace(it, color, settleP, reveal)),
    );
  }

  Widget _spinFace(ServerReelItem it, Color color) {
    // Reel rolling: icon cycles fast with a vertical "roller" jitter.
    final idx = ((t * 60).floor() + index * 5) % _spinShapes.length;
    final jitter = sin(t * pi * 26) * 5;
    return Center(
      child: Transform.translate(
        offset: Offset(0, jitter),
        child: Opacity(
          opacity: 0.7,
          child: PixelSprite(
            art: ItemSprites.shape(_spinShapes[idx]),
            height: 40,
            recolor: {'X': const Color(0xFF8FB3D9), 'x': const Color(0xFF2A3852)},
          ),
        ),
      ),
    );
  }

  Widget _itemFace(ServerReelItem it, Color color, double settleP, double reveal) {
    return Stack(
      children: [
        // Stats panel fades/slides in.
        Padding(
          padding: const EdgeInsets.all(5),
          child: Opacity(
            opacity: reveal,
            child: Transform.translate(
              offset: Offset(0, (1 - reveal) * 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${it.rarity.toUpperCase()} · LV ${it.level}',
                      style: _retro(7, color: color, w: FontWeight.w900), maxLines: 1),
                  const SizedBox(height: 1),
                  Text(it.primary.toUpperCase(),
                      style: _retro(8.5, color: const Color(0xFFF1F5F9), w: FontWeight.w900), maxLines: 1),
                  const SizedBox(height: 2),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: it.passives.length,
                      itemExtent: 9.5,
                      itemBuilder: (context, l) => Text(it.passives[l],
                          style: _retro(6.5, color: const Color(0xFF9FB3CC)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Icon lands with an overshoot, then recedes behind the stats.
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - reveal).clamp(0.0, 1.0),
              child: Center(
                child: Transform.scale(
                  scale: 0.6 + 0.45 * settleP,
                  child: PixelSprite(
                    art: ItemSprites.shape(_shape(it.shape)),
                    height: 40,
                    recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
