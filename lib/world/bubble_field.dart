import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// One luminous mote drifting at the edge of the play world.
///
/// The public shape is retained for callers that construct their own field.
/// Positions and drift are fractions of the available width; radius remains
/// a logical-pixel size before the painter applies its small tablet scale.
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

  final double startX;
  final double drift;
  final double radius;
  final double speed;
  final double offset;
  final double opacity;
  final Color tint;
}

/// Paints all ambient motes in one pass.
///
/// The glow is built from a few translucent circles rather than a blur filter.
/// That keeps the field inexpensive while other parts of the scene animate.
class BubbleFieldPainter extends CustomPainter {
  const BubbleFieldPainter({required this.bubbles, required this.t});

  final List<DriftingBubble> bubbles;

  /// Progress through the loop, from 0 to 1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final double sizeScale = (min(size.width, size.height) / 390).clamp(
      0.82,
      1.35,
    );
    final Paint paint = Paint()..isAntiAlias = true;

    for (final DriftingBubble bubble in bubbles) {
      final double progress = (t * bubble.speed + bubble.offset) % 1;
      final double y = size.height * (1.10 - (progress * 1.20));
      final double sway =
          sin((progress * 2 * pi) + (bubble.offset * 2 * pi)) * bubble.drift;
      final double x = (bubble.startX + sway) * size.width;
      final double edgeFade = sin(progress * pi).clamp(0.0, 1.0);
      final double alpha = bubble.opacity * edgeFade;

      if (alpha <= 0.015) continue;

      final Offset centre = Offset(x, y);
      final double radius = bubble.radius * sizeScale;

      // A broad colored aura, then a restrained translucent core.
      paint
        ..style = PaintingStyle.fill
        ..color = bubble.tint.withValues(alpha: alpha * 0.16);
      canvas.drawCircle(centre, radius * 1.85, paint);

      paint.color = bubble.tint.withValues(alpha: alpha * 0.34);
      canvas.drawCircle(centre, radius, paint);

      // A fine white rim and pinprick catchlight make this read as light, not
      // another answer bubble. Motes remain small and live near the margins.
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, radius * 0.08)
        ..color = AppColors.white.withValues(alpha: alpha * 0.42);
      canvas.drawCircle(centre, radius * 0.92, paint);

      paint
        ..style = PaintingStyle.fill
        ..color = AppColors.white.withValues(alpha: alpha * 0.72);
      canvas.drawCircle(
        centre.translate(-radius * 0.30, -radius * 0.32),
        max(0.9, radius * 0.18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BubbleFieldPainter oldDelegate) {
    return oldDelegate.t != t || !identical(oldDelegate.bubbles, bubbles);
  }
}

/// Low-cost ambient lights drifting around the neutral play clearing.
class BubbleField extends StatefulWidget {
  const BubbleField({super.key, this.count = 24});

  /// Maximum number of motes. The actual count responds to screen area and
  /// short landscape heights, so smaller devices do less work.
  final int count;

  @override
  State<BubbleField> createState() => _BubbleFieldState();
}

class _BubbleFieldState extends State<BubbleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<DriftingBubble> _bubbles;
  bool _reduceMotion = false;

  static const List<Color> _tints = <Color>[
    AppColors.booBlue,
    AppColors.bubbleMint,
    AppColors.bubblePink,
    AppColors.bubblePurple,
    AppColors.sunnyPop,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 34),
    );
    _buildMotes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion && _controller.isAnimating) return;

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BubbleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) _buildMotes();
  }

  void _buildMotes() {
    final Random random = Random(7);
    final int count = max(0, widget.count);

    _bubbles = List<DriftingBubble>.generate(count, (int index) {
      final bool leftEdge = index.isEven;

      return DriftingBubble(
        // Keep colored ambience at the margins. The educational choices stay
        // over the neutral clearing and cannot be confused with these motes.
        startX: leftEdge
            ? 0.015 + (random.nextDouble() * 0.12)
            : 0.865 + (random.nextDouble() * 0.12),
        drift: 0.008 + (random.nextDouble() * 0.025),
        radius: 3.5 + (random.nextDouble() * 7.5),
        speed: 0.48 + (random.nextDouble() * 0.52),
        offset: random.nextDouble(),
        opacity: 0.34 + (random.nextDouble() * 0.30),
        tint: _tints[index % _tints.length],
      );
    }, growable: false);
  }

  int _responsiveCount(Size size) {
    if (_bubbles.isEmpty) return 0;

    int wanted = ((size.width * size.height) / 23000).round();
    if (size.height < 500) wanted -= 4;
    wanted = wanted.clamp(7, 24);
    return min(wanted, _bubbles.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final List<DriftingBubble> visible = _bubbles
            .take(_responsiveCount(size))
            .toList(growable: false);

        if (_reduceMotion) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: BubbleFieldPainter(bubbles: visible, t: 0.31),
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
                  bubbles: visible,
                  t: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        );
      },
    );
  }
}
