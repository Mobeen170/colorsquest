import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Coloriboo's twilight world, with a calm neutral clearing for learning.
///
/// The colour lives around the edge of the scene. The entire activity area is
/// kept warm and nearly neutral so the background never changes how an answer
/// colour appears to a child.
class PaperBackgroundPainter extends CustomPainter {
  const PaperBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Rect bounds = Offset.zero & size;
    final RRect clearing = _clearingFor(size);

    _paintTwilight(canvas, bounds);
    _paintEdgeLight(canvas, size);
    _paintClearingGlow(canvas, clearing, size);
    _paintNeutralClearing(canvas, clearing);
    _paintQuietCentre(canvas, clearing);
    _paintGrain(canvas, clearing, size);
  }

  /// A deep blue-violet base made only from the existing Coloriboo palette.
  void _paintTwilight(Canvas canvas, Rect bounds) {
    final Color lowerTwilight = Color.lerp(
      AppColors.darkInk,
      AppColors.bubblePurple,
      0.22,
    )!;
    final Color upperTwilight = Color.lerp(
      AppColors.darkInk,
      AppColors.booBlue,
      0.08,
    )!;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          <Color>[upperTwilight, AppColors.darkInk, lowerTwilight],
          <double>[0, 0.55, 1],
        ),
    );
  }

  /// Luminous colour at the margins makes the world feel larger than the
  /// screen without placing a colour cast under the learning bubbles.
  void _paintEdgeLight(Canvas canvas, Size size) {
    final double reach = max(size.width, size.height) * 0.62;

    void glow(Offset centre, Color color, double radius, double opacity) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            radius,
            <Color>[
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.24),
              color.withValues(alpha: 0),
            ],
            <double>[0, 0.42, 1],
          ),
      );
    }

    glow(
      Offset(-size.width * 0.08, size.height * 0.04),
      AppColors.booBlue,
      reach * 0.72,
      0.34,
    );
    glow(
      Offset(size.width * 1.08, size.height * 0.16),
      AppColors.bubblePink,
      reach * 0.58,
      0.24,
    );
    glow(
      Offset(size.width * 0.92, size.height * 1.10),
      AppColors.bubbleMint,
      reach * 0.64,
      0.20,
    );
    glow(
      Offset(size.width * 0.02, size.height * 1.08),
      AppColors.bubblePurple,
      reach * 0.56,
      0.27,
    );
  }

  /// Phones need almost all of their width for play. On a wide tablet the
  /// clearing follows the app's capped play width and leaves richer twilight
  /// gutters at either side.
  RRect _clearingFor(Size size) {
    final double shortest = min(size.width, size.height);
    final double horizontalInset = max(10, (size.width - 960) / 2);
    final double verticalInset = max(8, min(18, size.height * 0.018));
    final double radius = (shortest * 0.12).clamp(30.0, 72.0);

    return RRect.fromRectAndRadius(
      Rect.fromLTRB(
        horizontalInset,
        verticalInset,
        size.width - horizontalInset,
        size.height - verticalInset,
      ),
      Radius.circular(radius),
    );
  }

  /// A cool halo separates the play clearing from the darker environment.
  /// This is static and lives in a repaint boundary, so the blur is not paid
  /// on every animation frame.
  void _paintClearingGlow(Canvas canvas, RRect clearing, Size size) {
    final double shortest = min(size.width, size.height);

    canvas.drawRRect(
      clearing.inflate(shortest * 0.012),
      Paint()
        ..color = AppColors.bubbleSky.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (shortest * 0.045).clamp(14.0, 32.0),
        ),
    );
  }

  /// The stage itself is deliberately neutral for perceptual accuracy.
  void _paintNeutralClearing(Canvas canvas, RRect clearing) {
    canvas.drawRRect(
      clearing,
      Paint()
        ..shader = ui.Gradient.linear(
          clearing.outerRect.topCenter,
          clearing.outerRect.bottomCenter,
          <Color>[
            AppColors.white.withValues(alpha: 0.97),
            AppColors.playBand.withValues(alpha: 0.99),
            AppColors.paperCream.withValues(alpha: 0.97),
          ],
          <double>[0, 0.54, 1],
        ),
    );

    canvas.drawRRect(
      clearing.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.white.withValues(alpha: 0.72),
    );
  }

  /// A gentle lift through the busiest part of the screen removes even the
  /// slight warmth of the stage gradient from behind answer bubbles.
  void _paintQuietCentre(Canvas canvas, RRect clearing) {
    final Rect rect = clearing.outerRect;
    final Offset centre = Offset(rect.center.dx, rect.top + rect.height * 0.47);
    final double radius = max(rect.width, rect.height) * 0.58;

    canvas.save();
    canvas.clipRRect(clearing);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          radius,
          <Color>[
            AppColors.playBand.withValues(alpha: 0.42),
            AppColors.playBand.withValues(alpha: 0.18),
            AppColors.playBand.withValues(alpha: 0),
          ],
          <double>[0, 0.58, 1],
        ),
    );
    canvas.restore();
  }

  /// A sparse, fixed grain keeps the clearing tactile without becoming noisy.
  void _paintGrain(Canvas canvas, RRect clearing, Size size) {
    final Random random = Random(20260812);
    final int count = ((size.width * size.height) / 2600)
        .clamp(70, 480)
        .toInt();
    final Paint paint = Paint();

    canvas.save();
    canvas.clipRRect(clearing);

    for (int i = 0; i < count; i++) {
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final double radius = 0.45 + (random.nextDouble() * 0.85);

      paint.color = random.nextBool()
          ? AppColors.paperShadow.withValues(alpha: 0.08)
          : AppColors.white.withValues(alpha: 0.30);
      canvas.drawCircle(point, radius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(PaperBackgroundPainter oldDelegate) => false;
}

/// The static world layer behind every activity.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: PaperBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}
