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

// ---------------------------------------------------------------------------
// Turn-based combat presentation (HSR / FF inspired):
//  - turn-order rail at the top,
//  - cards that flip in for the slot roll,
//  - a combo "break" banner,
//  - floating damage numbers over the enemy (crit = gold pop),
//  - a projectile + impact shake.
// All data comes from the server snapshot; the client only animates it.
// ---------------------------------------------------------------------------

const _pixelFont = 'monospace';
const int _turnMs = 2600;

// Timeline (fractions of a turn).
const double _cardStart = 0.05;
const double _cardStagger = 0.12;
const double _cardDur = 0.26;
const double _bannerStart = 0.44;
const double _lungeAt = 0.62;
const double _projStart = 0.64;
const double _projEnd = 0.84;
const double _hitAt = 0.84;

TextStyle _retro(double size,
        {Color color = const Color(0xFFF1F5F9), FontWeight w = FontWeight.w700}) =>
    TextStyle(fontFamily: _pixelFont, fontSize: size, color: color, fontWeight: w, letterSpacing: 1.0, height: 1.1);

List<Shadow> _outline(Color c, [double b = 3]) => [
      Shadow(color: c, offset: const Offset(1, 1), blurRadius: b),
      Shadow(color: c, offset: const Offset(-1, 1), blurRadius: b),
      Shadow(color: c, offset: const Offset(1, -1), blurRadius: b),
      Shadow(color: c, blurRadius: b * 2),
    ];

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

Color _rarityColor(int tier) => Rarity.values[(tier - 1).clamp(0, Rarity.values.length - 1)].color;

Color _comboColor(String combo) => switch (combo) {
      'JACKPOT' => const Color(0xFFFFD700),
      'SYNERGY' => const Color(0xFFA78BFA),
      'PAIR' => const Color(0xFF60A5FA),
      _ => const Color(0xFF5E7392),
    };

double _ease(Curve c, double x) => c.transform(x.clamp(0.0, 1.0));
double _win(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

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
            child: _snap == null ? const _Connecting() : _ArenaCard(snap: _snap!, online: _online),
          ),
        ),
      ),
    );
  }
}

class _Connecting extends StatelessWidget {
  const _Connecting();

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('CONNECTING TO SERVER', style: _retro(12, color: const Color(0xFF8FB3D9))));
}

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
                _TurnOrderRail(snap: widget.snap),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(color: Color(0xFF111B2C)),
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

/// HSR-style turn-order rail: every combatant, the current actor highlighted.
class _TurnOrderRail extends StatelessWidget {
  const _TurnOrderRail({required this.snap});

