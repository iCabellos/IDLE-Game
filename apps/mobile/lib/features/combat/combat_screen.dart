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
const double _cellHeight = 172;
const double _passiveLineH = 9.5;

/// Total turn animation length, scaled to the number of sub-stats so the walk
/// always covers them all and still finishes before the next 4s server turn.
int _turnMs(int ledgerLen) => (1600 + ledgerLen * 120).clamp(1800, 3400);

/// Progress (0..1) of the "apply sub-stats" phase (after the items roll in).
double _walkP(double t) => ((t - 0.18) / 0.82).clamp(0.0, 1.0);

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
  Widget build(BuildContext context) {
    return Center(
      child: Text('CONNECTING TO SERVER',
          style: _retro(12, color: const Color(0xFF8FB3D9))),
    );
  }
}

/// Owns the single per-turn clock so the reel underline, the total and the
/// floating before/after rows are all frame-locked together.
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
    _turn = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _turnMs(widget.snap.reel.ledger.length)),
    )..forward();
  }

  @override
  void didUpdateWidget(_ArenaCard old) {
    super.didUpdateWidget(old);
    if (widget.snap.tick != old.snap.tick) {
      _turn.duration = Duration(milliseconds: _turnMs(widget.snap.reel.ledger.length));
      _turn.forward(from: 0);
    }
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
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
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

/// Allies front-left, enemy wave back-right (a step higher).
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
        final ledger = snap.reel.ledger;
        final hasDebuffs = ledger.any((e) => e.isEnemy);

        return Stack(
          fit: StackFit.expand,
          children: [
            StageBackground(theme: _theme(snap.theme)),

            // Enemy wave: right side, a step above the allies.
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
                          overlay: (enemy.hit && hasDebuffs)
                              ? _FloatRows(ledger: ledger, t: t, enemy: true)
                              : null,
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
                            ? _HeroTotal(dmg: dmg, ledger: ledger, t: t)
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
                child: Transform.translate(offset: const Offset(0, -8), child: widget.overlay),
              ),
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

/// Only the running total (no card/border), rising as hero before/after rows
/// stack below it. Counts up through the breakdown steps over the walk phase.
class _HeroTotal extends StatelessWidget {
  const _HeroTotal({required this.dmg, required this.ledger, required this.t});

  final ServerDamage dmg;
  final List<ServerSubStat> ledger;
  final double t;

  @override
  Widget build(BuildContext context) {
    final steps = dmg.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    final p = _walkP(t);
    final segs = steps.length;
    final pos = (p * (segs - 1)).clamp(0.0, (segs - 1).toDouble());
    final i = pos.floor().clamp(0, segs - 1);
    final frac = (pos - i).clamp(0.0, 1.0);
    final to = steps[min(i + 1, segs - 1)].total;
    final shown = (steps[i].total + (to - steps[i].total) * frac).round();
    final finalCrit = dmg.crit && p > 0.96;
    final numColor = finalCrit ? const Color(0xFFFFD700) : const Color(0xFFF1F5F9);

    final rows = _ledgerRows(ledger, t, enemy: false, color: const Color(0xFF6EE7B7));

    return Transform.translate(
      offset: Offset(0, -rows.length * 10.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$shown',
              style: _retro(finalCrit ? 22 : 17, color: numColor, w: FontWeight.w900).copyWith(
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                  Shadow(color: Colors.black, blurRadius: 8),
                ],
              )),
          if (finalCrit)
            Text('CRIT!!', style: _retro(12, color: const Color(0xFFFFD700), w: FontWeight.w900)),
          ...rows,
        ],
      ),
    );
  }
}

/// Debuff before/after rows floating over the targeted enemy.
class _FloatRows extends StatelessWidget {
  const _FloatRows({required this.ledger, required this.t, required this.enemy});

  final List<ServerSubStat> ledger;
  final double t;
  final bool enemy;

