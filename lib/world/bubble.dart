import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Draws one glossy bubble.
///
/// The style is flat and graphic rather than a rendered sphere: a bold, even
/// colour, a thick light outline like a sticker, one clean sweep of shine, a
/// sparkle, and a soft halo of its own colour behind it.
///
/// Flat matters here. A heavy three dimensional gradient shades the colour
/// darker on one side and lighter on the other, which is the last thing you
/// want when the entire game is asking a child to name that colour. Keeping
/// the fill even means red looks the same red all over.
class BubblePainter extends CustomPainter {
  const BubblePainter({
    required this.color,
    this.phase = 0,
    this.squash = 1,
    this.opacity = 1,
    this.glow = 0,
    this.showSparkle = true,
  });

  /// The colour a child is learning.
  final Color color;

  /// Where the bubble is in its gentle drift, used to twinkle the sparkle.
  final double phase;

  /// Vertical squash. Below 1 is squat, above 1 is tall.
  final double squash;

  final double opacity;

  /// Extra halo, used to nudge a child towards the right answer.
  final double glow;

  final bool showSparkle;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = (min(size.width, size.height) / 2) * 0.86;

    if (radius <= 0) return;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(1 / squash, squash);
    canvas.translate(-centre.dx, -centre.dy);

    _paintHalo(canvas, centre, radius);
    _paintBody(canvas, centre, radius);
    _paintOutline(canvas, centre, radius);
    _paintShine(canvas, centre, radius);
    if (showSparkle) _paintSparkle(canvas, centre, radius);

    canvas.restore();
  }

  /// The coloured glow around the bubble.
  ///
  /// This replaces the drop shadow a solid object would cast. It keeps every
  /// bubble looking like light rather than plastic, and it grows when Boo is
  /// pointing a child towards the answer.
  void _paintHalo(Canvas canvas, Offset centre, double radius) {
    final double strength = 0.30 + (0.45 * glow);

    canvas.drawCircle(
      centre,
      radius * (1.05 + (0.12 * glow)),
      Paint()
        ..color = color.withValues(alpha: strength * opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          radius * (0.22 + (0.16 * glow)),
        ),
    );
  }

  /// The flat colour itself.
  void _paintBody(Canvas canvas, Offset centre, double radius) {
    final HSLColor hsl = HSLColor.fromColor(color);

    // Only the faintest lift towards the top. Just enough that the shape does
    // not look like a paper cut-out, nowhere near enough to change the colour.
    final Color top = hsl
        .withLightness((hsl.lightness + 0.07).clamp(0.0, 1.0))
        .toColor();

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(centre.dx, centre.dy - radius),
          Offset(centre.dx, centre.dy + radius),
          <Color>[
            top.withValues(alpha: opacity),
            color.withValues(alpha: opacity),
          ],
        ),
    );
  }

  /// The thick light rim that makes it read as a sticker.
  void _paintOutline(Canvas canvas, Offset centre, double radius) {
    // A white rim vanishes on a white bubble, so very pale colours get a
    // tinted rim of their own instead.
    final double luminance = color.computeLuminance();
    final HSLColor hsl = HSLColor.fromColor(color);

    final Color rim = luminance > 0.72
        ? hsl
              .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
              .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
              .toColor()
        : AppColors.white;

    canvas.drawCircle(
      centre,
      radius - (radius * 0.04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.085
        ..color = rim.withValues(alpha: 0.95 * opacity),
    );
  }

  /// One clean sweep of shine across the top left.
  void _paintShine(Canvas canvas, Offset centre, double radius) {
    canvas.save();

    // Kept inside the bubble so the shine follows its edge.
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius * 0.93)),
    );

    // A large soft oval overlapping the top edge leaves a crescent of light.
    canvas.save();
    canvas.translate(centre.dx - (radius * 0.30), centre.dy - (radius * 0.40));
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.95,
        height: radius * 0.52,
      ),
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.55 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.10),
    );
    canvas.restore();

    // A small hard catchlight for the glossy snap.
    canvas.save();
    canvas.translate(centre.dx - (radius * 0.38), centre.dy - (radius * 0.46));
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.40,
        height: radius * 0.20,
      ),
      Paint()..color = AppColors.white.withValues(alpha: 0.92 * opacity),
    );
    canvas.restore();

    canvas.restore();
  }

  /// A little four pointed star, the way a highlight twinkles in cartoons.
  void _paintSparkle(Canvas canvas, Offset centre, double radius) {
    // Breathes slowly so the bubble never looks completely still.
    final double twinkle = 0.75 + (0.25 * sin(phase));
    final Offset at = centre.translate(radius * 0.44, -radius * 0.44);
    final double s = radius * 0.17 * twinkle;

    final Path star = Path()
      ..moveTo(at.dx, at.dy - s)
      ..quadraticBezierTo(at.dx + s * 0.20, at.dy - s * 0.20, at.dx + s, at.dy)
      ..quadraticBezierTo(at.dx + s * 0.20, at.dy + s * 0.20, at.dx, at.dy + s)
      ..quadraticBezierTo(at.dx - s * 0.20, at.dy + s * 0.20, at.dx - s, at.dy)
      ..quadraticBezierTo(at.dx - s * 0.20, at.dy - s * 0.20, at.dx, at.dy - s)
      ..close();

    canvas.drawPath(
      star,
      Paint()..color = AppColors.white.withValues(alpha: 0.95 * opacity),
    );
  }

  @override
  bool shouldRepaint(BubblePainter old) {
    return old.color != color ||
        old.phase != phase ||
        old.squash != squash ||
        old.opacity != opacity ||
        old.glow != glow ||
        old.showSparkle != showSparkle;
  }
}

/// A glossy bubble a child can tap.
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
  bool _pressed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    // Each bubble twinkles at its own moment so a row never pulses in unison.
    _phaseOffset = Random().nextDouble() * 2 * pi;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
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
    final Widget painted = SizedBox(
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
                  phase: _reduceMotion
                      ? 0
                      : _phaseOffset + (_controller.value * 2 * pi),
                  squash: widget.squash,
                  opacity: widget.opacity,
                  glow: widget.glow,
                  showSparkle: !_reduceMotion,
                ),
              );
            },
          ),
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.91 : 1,
          duration: _reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 105),
          curve: Curves.easeOut,
          child: painted,
        ),
      ),
    );
  }
}