  final ServerSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final h in snap.heroes) {
      chips.add(_RailChip(art: ItemSprites.roster(_roster(h.archetype)), ally: true, active: h.acting, alive: h.alive));
    }
    for (final e in snap.enemies.where((e) => e.alive)) {
      chips.add(_RailChip(art: Sprites.enemy(_enemy(e.kind)), ally: false, active: false, alive: true, flip: true));
    }

    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1422),
        border: Border(bottom: BorderSide(color: Color(0xFF1F2D44), width: 2)),
      ),
      child: Row(
        children: [
          Text('TURN', style: _retro(8, color: const Color(0xFF5E7392))),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => Center(child: chips[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailChip extends StatelessWidget {
  const _RailChip({required this.art, required this.ally, required this.active, required this.alive, this.flip = false});

  final PixelArt art;
  final bool ally;
  final bool active;
  final bool alive;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final accent = ally ? const Color(0xFF34D399) : const Color(0xFFEF6B6B);
    final side = active ? 30.0 : 26.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        border: Border.all(color: active ? Colors.white : accent, width: active ? 2 : 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: active ? [BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 9)] : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Center(child: PixelSprite(art: art, height: side - 6, flipX: flip)),
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
        final heroH = min(h * 0.32, w * 0.155);
        final bossH = min(h * 0.52, w * 0.34);
        final dmg = snap.reel.damage;
        final comboColor = _comboColor(snap.reel.combo);

        return Stack(
          fit: StackFit.expand,
          children: [
            StageBackground(theme: _theme(snap.theme)),

            // Enemy wave: right, a step higher.
            Align(
              alignment: const Alignment(0.95, 0.7),
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
                          trigger: (enemy.hit && t > _hitAt) ? snap.tick : 0,
                          lungeDir: 0,
                          overlay: (enemy.hit && dmg != null)
                              ? _DamageNumber(value: dmg.total, crit: dmg.crit, t: t)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Allies: front-left.
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
                        trigger: (hero.acting && t > _lungeAt) ? snap.tick : 0,
                        lungeDir: 1,
                        overlay: null,
                      ),
                    ),
                ],
              ),
            ),

            // Projectile from the acting hero to the targeted enemy.
            if (dmg != null && t >= _projStart && t <= _projEnd)
              _Projectile(t: t, color: comboColor, crit: dmg.crit),

            // Combo "break" banner.
            if (snap.reel.combo != 'MIXED' && dmg != null)
              _ComboBanner(combo: snap.reel.combo, mult: snap.reel.multiplier, t: t),
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
    final p = _ease(Curves.easeInCubic, _win(t, _projStart, _projEnd));
    final a = Alignment.lerp(const Alignment(-0.55, 0.55), const Alignment(0.8, 0.32), p)!;
    final c = crit ? const Color(0xFFFFD700) : color;
    return Align(
      alignment: a,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c, blurRadius: 14, spreadRadius: 3)],
        ),
      ),
    );
  }
}

/// HSR/FF-style floating damage number over the enemy.
class _DamageNumber extends StatelessWidget {
  const _DamageNumber({required this.value, required this.crit, required this.t});

  final double value;
  final bool crit;
  final double t;

  @override
  Widget build(BuildContext context) {
    if (t < _hitAt) return const SizedBox.shrink();
    final local = _win(t, _hitAt, 1.0);
    final pop = _ease(Curves.easeOutBack, _win(t, _hitAt, _hitAt + 0.07));
    final rise = 30.0 * _ease(Curves.easeOutCubic, local);
    final fade = local < 0.7 ? 1.0 : (1 - (local - 0.7) / 0.3);
    final color = crit ? const Color(0xFFFFD700) : const Color(0xFFFFF1C2);

    return Transform.translate(
      offset: Offset(0, -22 - rise),
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.4 + 0.6 * pop,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (crit)
                Text('CRIT', style: _retro(9, color: const Color(0xFFFFD700), w: FontWeight.w900).copyWith(shadows: _outline(Colors.black))),
              Text('${value.round()}',
                  style: _retro(crit ? 30 : 24, color: color, w: FontWeight.w900).copyWith(shadows: _outline(Colors.black, 4))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cinematic combo banner (weakness-break style): zoom-in + glow, then fade.
class _ComboBanner extends StatelessWidget {
  const _ComboBanner({required this.combo, required this.mult, required this.t});

  final String combo;
  final double mult;
  final double t;

  @override
  Widget build(BuildContext context) {
    if (t < _bannerStart) return const SizedBox.shrink();
    final inP = _ease(Curves.easeOutBack, _win(t, _bannerStart, _bannerStart + 0.14));
    final fade = t < 0.82 ? 1.0 : (1 - _win(t, 0.82, 0.96));
    if (fade <= 0) return const SizedBox.shrink();
    final color = _comboColor(combo);
    final label = combo == 'JACKPOT' ? 'JACKPOT!' : combo == 'SYNERGY' ? 'SYNERGY!' : 'PAIR!';

    return Align(
      alignment: const Alignment(0, -0.35),
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.45 * inP,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _retro(combo == 'JACKPOT' ? 26 : 20, color: color, w: FontWeight.w900).copyWith(shadows: _outline(Colors.black, 5))),
              const SizedBox(width: 8),
              Text('x${mult.toStringAsFixed(0)}',
                  style: _retro(combo == 'JACKPOT' ? 26 : 20, color: Colors.white, w: FontWeight.w900).copyWith(shadows: _outline(color, 6))),
            ],
          ),
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
        final e = 1 - _hit.value;
        final lungeX = widget.lungeDir != 0 ? sin(e * pi) * 10.0 * widget.lungeDir : 0.0;
        final shakeX = widget.lungeDir == 0 ? sin(e * pi * 3) * 5.0 * e : 0.0;
        final flash = e * 0.95;

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
                child: widget.overlay,
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
      width: 40,
      height: 6,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: const Color(0xFF0A0F18), border: Border.all(color: const Color(0xFF1F2D44), width: 1)),
      child: Stack(
        children: [
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            widthFactor: f <= 0 ? 0.001 : f,
            child: Container(color: color),
          ),
        ],
      ),
    );
  }
}

