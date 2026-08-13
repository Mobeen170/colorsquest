import 'dart:math';

import 'package:flutter/material.dart';

/// A mark left on the paper where a bubble burst.
@immutable
class SplashMark {
  const SplashMark({
    required this.position,
    required this.color,
    required this.radius,
    required this.seed,
    required this.bornAt,
  });

  /// Where it landed, as a share of the screen, so it survives rotation.
  final Offset position;

  final Color color;

  /// Size as a share of the shortest side.
  final double radius;

  /// Fixes the shape of this particular blot.
  final int seed;

  final DateTime bornAt;
}

/// Draws the watercolour the child has splashed around.
///
/// Every bubble a child pops leaves its colour behind. Over a sitting the
/// world slowly becomes a painting of their own play. It is the only thing
/// that accumulates anywhere in the app, and it is deliberately not a score:
/// nothing is counted, nothing is saved, and it simply looks nice.
class SplashMarksPainter extends CustomPainter {
  const SplashMarksPainter({required this.marks, required this.now});

  final List<SplashMark> marks;

  /// Used to bloom marks in as they are made.
  final DateTime now;

  static const Duration _bloom = Duration(milliseconds: 700);

  @override
  void paint(Canvas canvas, Size size) {
    final double shortest = min(size.width, size.height);

    for (final SplashMark mark in marks) {
      final int age = now.difference(mark.bornAt).inMilliseconds;
      final double growth = (age / _bloom.inMilliseconds).clamp(0.0, 1.0);

      // Ease out, so it spreads quickly then settles.
      final double eased = 1 - pow(1 - growth, 3).toDouble();

      final Offset centre = Offset(
        mark.position.dx * size.width,
        mark.position.dy * size.height,
      );

      _paintBlot(
        canvas: canvas,
        centre: centre,
        radius: mark.radius * shortest * eased,
        color: mark.color,
        seed: mark.seed,
        strength: eased,
      );
    }
  }

  /// One irregular, soft-edged blot of colour.
  void _paintBlot({
    required Canvas canvas,
    required Offset centre,
    required double radius,
    required Color color,
    required int seed,
    required double strength,
  }) {
    if (radius <= 0.5) return;

    final Random random = Random(seed);

    // Three overlapping lobes read as a wet blot rather than a dot.
    for (int lobe = 0; lobe < 3; lobe++) {
      final double angle = random.nextDouble() * 2 * pi;
      final double distance = radius * 0.22 * random.nextDouble();
      final double scale = 0.66 + (random.nextDouble() * 0.42);

      final Offset at = centre.translate(
        cos(angle) * distance,
        sin(angle) * distance,
      );

      final Paint paint = Paint()
        ..color = color.withValues(alpha: 0.13 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.32);

      canvas.drawCircle(at, radius * scale, paint);
    }

    // A denser centre, the way pigment pools.
    final Paint core = Paint()
      ..color = color.withValues(alpha: 0.16 * strength)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.2);

    canvas.drawCircle(centre, radius * 0.52, core);
  }

  @override
  bool shouldRepaint(SplashMarksPainter old) =>
      old.marks.length != marks.length ||
      old.marks.lastOrNull?.seed != marks.lastOrNull?.seed ||
      old.now != now;
}

/// Keeps the splashes on the paper and blooms new ones in.
class SplashMarksLayer extends StatefulWidget {
  const SplashMarksLayer({super.key, required this.marks});

  final List<SplashMark> marks;

  @override
  State<SplashMarksLayer> createState() => _SplashMarksLayerState();
}

class _SplashMarksLayerState extends State<SplashMarksLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bloomController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    // Runs only while a new splash is spreading, then stops. There is no
    // point burning frames on marks that have already settled.
    _bloomController = AnimationController(
      vsync: this,
      duration: SplashMarksPainter._bloom + const Duration(milliseconds: 100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _bloomController
        ..stop()
        ..value = 1;
    } else if (widget.marks.isNotEmpty && _bloomController.value < 1) {
      _bloomController.forward();
    }
  }

  @override
  void didUpdateWidget(SplashMarksLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.marks.length != oldWidget.marks.length ||
        widget.marks.lastOrNull?.seed != oldWidget.marks.lastOrNull?.seed) {
      if (_reduceMotion) {
        _bloomController.value = 1;
      } else {
        _bloomController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _bloomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      final DateTime settledAt = widget.marks.isEmpty
          ? DateTime.now()
          : widget.marks.last.bornAt.add(SplashMarksPainter._bloom);
      return RepaintBoundary(
        child: CustomPaint(
          painter: SplashMarksPainter(marks: widget.marks, now: settledAt),
          size: Size.infinite,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _bloomController,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: SplashMarksPainter(
              marks: widget.marks,
              now: DateTime.now(),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
