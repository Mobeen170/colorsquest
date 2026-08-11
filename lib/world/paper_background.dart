import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// The world a child plays in: a warm watercolour morning.
///
/// The most important rule here is the quiet middle. Colourful washes are kept
/// out at the edges and the centre of the screen stays almost colourless.
/// A bright, colourful background would compete with the colours a child is
/// trying to tell apart, which is the one thing this app cannot afford.
class PaperBackgroundPainter extends CustomPainter {
  const PaperBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    _paintPaper(canvas, bounds);
    _paintMarginWashes(canvas, size);
    _paintQuietCentre(canvas, size);
    _paintGrain(canvas, size);
  }

  /// The cream page everything sits on.
  void _paintPaper(Canvas canvas, Rect bounds) {
    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        bounds.topCenter,
        bounds.bottomCenter,
        <Color>[AppColors.paperCream, AppColors.paperWarm],
      );

    canvas.drawRect(bounds, paint);
  }

  /// Soft colour bleeding in from the corners, like wet paint on damp paper.
  void _paintMarginWashes(Canvas canvas, Size size) {
    final double reach = max(size.width, size.height) * 0.55;

    void wash(Offset at, Color color, double strength, double scale) {
      final Paint paint = Paint()
        ..shader = ui.Gradient.radial(at, reach * scale, <Color>[
          color.withValues(alpha: strength),
          color.withValues(alpha: 0),
        ]);
      canvas.drawCircle(at, reach * scale, paint);
    }

    wash(
      Offset(size.width * 0.04, size.height * 0.03),
      AppColors.bubbleSky,
      0.75,
      0.72,
    );
    wash(
      Offset(size.width * 0.98, size.height * 0.10),
      AppColors.bubblePink,
      0.30,
      0.60,
    );
    wash(
      Offset(size.width * 0.92, size.height * 0.97),
      AppColors.bubbleMint,
      0.34,
      0.66,
    );
    wash(
      Offset(size.width * 0.02, size.height * 0.92),
      AppColors.bubblePurple,
      0.20,
      0.58,
    );
  }

  /// Lifts the middle of the screen back towards neutral.
  ///
  /// This is what protects colour discrimination. Without it the washes creep
  /// inwards and start tinting the answer bubbles.
  void _paintQuietCentre(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height * 0.46);
    final double reach = max(size.width, size.height) * 0.52;

    final Paint paint = Paint()
      ..shader = ui.Gradient.radial(
        centre,
        reach,
        <Color>[
          AppColors.playBand.withValues(alpha: 0.97),
          AppColors.playBand.withValues(alpha: 0.86),
          AppColors.playBand.withValues(alpha: 0),
        ],
        <double>[0.0, 0.45, 1.0],
      );

    canvas.drawCircle(centre, reach, paint);
  }

  /// The tooth of the paper.
  ///
  /// Drawn from a fixed seed so it never crawls between frames, and painted
  /// once because this layer does not animate.
  void _paintGrain(Canvas canvas, Size size) {
    final Random random = Random(20260811);
    final Paint paint = Paint();

    final int count = ((size.width * size.height) / 900)
        .clamp(300, 1600)
        .toInt();

    for (int i = 0; i < count; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double r = 0.6 + (random.nextDouble() * 1.5);

      final bool dark = random.nextBool();
      paint.color = dark
          ? AppColors.paperShadow.withValues(alpha: 0.16)
          : AppColors.white.withValues(alpha: 0.42);

      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(PaperBackgroundPainter oldDelegate) => false;
}

/// The paper, ready to put behind everything else.
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
