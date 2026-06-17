import 'package:dio/dio.dart';

import '../network/api_client.dart';

/// Dumb client model: a snapshot computed entirely on the server. The client
/// never simulates combat — it only paints what the server returns.

class ServerHero {
  ServerHero({
    required this.id,
    required this.name,
    required this.archetype,
    required this.level,
    required this.hpFraction,
    required this.alive,
    required this.acting,
  });

  final String id;
  final String name;
  final String archetype;
  final int level;
  final double hpFraction;
  final bool alive;
  final bool acting;

  factory ServerHero.fromJson(Map<String, dynamic> j) => ServerHero(
        id: j['id'] as String,
        name: j['name'] as String,
        archetype: j['archetype'] as String,
        level: (j['level'] as num).toInt(),
        hpFraction: (j['hpFraction'] as num).toDouble(),
        alive: j['alive'] as bool,
        acting: j['acting'] as bool,
      );
}

class ServerEnemy {
  ServerEnemy({
    required this.id,
    required this.kind,
    required this.hpFraction,
    required this.alive,
    required this.isBoss,
    required this.hit,
  });

  final String id;
  final String kind;
  final double hpFraction;
  final bool alive;
  final bool isBoss;
  final bool hit;

  factory ServerEnemy.fromJson(Map<String, dynamic> j) => ServerEnemy(
        id: j['id'] as String,
        kind: j['kind'] as String,
        hpFraction: (j['hpFraction'] as num).toDouble(),
        alive: j['alive'] as bool,
        isBoss: j['isBoss'] as bool,
        hit: j['hit'] as bool,
      );
}

class ServerReel {
  ServerReel({
    required this.items,
    required this.combo,
    required this.multiplier,
    required this.actorIsHero,
  });

  final List<String> items;
  final String combo;
  final double multiplier;
  final bool actorIsHero;

  factory ServerReel.fromJson(Map<String, dynamic> j) => ServerReel(
        items: (j['items'] as List).map((e) => e as String).toList(),
        combo: j['combo'] as String,
        multiplier: (j['multiplier'] as num).toDouble(),
        actorIsHero: j['actorIsHero'] as bool,
      );
}

class ServerSnapshot {
  ServerSnapshot({
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
    required this.reel,
    required this.outcome,
    required this.status,
  });

  final int tick;
  final int levelIndex;
  final String levelName;
  final String theme;
  final int phaseIndex;
  final int phaseCount;
  final int waveIndex;
  final int wavesPerPhase;
  final List<ServerHero> heroes;
  final List<ServerEnemy> enemies;
  final ServerReel reel;
  final String outcome;
  final String status;

  factory ServerSnapshot.fromJson(Map<String, dynamic> j) => ServerSnapshot(
        tick: (j['tick'] as num).toInt(),
        levelIndex: (j['levelIndex'] as num).toInt(),
        levelName: j['levelName'] as String,
        theme: j['theme'] as String,
        phaseIndex: (j['phaseIndex'] as num).toInt(),
        phaseCount: (j['phaseCount'] as num).toInt(),
        waveIndex: (j['waveIndex'] as num).toInt(),
        wavesPerPhase: (j['wavesPerPhase'] as num).toInt(),
        heroes: (j['heroes'] as List)
            .map((e) => ServerHero.fromJson(e as Map<String, dynamic>))
            .toList(),
        enemies: (j['enemies'] as List)
            .map((e) => ServerEnemy.fromJson(e as Map<String, dynamic>))
            .toList(),
        reel: ServerReel.fromJson(j['reel'] as Map<String, dynamic>),
        outcome: j['outcome'] as String,
        status: j['status'] as String,
      );
}

/// Reads the server-authoritative game state. The server advances combat on
/// every read (and 24/7 via its Hangfire job); the client just polls.
class GameApi {
  GameApi() : _dio = buildApiClient();

  final Dio _dio;

  Future<ServerSnapshot> fetchState() async {
    final res = await _dio.get<Map<String, dynamic>>('/game/state');
    return ServerSnapshot.fromJson(res.data!);
  }
}
