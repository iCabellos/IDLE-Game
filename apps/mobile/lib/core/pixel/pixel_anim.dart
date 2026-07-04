import 'dart:async';

import 'package:flutter/widgets.dart';

import 'pixel_sprite.dart';

/// Frame-based sprite animation, the way cartridge games did it: a small
/// set of hand-drawn frames swapped at a fixed step rate. No tweens, no
/// easing — discrete steps read as intentional and are easy on the eyes.
class AnimatedPixelArt extends StatefulWidget {
  const AnimatedPixelArt(
    this.frames, {
    super.key,
    this.size = 48,
    this.stepMs = 600,
    this.flipX = false,
    this.startFrame = 0,
  });

  final List<PixelSprite> frames;
  final double size;

  /// Milliseconds per frame. Ambient idles use slow steps (500-700ms).
  final int stepMs;

  final bool flipX;

  /// Stagger starting frame so a row of sprites doesn't move in lockstep.
  final int startFrame;

  @override
  State<AnimatedPixelArt> createState() => _AnimatedPixelArtState();
}

class _AnimatedPixelArtState extends State<AnimatedPixelArt> {
  Timer? _timer;
  late int _frame = widget.startFrame;

  @override
  void initState() {
    super.initState();
    if (widget.frames.length > 1) {
      _timer = Timer.periodic(Duration(milliseconds: widget.stepMs), (_) {
        if (mounted) {
          setState(() => _frame = (_frame + 1) % widget.frames.length);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PixelArt(
      widget.frames[_frame % widget.frames.length],
      size: widget.size,
      flipX: widget.flipX,
    );
  }
}

/// Hard on/off blink (classic "PRESS START"): fully visible or fully
/// hidden, never a fatiguing alpha pulse.
class PixelBlink extends StatefulWidget {
  const PixelBlink({super.key, required this.child, this.onMs = 800, this.offMs = 400});

  final Widget child;
  final int onMs;
  final int offMs;

  @override
  State<PixelBlink> createState() => _PixelBlinkState();
}

class _PixelBlinkState extends State<PixelBlink> {
  Timer? _timer;
  bool _on = true;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer = Timer(Duration(milliseconds: _on ? widget.onMs : widget.offMs), () {
      if (!mounted) return;
      setState(() => _on = !_on);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _on,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: widget.child,
    );
  }
}

/// One-shot burst of gold spark pixels flying outward on fixed diagonal
/// paths — fired on claims and lucky finds. Runs ~300ms and stops; it never
/// loops on its own.
class SparkBurst extends StatefulWidget {
  const SparkBurst({super.key, required this.trigger, this.size = 60});

  /// Increment to fire the burst once; equal values keep it dormant.
  final int trigger;
  final double size;

  @override
  State<SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<SparkBurst>
    with SingleTickerProviderStateMixin {
  static const _steps = 4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(SparkBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final step = _controller.isAnimating
            ? (_controller.value * _steps).floor().clamp(0, _steps - 1)
            : -1;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _SparkPainter(step),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.step);

  /// -1 = idle (paints nothing); 0..3 = expanding spark ring.
  final int step;

  // Eight fixed diagonal/cardinal directions — deterministic, hand-placed.
  static const _dirs = [
    Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1),
    Offset(0.7, 0.7), Offset(-0.7, 0.7), Offset(0.7, -0.7), Offset(-0.7, -0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (step < 0) {
      return;
    }

    final paint = Paint()..isAntiAlias = false;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.14 * (step + 1);
    final px = size.width * 0.06;

    // Two restrained colors only: gold sparks, white core on early steps.
    paint.color = step < 2 ? const Color(0xFFE2E8F0) : const Color(0xFFFFD700);
    for (final dir in _dirs) {
      final p = center + dir * radius;
      canvas.drawRect(Rect.fromLTWH(p.dx - px / 2, p.dy - px / 2, px, px), paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.step != step;
}
