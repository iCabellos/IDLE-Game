import 'package:flutter/widgets.dart';

/// A hand-drawn pixel-art sprite encoded as text rows.
///
/// Every character of every row is one pixel; `.` (and space) are
/// transparent, any other character is looked up in [palette]. All art in
/// the app is authored this way — no image assets, everything is rendered
/// crisp at any scale by [PixelSpritePainter].
class PixelSprite {
  const PixelSprite({required this.rows, required this.palette});

  final List<String> rows;
  final Map<String, Color> palette;

  int get height => rows.length;
  int get width => rows.isEmpty ? 0 : rows.first.length;
}

/// Paints a [PixelSprite] scaled to fit its canvas.
///
/// Pixels are snapped to a uniform scale (integer when the target is large
/// enough) and drawn without anti-aliasing so edges stay razor sharp.
/// Horizontal runs of the same color collapse into single rects.
class PixelSpritePainter extends CustomPainter {
  PixelSpritePainter(this.sprite, {this.flipX = false});

  final PixelSprite sprite;
  final bool flipX;

  @override
  void paint(Canvas canvas, Size size) {
    final w = sprite.width;
    final h = sprite.height;
    if (w == 0 || h == 0) {
      return;
    }

    var scale = size.width / w < size.height / h ? size.width / w : size.height / h;
    if (scale >= 1) {
      scale = scale.floorToDouble();
    }

    final dx = (size.width - w * scale) / 2;
    final dy = (size.height - h * scale) / 2;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < h; y++) {
      final row = sprite.rows[y];
      var x = 0;
      while (x < w) {
        final ch = row[x];
        if (ch == '.' || ch == ' ') {
          x++;
          continue;
        }

        var run = 1;
        while (x + run < w && row[x + run] == ch) {
          run++;
        }

        final color = sprite.palette[ch];
        if (color != null) {
          paint.color = color;
          final px = flipX ? w - x - run : x;
          canvas.drawRect(
            Rect.fromLTWH(dx + px * scale, dy + y * scale, run * scale, scale),
            paint,
          );
        }

        x += run;
      }
    }
  }

  @override
  bool shouldRepaint(PixelSpritePainter oldDelegate) =>
      oldDelegate.sprite != sprite || oldDelegate.flipX != flipX;
}

/// Convenience widget: renders a sprite in a square (or explicit) box.
class PixelArt extends StatelessWidget {
  const PixelArt(this.sprite, {super.key, this.size = 48, this.flipX = false});

  final PixelSprite sprite;
  final double size;
  final bool flipX;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: PixelSpritePainter(sprite, flipX: flipX),
    );
  }
}
