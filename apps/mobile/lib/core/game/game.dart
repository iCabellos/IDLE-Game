import 'dart:async';
import 'dart:math';

/// ---------------------------------------------------------------------------
/// Idle-combat game model + engine.
///
/// Everything the UI consumes is delivered ASYNCHRONOUSLY:
///  - [GameRepository.loadCampaign] returns a Future (simulating a backend).
///  - [CombatController] streams [CombatSnapshot]s over time (the live battle).
///
/// The UI never sees raw stat numbers — only fractions (for bars) and
/// qualitative outcomes (HIT / CRIT! / COMBO / ...).
/// ---------------------------------------------------------------------------

enum HeroClass { knight, mage, ranger }

enum EnemyKind { slime, bat, goblin, skeleton, orc, demon }

/// The five symbols that can land on the 3x3 slot engine.
enum SlotSymbol { sword, fire, bolt, shield, star }

/// Qualitative result of an attack roll (drives colours / labels / damage).
enum OutcomeKind { hit, power, burn, crit, combo, guard }

/// Visual theme of a stage background.
enum BgTheme { meadow, cavern, forest, crypt, volcano, citadel }

enum CampaignStatus { fighting, levelCleared, campaignCleared }

/// Immutable per-hero view for the UI (fractions only, no raw stats).
class HeroState {
  const HeroState({
    required this.id,
    required this.name,
    required this.klass,
    required this.level,
    required this.hpFraction,
    required this.alive,
  });

  final String id;
  final String name;
  final HeroClass klass;
  final int level;
  final double hpFraction; // 0..1
  final bool alive;
}

class EnemyState {
  const EnemyState({
    required this.id,
    required this.kind,
    required this.hpFraction,
    required this.alive,
    required this.isBoss,
  });

  final String id;
  final EnemyKind kind;
  final double hpFraction; // 0..1
  final bool alive;
  final bool isBoss;
}

/// One delivered frame of the battle.
class CombatSnapshot {
  const CombatSnapshot({
    required this.tick,
    required this.levelIndex,
    required this.levelName,
    required this.theme,
    required this.phaseIndex,
    required this.phaseCount,
    required this.waveIndex,
    required this.wavesPerPhase,
    required this.heroes,
    required this.enemies,
    required this.grid,
    required this.matched,
    required this.gridTick,
    required this.outcome,
    required this.actorIsHero,
    required this.actorId,
    required this.targetId,
    required this.status,
  });

  final int tick;
  final int levelIndex;
  final String levelName;
  final BgTheme theme;
  final int phaseIndex;
  final int phaseCount;
  final int waveIndex;
  final int wavesPerPhase;
  final List<HeroState> heroes;
  final List<EnemyState> enemies;

  /// Current 3x3 slot face (row-major, 9 entries) — persists between frames.
  final List<SlotSymbol> grid;

  /// Indices (0..8) that formed a winning line on the last roll.
  final Set<int> matched;

  /// Increments only when a fresh slot roll happened (drives roll animation).
  final int gridTick;

  final OutcomeKind outcome;
  final bool actorIsHero;
  final String? actorId;
  final String? targetId;
  final CampaignStatus status;
}

class LevelDef {
  const LevelDef({
    required this.index,
    required this.name,
    required this.theme,
    required this.phaseCount,
    required this.wavesPerPhase,
    required this.enemyCount,
    required this.kinds,
    required this.bossKind,
    required this.hpScale,
  });

  final int index;
  final String name;
  final BgTheme theme;
  final int phaseCount;
  final int wavesPerPhase;
  final int enemyCount;
  final List<EnemyKind> kinds;
  final EnemyKind bossKind;
  final double hpScale;
}

