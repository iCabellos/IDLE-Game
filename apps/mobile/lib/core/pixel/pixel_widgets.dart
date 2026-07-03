import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Retro text helper: chunky monospace caps, the "bitmap font" of the app.
class PixelText extends StatelessWidget {
  const PixelText(
    this.text, {
    super.key,
    this.size = 13,
    this.color = AppColors.text,
    this.shadow = true,
    this.align = TextAlign.left,
    this.maxLines,
  });

  final String text;
  final double size;
  final Color color;
  final bool shadow;
  final TextAlign align;
  final int? maxLines;

  static TextStyle style({
    double size = 13,
    Color color = AppColors.text,
    bool shadow = true,
  }) =>
      TextStyle(
        // Bundled bitmap font (assets/fonts, OFL) — glyphs are designed on
        // an 8px grid, so it stays crisp at multiples of 8.
        fontFamily: 'PressStart2P',
        fontSize: size * 0.85,
        height: 1.5,
        color: color,
        shadows: shadow
            ? const [Shadow(offset: Offset(1.5, 1.5), color: Color(0xFF0B1220))]
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: style(size: size, color: color, shadow: shadow),
    );
  }
}

/// Classic RPG dialog panel: hard black outline, bright bevel, notched
/// corners. Everything is square — no rounded corners in a pixel world.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.fill = AppColors.surface,
    this.border = AppColors.muted,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color fill;
  final Color border;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PanelPainter(fill: fill, border: border),
      child: Padding(
        padding: padding.add(const EdgeInsets.all(6)),
        child: child,
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  static const _u = 3.0; // pixel unit

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width;
    final h = size.height;

    // Outline (with notched corners: skip the corner unit squares).
    paint.color = const Color(0xFF0B1220);
    canvas.drawRect(Rect.fromLTWH(_u, 0, w - 2 * _u, h), paint);
    canvas.drawRect(Rect.fromLTWH(0, _u, w, h - 2 * _u), paint);

    // Border bevel.
    paint.color = border;
    canvas.drawRect(Rect.fromLTWH(2 * _u, _u, w - 4 * _u, h - 2 * _u), paint);
    canvas.drawRect(Rect.fromLTWH(_u, 2 * _u, w - 2 * _u, h - 4 * _u), paint);

    // Fill.
    paint.color = fill;
    canvas.drawRect(
        Rect.fromLTWH(2 * _u, 2 * _u, w - 4 * _u, h - 4 * _u), paint);

    // Top-left highlight / bottom-right shade, one unit thick.
    paint.color = Colors.white.withValues(alpha: 0.10);
    canvas.drawRect(Rect.fromLTWH(2 * _u, 2 * _u, w - 4 * _u, _u), paint);
    paint.color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRect(
        Rect.fromLTWH(2 * _u, h - 3 * _u, w - 4 * _u, _u), paint);
  }

  @override
  bool shouldRepaint(_PanelPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}

/// Chunky press-down button with a hard drop shadow. No gradients, no
/// rounded corners — just like the cartridge era intended.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.blue,
    this.textColor = AppColors.text,
    this.icon,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? icon;
  final double height;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final down = _pressed && enabled;
    final fill = enabled ? widget.color : AppColors.surface;
    final label = enabled ? widget.textColor : AppColors.muted;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: SizedBox(
        height: widget.height + 4,
        child: Stack(
          children: [
            // Hard shadow block.
            Positioned.fill(
              top: 4,
              child: Container(color: const Color(0xFF0B1220)),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: down ? 4 : 0,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  border: Border.all(color: const Color(0xFF0B1220), width: 3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: PixelText(
                        widget.label.toUpperCase(),
                        size: 14,
                        color: label,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented progress bar built from discrete pixel cells.
class PixelProgressBar extends StatelessWidget {
  const PixelProgressBar({
    super.key,
    required this.filled,
    required this.total,
    this.color = AppColors.success,
    this.height = 14,
  });

  final int filled;
  final int total;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        border: Border.all(color: AppColors.muted, width: 1.5),
      ),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                color: i < filled
                    ? color
                    : AppColors.surface.withValues(alpha: 0.6),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

/// Full-screen dungeon backdrop: brick courses and a sprinkle of star
/// pixels, all painted — no images.
class PixelBackground extends StatelessWidget {
  const PixelBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: CustomPaint(
        painter: _DungeonPainter(),
        child: child,
      ),
    );
  }
}

class _DungeonPainter extends CustomPainter {
  static const _brick = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;

    // Faint brick mortar lines.
    paint.color = Colors.white.withValues(alpha: 0.03);
    for (var y = 0.0; y < size.height; y += _brick) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
      final offset = ((y / _brick).floor() % 2) * _brick;
      for (var x = offset; x < size.width; x += _brick * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y, 2, _brick), paint);
      }
    }

    // Deterministic star pixels (torch dust).
    paint.color = AppColors.accent.withValues(alpha: 0.20);
    var seed = 41;
    for (var i = 0; i < 40; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      final x = (seed % 997) / 997 * size.width;
      final y = ((seed >> 8) % 991) / 991 * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 3, 3), paint);
    }
  }

  @override
  bool shouldRepaint(_DungeonPainter oldDelegate) => false;
}

/// Small square chip with a status color, used for readable state badges.
class PixelBadge extends StatelessWidget {
  const PixelBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
      ),
      child: PixelText(label.toUpperCase(), size: 10, color: color),
    );
  }
}
