import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game/combat_service.dart';
import '../../core/game/game.dart' show EnemyKind, BgTheme;
import '../../core/game/server_game.dart';
import '../../core/inventory/inventory_model.dart' show RosterId, ItemShape, Rarity, RarityX;
import '../../core/pixel/backgrounds.dart';
import '../../core/pixel/item_sprites.dart';
import '../../core/pixel/pixel_art.dart';
import '../../core/pixel/sprites.dart';

// ---------------------------------------------------------------------------
// Always-on LANDSCAPE combat panel (~2:1), HSR/FF-inspired and widget-ready.
//  - turn-order rail (top, slim)
//  - scene: allies on the left, enemies on the right, facing each other
//  - slot roll (bottom, compact): 3 item icons spin/flip in + combo badge
//  - floating damage over the enemy, projectile, impact shake
// Detailed sub-stats live on the Battle tab, not on this compact panel.
// ---------------------------------------------------------------------------

const _pixelFont = 'monospace';
const int _turnMs = 2600;
const double _cardStart = 0.06;
const double _cardStagger = 0.10;
const double _cardDur = 0.24;
const double _bannerStart = 0.42;
const double _lungeAt = 0.60;
const double _projStart = 0.62;
const double _projEnd = 0.84;
const double _hitAt = 0.84;

TextStyle _retro(double size, {Color color = const Color(0xFFF1F5F9), FontWeight w = FontWeight.w700}) =>
    TextStyle(fontFamily: _pixelFont, fontSize: size, color: color, fontWeight: w, letterSpacing: 0.8, height: 1.1);

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

/// Public entry: listens to the shared service and renders the panel at 2:1.
class CombatPanel extends StatelessWidget {
  const CombatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServerSnapshot?>(
      valueListenable: CombatService.instance.snapshot,
      builder: (context, snap, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: CombatService.instance.online,
          builder: (context, online, __) {
            return _Frame(child: snap == null ? const _Connecting() : _CombatView(snap: snap, online: online));
          },
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1320),
        border: Border.all(color: const Color(0xFF1F2D44), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: AspectRatio(aspectRatio: 2 / 1, child: child)),
    );
  }
}

class _Connecting extends StatelessWidget {
  const _Connecting();

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('CONNECTING…', style: _retro(11, color: const Color(0xFF8FB3D9))));
}

class _CombatView extends StatefulWidget {
  const _CombatView({required this.snap, required this.online});

  final ServerSnapshot snap;
  final bool online;

  @override
  State<_CombatView> createState() => _CombatViewState();
}

class _CombatViewState extends State<_CombatView> with SingleTickerProviderStateMixin {
  late final AnimationController _turn;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: _turnMs))..forward();
  }

  @override
  void didUpdateWidget(_CombatView old) {
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
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, _) => Column(
        children: [
          _Rail(snap: widget.snap, online: widget.online),
          Expanded(child: _Scene(snap: widget.snap, t: _turn.value)),
          _Roll(snap: widget.snap, t: _turn.value),
        ],
      ),
    );
  }
}

/// Slim turn-order rail + level/status.
class _Rail extends StatelessWidget {
  const _Rail({required this.snap, required this.online});

  final ServerSnapshot snap;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1422),
        border: Border(bottom: BorderSide(color: Color(0xFF1F2D44), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: online ? const Color(0xFF34D399) : const Color(0xFFEF4444)),
          ),
          const SizedBox(width: 5),
          Text('LV ${snap.levelIndex + 1}', style: _retro(8, color: const Color(0xFF8FB3D9))),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                for (final h in snap.heroes) _Dot(art: ItemSprites.roster(_roster(h.archetype)), active: h.acting, ally: true),
                const SizedBox(width: 8),
                for (final e in snap.enemies.where((e) => e.alive)) _Dot(art: Sprites.enemy(_enemy(e.kind)), active: false, ally: false, flip: true),
              ],
            ),
          ),
          Text(snap.levelName.toUpperCase(), style: _retro(8, color: const Color(0xFF5E7392)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.art, required this.active, required this.ally, this.flip = false});

  final PixelArt art;
  final bool active;
  final bool ally;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final accent = ally ? const Color(0xFF34D399) : const Color(0xFFEF6B6B);
    final side = active ? 18.0 : 15.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: side,
      height: side,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        border: Border.all(color: active ? Colors.white : accent, width: 1),
        borderRadius: BorderRadius.circular(3),
        boxShadow: active ? [BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 6)] : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Center(child: PixelSprite(art: art, height: side - 4, flipX: flip)),
    );
  }
}