  @override
  Widget build(BuildContext context) {
    final rows = _ledgerRows(ledger, t, enemy: enemy, color: const Color(0xFFEF6B6B));
    if (rows.isEmpty) return const SizedBox.shrink();
    return Transform.translate(
      offset: Offset(0, -rows.length * 10.5),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// Builds the visible (newest-first, soft-fading) before/after rows for one
/// side. No fixed cap — older rows fade to nothing instead of being clipped.
List<Widget> _ledgerRows(List<ServerSubStat> ledger, double t,
    {required bool enemy, required Color color}) {
  if (ledger.isEmpty) return const [];
  final p = _walkP(t);
  final applied = (p * ledger.length).floor().clamp(0, ledger.length);
  final rows = <Widget>[];
  for (var k = applied - 1; k >= 0; k--) {
    if (ledger[k].isEnemy != enemy) continue;
    final age = (applied - 1 - k);
    final op = (1.0 - age * 0.16).clamp(0.0, 1.0);
    if (op <= 0.02) break;
    final s = ledger[k];
    rows.add(Opacity(
      opacity: op,
      child: Text('${s.stat}  ${s.before} -> ${s.after}',
          style: _retro(7.5, color: color, w: FontWeight.w900), maxLines: 1),
    ));
  }
  return rows;
}

/// Fixed-size 1x3 reel. Items roll in, then the underline walks every sub-stat
/// of every item in order, auto-scrolling each cell so all are visible.
class _Reel extends StatelessWidget {
  const _Reel({required this.snap, required this.t});

  final ServerSnapshot snap;
  final double t;

  @override
  Widget build(BuildContext context) {
    final reel = snap.reel;
    final items = reel.items;
    final dmg = reel.damage;
    final isPrize = reel.combo != 'MIXED' && items.isNotEmpty;
    final led = reel.ledger;

    final p = _walkP(t);
    final applied = led.isEmpty ? 0 : (p * led.length).floor().clamp(0, led.length);
    final cur = applied - 1;
    final curCell = cur >= 0 ? led[cur].cell : -1;
    final curLine = cur >= 0 ? led[cur].line : -1;

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
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: _Cell(
                      item: i < items.length ? items[i] : null,
                      t: t,
                      index: i,
                      highlightLine: curCell == i ? curLine : -1,
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

class _Cell extends StatefulWidget {
  const _Cell({required this.item, required this.t, required this.index, required this.highlightLine});

  final ServerReelItem? item;
  final double t;
  final int index;
  final int highlightLine;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  final _sc = ScrollController();
  int _lastLine = -1;

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _scrollTo(int line) {
    if (line < 0 || !_sc.hasClients) return;
    final target = (line * _passiveLineH - 46).clamp(0.0, _sc.position.maxScrollExtent);
    _sc.animateTo(target, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final color = it == null ? const Color(0xFF1F2D44) : _rarityColor(it.rarityTier);

    // Roll-in happens in the first 0.18 of the turn.
    final t = widget.t;
    final ci = ((t - widget.index * 0.05) / 0.06).clamp(0.0, 1.0);
    final textT = ((t - 0.12) / 0.06).clamp(0.0, 1.0);
    final iconOpacity = ci * (1 - textT);
    final iconScale = 0.55 + 0.45 * ci;

    if (widget.highlightLine != _lastLine) {
      _lastLine = widget.highlightLine;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_lastLine));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: ci > 0.9 ? color : const Color(0xFF1F2D44), width: ci > 0.9 ? 2 : 1),
        boxShadow: ci > 0.9 ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)] : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: it == null
          ? const SizedBox.shrink()
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Opacity(
                    opacity: textT,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${it.rarity.toUpperCase()} · LV ${it.level}',
                            style: _retro(7, color: color, w: FontWeight.w900), maxLines: 1),
                        const SizedBox(height: 1),
                        Text(it.primary.toUpperCase(),
                            style: _retro(8, color: const Color(0xFFF1F5F9), w: FontWeight.w900),
                            maxLines: 2),
                        const SizedBox(height: 2),
                        Expanded(
                          child: ListView.builder(
                            controller: _sc,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: it.passives.length,
                            itemExtent: _passiveLineH,
                            itemBuilder: (context, l) => _PassiveLine(
                              text: it.passives[l],
                              color: color,
                              lit: l == widget.highlightLine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

class _PassiveLine extends StatelessWidget {
  const _PassiveLine({required this.text, required this.color, required this.lit});

  final String text;
  final Color color;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 2),
      decoration: lit
          ? BoxDecoration(
              color: color.withValues(alpha: 0.34),
              border: Border(left: BorderSide(color: color, width: 2)),
            )
          : null,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: _retro(6.5,
            color: lit ? const Color(0xFFFFFFFF) : const Color(0xFF9FB3CC),
            w: lit ? FontWeight.w900 : FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
