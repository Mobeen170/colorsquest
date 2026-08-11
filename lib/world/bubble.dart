import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Builds the outline of a soap bubble.
///
/// A real bubble is never a perfect circle: the film flexes. The radius is
/// nudged in and out by a couple of slow waves so every bubble breathes
/// slightly and no two look alike.
Path buildBubblePath({
  required Offset center,
  required double radius,
  double wobble = 0,
  double phase = 0,
}) {
  final Path path = Path();
  const int steps = 56;

  for (int i = 0; i <= steps; i++) {
    final double t = (i / steps) * 2 * pi;

    final double flex =
        (0.045 * sin(3 * t + phase)) + (0.028 * sin(5 * t - phase * 1.3));
    final double r = radius * (1 + (wobble * flex));

    final Offset point = Offset(
      center.dx + (r * cos(t)),
      center.dy + (r * sin(t)),
    );

    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }

  path.close();
  return path;
}

/// Draws one glossy soap bubble.
///
/// Every touchable thing in Coloriboo is one of these. They are deliberately
/// glossy and sharp so they stand off the soft painterly paper: that contrast
/// is how a child knows what can be touched without needing to read anything.
class BubblePainter extends CustomPainter {
  const BubblePainter({
    required this.color,
    this.wobble = 0.35,
    this.phase = 0,
    this.squash = 1,
    this.opacity = 1,
    this.glow = 0,
    this.showShadow = true,
  });

  /// The colour a child is learning.
  final Color color;

  /// How much the film flexes, 0 is a perfect circle.
  final double wobble;

  /// Where in its wobble the bubble currently is.
  final double phase;

  /// Vertical squash. Below 1 is squat, above 1 is tall.
  final double squash;

  final double opacity;

  /// Extra halo, used to nudge a child towards the right answer.
  final double glow;

  final bool showShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (min(size.width, size.height) / 2) * 0.94;

    if (radius <= 0) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1 / squash, squash);
    canvas.translate(-center.dx, -center.dy);

    final Path body = buildBubblePath(
      center: center,
      radius: radius,
      wobble: wobble,
      phase: phase,
    );

    if (glow > 0) _paintGlow(canvas, center, radius);
    if (showShadow) _paintContactShadow(canvas, center, radius);

    _paintBody(canvas, body, center, radius);
    _paintIridescentRim(canvas, body, center, radius);
    _paintHighlights(canvas, center, radius);

    canvas.restore();
  }

  /// Soft halo behind the bubble, used as a gentle hint.
  void _paintGlow(Canvas canvas, Offset center, double radius) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.32 * glow * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35);

    canvas.drawCircle(center, radius * 1.06, paint);
  }

  /// Where the bubble meets the paper.
  void _paintContactShadow(Canvas canvas, Offset center, double radius) {
    final Paint paint = Paint()
      ..color = AppColors.paperShadow.withValues(alpha: 0.34 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(radius * 0.06, radius * 0.30),
        width: radius * 1.66,
        height: radius * 0.62,
      ),
      paint,
    );
  }

  /// The coloured film itself.
  void _paintBody(Canvas canvas, Path body, Offset center, double radius) {
    final HSLColor hsl = HSLColor.fromColor(color);

    // Light falls from the upper left, so that side is lifted and the far
    // side is deepened. This is what makes a flat circle read as a sphere.
    final Color lit = hsl
        .withLightness((hsl.lightness + 0.26).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.82).clamp(0.0, 1.0))
        .toColor();

    final Color deep = hsl
        .withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0))
        .toColor();

    final Paint paint = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-radius * 0.34, -radius * 0.38),
        radius * 1.5,
        <Color>[
          lit.withValues(alpha: opacity),
          color.withValues(alpha: opacity),
          deep.withValues(alpha: opacity),
        ],
        <double>[0.0, 0.52, 1.0],
      );

    canvas.drawPath(body, paint);
  }

  /// The rainbow edge of a soap film.
  void _paintIridescentRim(
    Canvas canvas,
    Path body,
    Offset center,
    double radius,
  ) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.075
      ..shader = ui.Gradient.sweep(
        center,
        <Color>[
          AppColors.bubblePink.withValues(alpha: 0.85 * opacity),
          AppColors.sunnyPop.withValues(alpha: 0.80 * opacity),
          AppColors.bubbleMint.withValues(alpha: 0.85 * opacity),
          AppColors.bubbleSky.withValues(alpha: 0.90 * opacity),
          AppColors.bubblePurple.withValues(alpha: 0.75 * opacity),
          AppColors.bubblePink.withValues(alpha: 0.85 * opacity),
        ],
        <double>[0.0, 0.2, 0.42, 0.62, 0.82, 1.0],
      );

    canvas.drawPath(body, paint);

    // A very light inner line keeps pale bubbles, especially white, from
    // disappearing into the cream paper.
    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02
      ..color = AppColors.white.withValues(alpha: 0.55 * opacity);

    canvas.drawPath(body, inner);
  }

  /// The two catchlights that sell the gloss.
  void _paintHighlights(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx - (radius * 0.36), center.dy - (radius * 0.42));
    canvas.rotate(-0.55);

    final Paint main = Paint()
      ..color = AppColors.white.withValues(alpha: 0.92 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.045);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.62,
        height: radius * 0.34,
      ),
      main,
    );
    canvas.restore();

    // Smaller bounce light on the opposite side.
    final Paint bounce = Paint()
      ..color = AppColors.white.withValues(alpha: 0.42 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.08);

    canvas.drawCircle(
      center.translate(radius * 0.38, radius * 0.40),
      radius * 0.17,
      bounce,
    );
  }

  @override
  bool shouldRepaint(BubblePainter old) {
    return old.color != color ||
        old.wobble != wobble ||
        old.phase != phase ||
        old.squash != squash ||
        old.opacity != opacity ||
        old.glow != glow ||
        old.showShadow != showShadow;
  }
}

/// A soap bubble that breathes on its own.
///
/// Used for every answer a child can tap.
class SoapBubble extends StatefulWidget {
  const SoapBubble({
    super.key,
    required this.color,
    required this.diameter,
    this.glow = 0,
    this.squash = 1,
    this.opacity = 1,
    this.semanticLabel,
    this.onTap,
  });

  final Color color;
  final double diameter;
  final double glow;
  final double squash;
  final double opacity;

  /// Spoken description for screen readers.
  final String? semanticLabel;

  final VoidCallback? onTap;

  @override
  State<SoapBubble> createState() => _SoapBubbleState();
}

class _SoapBubbleState extends State<SoapBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phaseOffset;

  @override
  void initState() {
    super.initState();

    // Each bubble starts somewhere different in its wobble so a row of them
    // never pulses in unison.
    _phaseOffset = Random().nextDouble() * 2 * pi;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Children need a bigger target than the usual Material minimum.
    final double tapSize = max(widget.diameter, AppSpacing.minTouchTarget);

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: tapSize,
          height: tapSize,
          child: Center(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    size: Size.square(widget.diameter),
                    painter: BubblePainter(
                      color: widget.color,
                      phase: _phaseOffset + (_controller.value * 2 * pi),
                      squash: widget.squash,
                      opacity: widget.opacity,
                      glow: widget.glow,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