/// The scene: allies left, enemies right, facing each other.
class _Scene extends StatelessWidget {
  const _Scene({required this.snap, required this.t});

  final ServerSnapshot snap;
  final double t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final heroH = h * 0.5;
        final bossH = h * 0.74;
        final dmg = snap.reel.damage;
        final comboColor = _comboColor(snap.reel.combo);

        return Stack(
          fit: StackFit.expand,
          children: [
            StageBackground(theme: _theme(snap.theme)),

            // Allies — bottom-left.
            Align(
              alignment: const Alignment(-0.98, 0.92),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final hero in snap.heroes)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _Unit(
                        key: ValueKey(hero.id),
                        art: ItemSprites.roster(_roster(hero.archetype)),
                        height: heroH,
                        flipX: false,
                        hpFraction: hero.hpFraction,
                        alive: hero.alive,
                        glow: hero.acting,
                        trigger: (hero.acting && t > _lungeAt) ? snap.tick : 0,
                        lungeDir: 1,
                        overlay: null,
                      ),
                    ),
                ],
              ),
            ),

            // Enemies — bottom-right.
            Align(
              alignment: const Alignment(0.98, 0.92),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final enemy in snap.enemies)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedOpacity(
                        opacity: enemy.alive ? 1 : 0,
                        duration: const Duration(milliseconds: 350),
                        child: _Unit(
                          key: ValueKey(enemy.id),
                          art: Sprites.enemy(_enemy(enemy.kind)),
                          height: enemy.isBoss ? bossH : heroH * 0.92,
                          flipX: true,
                          hpFraction: enemy.hpFraction,
                          alive: enemy.alive,
                          glow: false,
                          trigger: (enemy.hit && t > _hitAt) ? snap.tick : 0,
                          lungeDir: -1,
                          overlay: (enemy.hit && dmg != null) ? _DamageNumber(value: dmg.total, crit: dmg.crit, t: t) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (dmg != null && t >= _projStart && t <= _projEnd) _Projectile(t: t, color: comboColor, crit: dmg.crit),
            if (snap.reel.combo != 'MIXED' && dmg != null) _ComboBanner(combo: snap.reel.combo, mult: snap.reel.multiplier, t: t),
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
    final a = Alignment.lerp(const Alignment(-0.7, 0.4), const Alignment(0.75, 0.3), p)!;
    final c = crit ? const Color(0xFFFFD700) : color;
    return Align(
      alignment: a,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c, blurRadius: 10, spreadRadius: 2)]),
      ),
    );
  }
}

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
    final rise = 22.0 * _ease(Curves.easeOutCubic, local);
    final fade = local < 0.7 ? 1.0 : (1 - (local - 0.7) / 0.3);
    final color = crit ? const Color(0xFFFFD700) : const Color(0xFFFFF1C2);

    return Transform.translate(
      offset: Offset(0, -16 - rise),
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.5 + 0.6 * pop,
          child: Text('${value.round()}',
              style: _retro(crit ? 22 : 17, color: color, w: FontWeight.w900).copyWith(shadows: _outline(Colors.black, 4))),
        ),
      ),
    );
  }
}

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
      alignment: const Alignment(0, -0.55),
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.5 * inP,
          child: Text('$label x${mult.toStringAsFixed(0)}',
              style: _retro(combo == 'JACKPOT' ? 18 : 15, color: color, w: FontWeight.w900).copyWith(shadows: _outline(Colors.black, 4))),
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
    _hit = AnimationController(vsync: this, duration: const Duration(milliseconds: 340), value: 1);
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
        final bobY = widget.alive ? sin(_bob.value * pi) * 1.5 : 0.0;
        final e = 1 - _hit.value;
        final lungeX = widget.lungeDir != 0 && _hit.value < 1 ? sin(e * pi) * 8.0 * widget.lungeDir : 0.0;
        final flash = e * 0.95;

        return Transform.translate(
          offset: Offset(lungeX, -bobY - (widget.glow ? 3 : 0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HpBar(fraction: widget.hpFraction, alive: widget.alive),
              const SizedBox(height: 2),
              Container(
                decoration: widget.glow
                    ? const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x9934D399), blurRadius: 12, spreadRadius: 1)])
                    : null,
                child: Opacity(
                  opacity: widget.alive ? 1 : 0.2,
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
              child: OverflowBox(minHeight: 0, maxHeight: double.infinity, alignment: Alignment.bottomCenter, child: widget.overlay),
            ),
          ),
        ),
      ],
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
      width: 30,
      height: 4,
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(color: const Color(0xFF0A0F18), border: Border.all(color: const Color(0xFF1F2D44), width: 1)),
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerLeft,
        widthFactor: f <= 0 ? 0.001 : f,
        child: Container(color: color),
      ),
    );
  }
}

