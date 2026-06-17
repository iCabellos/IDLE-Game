import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game.dart';

/// Procedurally painted pixel-art stage backdrops — one palette per theme.
/// Drawn on a coarse virtual grid so everything stays blocky and crisp.
class StageBackground extends StatelessWidget {
  const StageBackground({super.key, required this.theme});

  final BgTheme theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BgPainter(theme),
      size: Size.infinite,
    );
  }
}

class _Palette {
  const _Palette({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.near,
    required this.ground,
    required this.groundDark,
    required this.accent,
  });

  final Color skyTop, skyBottom, far, near, ground, groundDark, accent;
}

_Palette _paletteFor(BgTheme t) {
  switch (t) {
    case BgTheme.meadow:
      return const _Palette(
        skyTop: Color(0xFF2C5F8A),
        skyBottom: Color(0xFF7FB4D6),
        far: Color(0xFF3E7E5A),
        near: Color(0xFF2E6347),
        ground: Color(0xFF4A8C3F),
        groundDark: Color(0xFF356B2D),
        accent: Color(0xFFBfe89A),
      );
    case BgTheme.cavern:
      return const _Palette(
        skyTop: Color(0xFF14121E),
        skyBottom: Color(0xFF241F33),
        far: Color(0xFF2C2740),
        near: Color(0xFF1E1A2C),
        ground: Color(0xFF332C44),
        groundDark: Color(0xFF221D30),
        accent: Color(0xFF6E5BA6),
      );
    case BgTheme.forest:
      return const _Palette(
        skyTop: Color(0xFF243B4A),
        skyBottom: Color(0xFF466B6B),
        far: Color(0xFF1F4D3A),
        near: Color(0xFF15392B),
        ground: Color(0xFF2A5C3E),
        groundDark: Color(0xFF1C3F2B),
        accent: Color(0xFF6FB04A),
      );
    case BgTheme.crypt:
      return const _Palette(
        skyTop: Color(0xFF161B22),
        skyBottom: Color(0xFF2A323D),
        far: Color(0xFF313A47),
        near: Color(0xFF222A34),
        ground: Color(0xFF39424F),
        groundDark: Color(0xFF262D38),
        accent: Color(0xFF5FB0A6),
      );
    case BgTheme.volcano:
      return const _Palette(
        skyTop: Color(0xFF2A1018),
        skyBottom: Color(0xFF6E2A1E),
        far: Color(0xFF491A1A),
        near: Color(0xFF301212),
        ground: Color(0xFF3A1414),
        groundDark: Color(0xFF240C0C),
        accent: Color(0xFFFB923C),
      );
    case BgTheme.citadel:
      return const _Palette(
        skyTop: Color(0xFF1E2740),
        skyBottom: Color(0xFF3C4E7A),
        far: Color(0xFF2E3A5C),
        near: Color(0xFF222B45),
        ground: Color(0xFF34406A),
        groundDark: Color(0xFF222A47),
        accent: Color(0xFF8FB3D9),
      );
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.theme);

  final BgTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _paletteFor(theme);
    final rng = Random(theme.index * 9973 + 7);
    final paint = Paint()..isAntiAlias = false;

    const cols = 48;
    final rows = (cols * size.height / size.width).round().clamp(20, 80);
    final cw = size.width / cols;
    final ch = size.height / rows;

    void cell(int x, int y, Color c, {int w = 1, int h = 1}) {
      paint.color = c;
      canvas.drawRect(
        Rect.fromLTWH(x * cw, y * ch, cw * w + 0.6, ch * h + 0.6),
        paint,
      );
    }

    // Sky: vertical gradient as horizontal bands.
    for (var y = 0; y < rows; y++) {
      final t = y / rows;
      final c = Color.lerp(p.skyTop, p.skyBottom, t)!;
      cell(0, y, c, w: cols);
    }

    final groundTop = (rows * 0.74).round();

    // Far silhouette ridge (mountains / pillars / spires).
    final fy = groundTop - 4;
    for (var x = 0; x < cols; x++) {
      final h = (sin(x * 0.5) * 2 + rng.nextInt(3)).round();
      for (var y = (fy - h).clamp(0, rows); y < groundTop; y++) {
        cell(x, y, p.far);
      }
    }

    // Near silhouette (taller, darker).
    for (var x = 0; x < cols; x += 1) {
      final h = (sin(x * 0.9 + 1.5) * 3 + 4 + rng.nextInt(2)).round();
      for (var y = (groundTop - h).clamp(0, rows); y < groundTop; y++) {
        cell(x, y, p.near);
      }
    }

    // Ground.
    for (var y = groundTop; y < rows; y++) {
      cell(0, y, y == groundTop ? p.ground : p.groundDark, w: cols);
    }
    // Ground texture speckles.
    for (var i = 0; i < cols * 2; i++) {
      final x = rng.nextInt(cols);
      final y = groundTop + 1 + rng.nextInt((rows - groundTop - 1).clamp(1, rows));
      cell(x, y, p.ground.withValues(alpha: 0.5));
    }

    // Theme accent dots (stars / embers / fireflies) in the sky.
    for (var i = 0; i < 26; i++) {
      final x = rng.nextInt(cols);
      final y = rng.nextInt(groundTop - 2);
      cell(x, y, p.accent.withValues(alpha: 0.55));
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.theme != theme;
}
