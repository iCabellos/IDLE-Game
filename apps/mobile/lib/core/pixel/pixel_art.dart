import 'package:flutter/material.dart';

/// A hand-authored pixel-art image: a list of rows where each character maps
/// to a colour in [palette]. Any character missing from the palette (e.g. '.')
/// is treated as transparent. Rows may be ragged — width is the longest row.
@immutable
class PixelArt {
  const PixelArt({required this.rows, required this.palette});

  final List<String> rows;
  final Map<String, Color> palette;

  int get cols =>
      rows.fold(0, (m, r) => r.length > m ? r.length : m);

  int get height => rows.length;
}

class _PixelPainter extends CustomPainter {
  _PixelPainter({
    required this.art,
    required this.flipX,
    required this.flash,
    required this.desaturate,
    required this.recolor,
  });

  final PixelArt art;
  final bool flipX;
  final double flash; // 0..1 white overlay on opaque pixels (hit flash)
  final bool desaturate; // render as a grey silhouette (locked heroes)
  final Map<String, Color>? recolor; // per-char overrides (rarity accents)

  @override
  void paint(Canvas canvas, Size size) {
    final cols = art.cols;
    final rowsN = art.height;
    if (cols == 0 || rowsN == 0) return;

    final pw = size.width / cols;
    final ph = size.height / rowsN;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < rowsN; y++) {
      final row = art.rows[y];
      for (var x = 0; x < cols; x++) {
        final ch = x < row.length ? row[x] : ' ';
        final base = recolor?[ch] ?? art.palette[ch];
        if (base == null) continue;
        var color = base;
        if (desaturate) {
          final lum =
              (0.299 * base.r + 0.587 * base.g + 0.114 * base.b) * 255.0;
          final g = (lum * 0.55 + 28).clamp(0, 255).toInt();
          color = Color.fromARGB(255, g, g, g);
        }
        if (flash > 0) color = Color.lerp(color, Colors.white, flash)!;
        final dx = flipX ? (cols - 1 - x) : x;
        paint.color = color;
        // +0.6 to overlap neighbouring cells and avoid hairline seams.
        canvas.drawRect(
          Rect.fromLTWH(dx * pw, y * ph, pw + 0.6, ph + 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) =>
      old.art != art ||
      old.flipX != flipX ||
      old.flash != flash ||
      old.desaturate != desaturate ||
      old.recolor != recolor;
}

/// Renders a [PixelArt] at a fixed [height], preserving its pixel aspect ratio.
class PixelSprite extends StatelessWidget {
  const PixelSprite({
    super.key,
    required this.art,
    required this.height,
    this.flipX = false,
    this.flash = 0,
    this.desaturate = false,
    this.recolor,
  });

  final PixelArt art;
  final double height;
  final bool flipX;
  final double flash;
  final bool desaturate;
  final Map<String, Color>? recolor;

  @override
  Widget build(BuildContext context) {
    final aspect = art.cols == 0 ? 1.0 : art.cols / art.height;
    return SizedBox(
      height: height,
      width: height * aspect,
      child: CustomPaint(
        painter: _PixelPainter(
          art: art,
          flipX: flipX,
          flash: flash,
          desaturate: desaturate,
          recolor: recolor,
        ),
      ),
    );
  }
}