/// Bottom panel: the acting hero portrait + the three item cards flipping in.
class _Reel extends StatelessWidget {
  const _Reel({required this.snap, required this.t});

  final ServerSnapshot snap;
  final double t;

  @override
  Widget build(BuildContext context) {
    final reel = snap.reel;
    final items = reel.items;
    final dmg = reel.damage;
    final actor = dmg?.heroName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
      decoration: const BoxDecoration(
        color: Color(0xFF0A111E),
        border: Border(top: BorderSide(color: Color(0xFF1F2D44), width: 2)),
      ),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActorPlate(snap: snap, name: actor),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _ItemCard(item: i < items.length ? items[i] : null, t: t, index: i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActorPlate extends StatelessWidget {
  const _ActorPlate({required this.snap, required this.name});

  final ServerSnapshot snap;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final acting = snap.heroes.where((h) => h.acting).toList();
    final hero = acting.isNotEmpty ? acting.first : null;

    return Container(
      width: 78,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        border: Border.all(color: const Color(0xFF34D399), width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hero != null)
            PixelSprite(art: ItemSprites.roster(_roster(hero.archetype)), height: 66)
          else
            const SizedBox(height: 66),
          const SizedBox(height: 4),
          Text((name ?? '').toUpperCase(), style: _retro(8, color: const Color(0xFFF1F5F9)), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (hero != null) Text('LV ${hero.level}', style: _retro(7, color: const Color(0xFF6EE7B7))),
        ],
      ),
    );
  }
}

/// A single item card that flips in (3D), then shows its details.
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.t, required this.index});

  final ServerReelItem? item;
  final double t;
  final int index;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final color = it == null ? const Color(0xFF243248) : _rarityColor(it.rarityTier);
    final start = _cardStart + index * _cardStagger;
    final flip = _ease(Curves.easeOutCubic, _win(t, start, start + _cardDur));
    final angle = (1 - flip) * (pi / 2.1);
    final revealed = flip >= 0.55;

    final card = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: revealed ? color : const Color(0xFF2A3852), width: revealed ? 2 : 1),
        borderRadius: BorderRadius.circular(5),
        boxShadow: revealed ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 9)] : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: it == null ? const SizedBox.shrink() : _face(it, color, revealed),
    );

    return Opacity(
      opacity: (flip * 1.6).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle),
        child: card,
      ),
    );
  }

  Widget _face(ServerReelItem it, Color color, bool revealed) {
    if (!revealed) {
      // Card "back" while still turning.
      return Center(
        child: PixelSprite(
          art: ItemSprites.shape(_shape(it.shape)),
          height: 40,
          recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.5)!},
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelSprite(
                art: ItemSprites.shape(_shape(it.shape)),
                height: 22,
                recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${it.rarity.toUpperCase()}\nLV ${it.level}',
                    style: _retro(6.5, color: color, w: FontWeight.w900), maxLines: 2),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(it.primary.toUpperCase(),
              style: _retro(8, color: const Color(0xFFF1F5F9), w: FontWeight.w900), maxLines: 1),
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
    );
  }
}