/// The 10-level test campaign with escalating themes and difficulty.
List<LevelDef> buildCampaign() {
  const names = [
    'Verdant Approach',
    'Whispering Crypts',
    'Hollow Pinewood',
    'Bonecold Catacombs',
    'Emberfall Caldera',
    'Sunken Ramparts',
    'Gloomroot Thicket',
    'Ashen Bastion',
    'Obsidian Spire',
    'Throne of Cinders',
  ];
  const themes = [
    BgTheme.meadow,
    BgTheme.crypt,
    BgTheme.forest,
    BgTheme.crypt,
    BgTheme.volcano,
    BgTheme.citadel,
    BgTheme.forest,
    BgTheme.cavern,
    BgTheme.citadel,
    BgTheme.volcano,
  ];
  const pools = <List<EnemyKind>>[
    [EnemyKind.slime, EnemyKind.bat],
    [EnemyKind.bat, EnemyKind.skeleton],
    [EnemyKind.slime, EnemyKind.goblin],
    [EnemyKind.skeleton, EnemyKind.bat],
    [EnemyKind.goblin, EnemyKind.orc],
    [EnemyKind.skeleton, EnemyKind.orc],
    [EnemyKind.goblin, EnemyKind.slime, EnemyKind.bat],
    [EnemyKind.orc, EnemyKind.skeleton],
    [EnemyKind.orc, EnemyKind.goblin, EnemyKind.bat],
    [EnemyKind.demon, EnemyKind.orc],
  ];
  const bosses = [
    EnemyKind.goblin,
    EnemyKind.skeleton,
    EnemyKind.orc,
    EnemyKind.skeleton,
    EnemyKind.orc,
    EnemyKind.orc,
    EnemyKind.orc,
    EnemyKind.demon,
    EnemyKind.demon,
    EnemyKind.demon,
  ];

  return List.generate(10, (i) {
    return LevelDef(
      index: i,
      name: names[i],
      theme: themes[i],
      phaseCount: 2 + (i ~/ 4), // 2 -> 3 phases as you go deeper
      wavesPerPhase: 2 + (i % 2), // 2 or 3 waves
      enemyCount: 2 + ((i ~/ 3).clamp(0, 2)), // 2 -> 4 enemies
      kinds: pools[i],
      bossKind: bosses[i],
      hpScale: 1.0 + i * 0.18,
    );
  });
}

/// Simulated async data source. Swap the body for a real HTTP call later.
class GameRepository {
  Future<List<LevelDef>> loadCampaign() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return buildCampaign();
  }
}

// --- internal mutable combatants -------------------------------------------

class _Hero {
  _Hero(this.id, this.name, this.klass);
  final String id;
  final String name;
  final HeroClass klass;
  int level = 1;
  double maxHp = 200;
  double hp = 200;
  bool get alive => hp > 0;
  int reviveIn = -1;

  void relevel() {
    level += 1;
    maxHp = 180 + level * 34;
    hp = maxHp;
    reviveIn = -1;
  }
}

class _Enemy {
  _Enemy(this.id, this.kind, this.maxHp, {this.isBoss = false}) : hp = maxHp;
  final String id;
  final EnemyKind kind;
  final double maxHp;
  double hp;
  final bool isBoss;
  bool get alive => hp > 0;
}

/// Drives the live battle and emits [CombatSnapshot]s on a [Stream].
class CombatController {
  CombatController(this._levels, {this.tickMs = 780}) {
    _heroes = [
      _Hero('h_knight', 'Sir Cinder', HeroClass.knight),
      _Hero('h_mage', 'Lyra Vex', HeroClass.mage),
      _Hero('h_ranger', 'Fenn Wilde', HeroClass.ranger),
    ];
    for (final h in _heroes) {
      h.relevel(); // initialise to level 1 stats
      h.level = 1;
      h.maxHp = 200;
      h.hp = 200;
    }
    _spawnWave();
    _current = _buildSnapshot(actorIsHero: true, actorId: null, targetId: null);
  }

  final List<LevelDef> _levels;
  final int tickMs;
  final _rng = Random();
  final _controller = StreamController<CombatSnapshot>.broadcast();

  late final List<_Hero> _heroes;
  List<_Enemy> _enemies = [];

  int levelIndex = 0;
  int phaseIndex = 0;
  int waveIndex = 0;

  int _tick = 0;
  int _gridTick = 0;
  int _turn = 0;
  Timer? _timer;

  List<SlotSymbol> _grid = List.filled(9, SlotSymbol.sword);
  Set<int> _matched = {};
  OutcomeKind _outcome = OutcomeKind.hit;
  CampaignStatus _status = CampaignStatus.fighting;

  late CombatSnapshot _current;
  CombatSnapshot get current => _current;
  Stream<CombatSnapshot> get stream => _controller.stream;

  static const _lines = <List<int>>[
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
    [0, 4, 8], [2, 4, 6], // diagonals
  ];

