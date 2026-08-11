import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// One drifting bubble in the background.
class DriftingBubble {
  DriftingBubble({
    required this.startX,
    required this.drift,
    required this.radius,
    required this.speed,
    required this.offset,
    required this.opacity,
    required this.tint,
  });

  /// Horizontal position as a share of the width.
  final double startX;

  /// How far it sways left and right on the way up.
  final double drift;

  final double radius;

  /// How many times it crosses the screen per full cycle.
  final double speed;

  /// Where it starts in its journey, so they do not all rise together.
  final double offset;

  final double opacity;
  final Color tint;
}

/// The soft bubbles floating through the world behind everything else.
///
/// All of them are drawn by a single painter driven by a single controller.
/// The old home screen built fifteen separate positioned widgets and rebuilt
/// the whole stack every frame, which is exactly what to avoid here.
class BubbleFieldPainter extends CustomPainter {
  const BubbleFieldPainter({required this.bubbles, required this.t});

  final List<DriftingBubble> bubbles;

  /// Progress through the loop, 0 to 1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (final DriftingBubble bubble in bubbles) {
      // Rise from just below the screen to just above it.
      final double progress = (t * bubble.speed + bubble.offset) % 1.0;
      final double y = size.height * (1.15 - (progress * 1.3));

      final double sway =
          sin((progress * 2 * pi) + bubble.offset * 6) * bubble.drift;
      final double x = (bubble.startX + sway) * size.width;

      // Fade in and out at the ends so nothing pops into existence.
      final double edgeFade = sin(progress * pi).clamp(0.0, 1.0);
      final double alpha = bubble.opacity * edgeFade;

      if (alpha <= 0.01) continue;

      final Offset centre = Offset(x, y);

      paint
        ..color = bubble.tint.withValues(alpha: alpha * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, bubble.radius * 0.5);
      canvas.drawCircle(centre, bubble.radius, paint);

      paint
        ..color = AppColors.white.withValues(alpha: alpha * 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, bubble.radius * 0.22);
      canvas.drawCircle(
        centre.translate(-bubble.radius * 0.3, -bubble.radius * 0.32),
        bubble.radius * 0.26,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BubbleFieldPainter old) => old.t != t;
}

/// Background bubbles drifting slowly upward.
class BubbleField extends StatefulWidget {
  const BubbleField({super.key, this.count = 24});

  /// Kept small on purpose. This layer must never cost much.
  final int count;

  @override
  State<BubbleField> createState() => _BubbleFieldState();
}

class _BubbleFieldState extends State<BubbleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<DriftingBubble> _bubbles;

  static const List<Color> _tints = <Color>[
    AppColors.bubbleSky,
    AppColors.bubbleMint,
    AppColors.bubblePink,
    AppColors.bubblePurple,
    AppColors.sunnyPop,
  ];

  @override
  void initState() {
    super.initState();

    final Random random = Random(7);
    _bubbles = List<DriftingBubble>.generate(widget.count, (int i) {
      return DriftingBubble(
        startX: 0.04 + (random.nextDouble() * 0.92),
        drift: 0.02 + (random.nextDouble() * 0.06),
        radius: 8 + (random.nextDouble() * 26),
        speed: 0.55 + (random.nextDouble() * 0.7),
        offset: random.nextDouble(),
        opacity: 0.18 + (random.nextDouble() * 0.30),
        tint: _tints[i % _tints.length],
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect a device that has been told to keep motion to a minimum.
    if (MediaQuery.disableAnimationsOf(context)) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: BubbleFieldPainter(bubbles: _bubbles, t: 0.25),
          size: Size.infinite,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: BubbleFieldPainter(
              bubbles: _bubbles,
              t: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