/// Bottom roll: the three item icons flip/spin in + the combo badge.
class _Roll extends StatelessWidget {
  const _Roll({required this.snap, required this.t});

  final ServerSnapshot snap;
  final double t;

  @override
  Widget build(BuildContext context) {
    final reel = snap.reel;
    final items = reel.items;
    final isPrize = reel.combo != 'MIXED' && items.isNotEmpty;
    final heroTurn = reel.damage != null;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF0A111E),
        border: Border(top: BorderSide(color: Color(0xFF1F2D44), width: 1)),
      ),
      child: Row(
        children: [
          if (reel.damage != null) ...[
            Text(reel.damage!.heroName.toUpperCase(), style: _retro(8, color: const Color(0xFF6EE7B7))),
            const SizedBox(width: 8),
          ],
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _RollIcon(item: i < items.length ? items[i] : null, t: t, index: i, dim: !heroTurn),
            ),
          const Spacer(),
          if (isPrize)
            _Badge(label: '${reel.combo} x${reel.multiplier.toStringAsFixed(0)}', color: _comboColor(reel.combo)),
        ],
      ),
    );
  }
}

class _RollIcon extends StatelessWidget {
  const _RollIcon({required this.item, required this.t, required this.index, required this.dim});

  final ServerReelItem? item;
  final double t;
  final int index;
  final bool dim;

  static const _spin = ItemShape.values;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final color = it == null ? const Color(0xFF243248) : _rarityColor(it.rarityTier);
    final start = _cardStart + index * _cardStagger;
    final flip = _ease(Curves.easeOutCubic, _win(t, start, start + _cardDur));
    final spinning = flip < 1 && !dim;
    final angle = (1 - flip) * (pi / 2.1);
    final shownShape = (it == null)
        ? ItemShape.sword
        : (spinning ? _spin[((t * 60).floor() + index * 5) % _spin.length] : _shape(it.shape));

    return Opacity(
      opacity: dim ? 0.5 : (flip * 1.6).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF111B2C),
            border: Border.all(color: (flip >= 1 && !dim) ? color : const Color(0xFF2A3852), width: (flip >= 1 && !dim) ? 2 : 1),
            borderRadius: BorderRadius.circular(4),
            boxShadow: (flip >= 1 && !dim) ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)] : null,
          ),
          child: it == null
              ? const SizedBox.shrink()
              : Center(
                  child: PixelSprite(
                    art: ItemSprites.shape(shownShape),
                    height: 24,
                    recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
                  ),
                ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 7)],
      ),
      child: Text(label, style: _retro(9, color: color, w: FontWeight.w900)),
    );
  }
}