  void start() {
    _timer ??= Timer.periodic(Duration(milliseconds: tickMs), (_) {
      final snap = _step();
      _current = snap;
      if (!_controller.isClosed) _controller.add(snap);
    });
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  // --- core step -----------------------------------------------------------

  CombatSnapshot _step() {
    _tick++;
    _status = CampaignStatus.fighting;

    // Revive fallen heroes after a short delay.
    for (final h in _heroes) {
      if (!h.alive && h.reviveIn > 0) {
        h.reviveIn--;
        if (h.reviveIn == 0) {
          h.hp = h.maxHp * 0.5;
          h.reviveIn = -1;
        }
      }
    }

    // Wave cleared -> advance progression and spawn the next group.
    if (_enemies.every((e) => !e.alive)) {
      _advance();
    }

    final heroesAlive = _heroes.any((h) => h.alive);
    final enemiesAlive = _enemies.any((e) => e.alive);

    bool actorIsHero = true;
    String? actorId;
    String? targetId;

    if (heroesAlive && enemiesAlive) {
      final enemyTurn = _tick % 4 == 0;
      if (enemyTurn) {
        (actorId, targetId) = _enemyAttack();
        actorIsHero = false;
      } else {
        (actorId, targetId) = _heroAttack();
        actorIsHero = true;
      }
    }

    return _buildSnapshot(
      actorIsHero: actorIsHero,
      actorId: actorId,
      targetId: targetId,
    );
  }

  // --- actions -------------------------------------------------------------

  (String?, String?) _heroAttack() {
    final actor = _nextAliveHero();
    if (actor == null) return (null, null);

    _grid = _rollGrid();
    final (kind, matched) = _evaluate(_grid);
    _matched = matched;
    _outcome = kind;
    _gridTick++;

    final target = _enemies.firstWhere(
      (e) => e.alive,
      orElse: () => _enemies.first,
    );

    final dmg = (22 + actor.level * 7) * _mult(kind, _grid);

    if (kind == OutcomeKind.combo) {
      for (final e in _enemies) {
        if (e.alive) {
          e.hp -= dmg;
          if (e.hp < 0) e.hp = 0;
        }
      }
    } else {
      target.hp -= dmg;
      if (target.hp < 0) target.hp = 0;
    }

    if (kind == OutcomeKind.guard) {
      final low = _lowestHero();
      if (low != null) low.hp = min(low.maxHp, low.hp + low.maxHp * 0.22);
    }

    return (actor.id, target.id);
  }

  (String?, String?) _enemyAttack() {
    final attackers = _enemies.where((e) => e.alive).toList();
    if (attackers.isEmpty) return (null, null);
    final attacker = attackers[_rng.nextInt(attackers.length)];

    final victim = _lowestHero();
    if (victim == null) return (attacker.id, null);

    final chip = (12 + levelIndex * 4) * (attacker.isBoss ? 2.4 : 1.0);
    victim.hp -= chip;
    if (victim.hp <= 0) {
      victim.hp = 0;
      victim.reviveIn = 5;
    }
    _outcome = OutcomeKind.hit;
    return (attacker.id, victim.id);
  }

  _Hero? _nextAliveHero() {
    for (var i = 0; i < _heroes.length; i++) {
      final h = _heroes[(_turn + i) % _heroes.length];
      if (h.alive) {
        _turn = (_turn + i + 1) % _heroes.length;
        return h;
      }
    }
    return null;
  }

  _Hero? _lowestHero() {
    final alive = _heroes.where((h) => h.alive).toList();
    if (alive.isEmpty) return null;
    alive.sort((a, b) => (a.hp / a.maxHp).compareTo(b.hp / b.maxHp));
    return alive.first;
  }

  // --- slot engine ---------------------------------------------------------

  List<SlotSymbol> _rollGrid() {
    const syms = SlotSymbol.values;
    final g = List<SlotSymbol>.generate(9, (_) => syms[_rng.nextInt(syms.length)]);
    // Bias toward producing a line so the mechanic reads clearly every attack.
    if (_rng.nextDouble() < 0.52) {
      final sym = syms[_rng.nextInt(syms.length)];
      final line = _lines[_rng.nextInt(_lines.length)];
      for (final c in line) {
        g[c] = sym;
      }
    }
    return g;
  }

  (OutcomeKind, Set<int>) _evaluate(List<SlotSymbol> g) {
    final matched = <int>{};
    final kinds = <OutcomeKind>[];
    for (final line in _lines) {
      final a = g[line[0]];
      if (a == g[line[1]] && a == g[line[2]]) {
        matched.addAll(line);
        kinds.add(_kindOf(a));
      }
    }
    if (kinds.isEmpty) return (OutcomeKind.hit, <int>{});
    kinds.sort((x, y) => _priority(y).compareTo(_priority(x)));
    return (kinds.first, matched);
  }

  OutcomeKind _kindOf(SlotSymbol s) => switch (s) {
        SlotSymbol.sword => OutcomeKind.power,
        SlotSymbol.fire => OutcomeKind.burn,
        SlotSymbol.bolt => OutcomeKind.crit,
        SlotSymbol.shield => OutcomeKind.guard,
        SlotSymbol.star => OutcomeKind.combo,
      };

  int _priority(OutcomeKind k) => switch (k) {
        OutcomeKind.crit => 5,
        OutcomeKind.combo => 4,
        OutcomeKind.power => 3,
        OutcomeKind.burn => 2,
        OutcomeKind.guard => 1,
        OutcomeKind.hit => 0,
      };

  double _mult(OutcomeKind k, List<SlotSymbol> g) {
    switch (k) {
      case OutcomeKind.crit:
        return 3.2;
      case OutcomeKind.combo:
        return 1.6;
      case OutcomeKind.power:
        return 2.4;
      case OutcomeKind.burn:
        return 1.8;
      case OutcomeKind.guard:
        return 0.5;
      case OutcomeKind.hit:
        final off = g
            .where((s) =>
                s == SlotSymbol.sword || s == SlotSymbol.fire || s == SlotSymbol.bolt)
            .length;
        return 0.8 + 0.08 * off;
    }
  }

  // --- progression ---------------------------------------------------------

  void _advance() {
    waveIndex++;
    final lvl = _levels[levelIndex];
    if (waveIndex >= lvl.wavesPerPhase) {
      waveIndex = 0;
      phaseIndex++;
      if (phaseIndex >= lvl.phaseCount) {
        phaseIndex = 0;
        for (final h in _heroes) {
          h.relevel();
        }
        levelIndex++;
        if (levelIndex >= _levels.length) {
          levelIndex = 0;
          _status = CampaignStatus.campaignCleared;
        } else {
          _status = CampaignStatus.levelCleared;
        }
      }
    }
    _spawnWave();
  }

  void _spawnWave() {
    final lvl = _levels[levelIndex];
    final isBossWave =
        phaseIndex == lvl.phaseCount - 1 && waveIndex == lvl.wavesPerPhase - 1;
    final baseHp = (52 + levelIndex * 20 + phaseIndex * 12 + waveIndex * 8) * lvl.hpScale;

    if (isBossWave) {
      _enemies = [
        _Enemy('e_${_tick}_boss', lvl.bossKind, baseHp * 3.6, isBoss: true),
      ];
    } else {
      _enemies = List.generate(lvl.enemyCount, (i) {
        final kind = lvl.kinds[_rng.nextInt(lvl.kinds.length)];
        final variance = 0.85 + _rng.nextDouble() * 0.4;
        return _Enemy('e_${_tick}_$i', kind, baseHp * variance);
      });
    }
  }

  // --- snapshot ------------------------------------------------------------

  CombatSnapshot _buildSnapshot({
    required bool actorIsHero,
    required String? actorId,
    required String? targetId,
  }) {
    final lvl = _levels[levelIndex];
    return CombatSnapshot(
      tick: _tick,
      levelIndex: levelIndex,
      levelName: lvl.name,
      theme: lvl.theme,
      phaseIndex: phaseIndex,
      phaseCount: lvl.phaseCount,
      waveIndex: waveIndex,
      wavesPerPhase: lvl.wavesPerPhase,
      heroes: [
        for (final h in _heroes)
          HeroState(
            id: h.id,
            name: h.name,
            klass: h.klass,
            level: h.level,
            hpFraction: (h.hp / h.maxHp).clamp(0.0, 1.0),
            alive: h.alive,
          ),
      ],
      enemies: [
        for (final e in _enemies)
          EnemyState(
            id: e.id,
            kind: e.kind,
            hpFraction: (e.hp / e.maxHp).clamp(0.0, 1.0),
            alive: e.alive,
            isBoss: e.isBoss,
          ),
      ],
      grid: List<SlotSymbol>.from(_grid),
      matched: Set<int>.from(_matched),
      gridTick: _gridTick,
      outcome: _outcome,
      actorIsHero: actorIsHero,
      actorId: actorId,
      targetId: targetId,
      status: _status,
    );
  }
}
