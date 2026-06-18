import 'dart:async';

import 'package:flutter/foundation.dart';

import 'server_game.dart';

/// App-wide, always-on combat feed. A single poller lives here so the combat
/// panel stays alive and never restarts when navigating between screens — the
/// same panel is what gets exported to the home-screen widget.
class CombatService {
  CombatService._();

  static final CombatService instance = CombatService._();

  final GameApi _api = GameApi();

  /// Latest server snapshot (null until the first successful poll).
  final ValueNotifier<ServerSnapshot?> snapshot = ValueNotifier<ServerSnapshot?>(null);

  /// Whether the last poll reached the server.
  final ValueNotifier<bool> online = ValueNotifier<bool>(false);

  Timer? _timer;

  /// Idempotent: starts the polling loop once for the whole app lifetime.
  void start({Duration interval = const Duration(milliseconds: 1500)}) {
    if (_timer != null) return;
    _poll();
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final s = await _api.fetchState();
      snapshot.value = s;
      online.value = true;
    } catch (_) {
      online.value = false;
    }
  }
}
