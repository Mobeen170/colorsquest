import 'dart:math';
import 'dart:ui';

/// The shape two soap bubbles make as they come together.
///
/// Real soap films do not simply overlap. As two bubbles approach, surface
/// tension pulls their skins towards each other and a pinched neck forms
/// between them before they snap into one. Reproducing that is what makes the
/// mixing lab feel like real soap rather than two circles sliding together,
/// and it is the reason mixing is the most convincing moment in the app.
class MergeShape {
  const MergeShape._();

  /// How far apart two bubbles can be and still reach for each other,
  /// as a multiple of the smaller radius.
  ///
  /// Kept short. Films only grab each other when they are genuinely close,
  /// and a neck stretched across a wide gap looks like a bar joining two
  /// circles rather than soap being pulled.
  static const double reach = 0.85;

  /// Below this the films are not yet gripping, so no neck is drawn at all.
  static const double _minimumGrip = 0.22;

  /// Builds the outline of two bubbles at [centerA] and [centerB].
  ///
  /// When they are far apart this is simply two circles. As they approach, a
  /// neck grows between them. Once they touch it becomes a single shape.
  static Path build({
    required Offset centerA,
    required double radiusA,
    required Offset centerB,
    required double radiusB,
  }) {
    final Path a = Path()
      ..addOval(Rect.fromCircle(center: centerA, radius: radiusA));
    final Path b = Path()
      ..addOval(Rect.fromCircle(center: centerB, radius: radiusB));

    final Path union = Path.combine(PathOperation.union, a, b);

    final double neckStrength = _neckStrength(
      centerA: centerA,
      radiusA: radiusA,
      centerB: centerB,
      radiusB: radiusB,
    );

    if (neckStrength <= _minimumGrip) return union;

    final Path neck = _buildNeck(
      centerA: centerA,
      radiusA: radiusA,
      centerB: centerB,
      radiusB: radiusB,
      strength: neckStrength,
    );

    return Path.combine(PathOperation.union, union, neck);
  }

  /// How strongly the two films are reaching for each other, 0 to 1.
  ///
  /// Zero when they are too far apart to notice each other, one when they are
  /// touching.
  static double _neckStrength({
    required Offset centerA,
    required double radiusA,
    required Offset centerB,
    required double radiusB,
  }) {
    final double distance = (centerB - centerA).distance;
    final double touching = radiusA + radiusB;
    final double noticing = touching + (min(radiusA, radiusB) * reach);

    if (distance >= noticing) return 0;
    if (distance <= touching) return 1;

    return ((noticing - distance) / (noticing - touching)).clamp(0.0, 1.0);
  }

  /// The pinched waist of film joining the two bubbles.
  static Path _buildNeck({
    required Offset centerA,
    required double radiusA,
    required Offset centerB,
    required double radiusB,
    required double strength,
  }) {
    final Offset delta = centerB - centerA;
    final double distance = delta.distance;

    if (distance < 0.001) return Path();

    // Along the line joining them, and square across it.
    final Offset along = delta / distance;
    final Offset across = Offset(-along.dy, along.dx);

    // The neck is widest where it leaves each bubble and narrowest in the
    // middle, which is what makes it look pulled rather than drawn.
    // The waist keeps a minimum thickness however weak the grip, so the neck
    // always looks like film under tension rather than a drawn line.
    final double widthA = radiusA * (0.30 + (0.38 * strength));
    final double widthB = radiusB * (0.30 + (0.38 * strength));
    final double waist = min(radiusA, radiusB) * (0.20 + (0.22 * strength));

    // Start slightly inside each bubble so the shapes join cleanly.
    final Offset startA = centerA + (along * (radiusA * 0.86));
    final Offset startB = centerB - (along * (radiusB * 0.86));
    final Offset middle = Offset.lerp(startA, startB, 0.5)!;

    final Path path = Path()
      ..moveTo(
        startA.dx + (across.dx * widthA),
        startA.dy + (across.dy * widthA),
      )
      ..quadraticBezierTo(
        middle.dx + (across.dx * waist),
        middle.dy + (across.dy * waist),
        startB.dx + (across.dx * widthB),
        startB.dy + (across.dy * widthB),
      )
      ..lineTo(
        startB.dx - (across.dx * widthB),
        startB.dy - (across.dy * widthB),
      )
      ..quadraticBezierTo(
        middle.dx - (across.dx * waist),
        middle.dy - (across.dy * waist),
        startA.dx - (across.dx * widthA),
        startA.dy - (across.dy * widthA),
      )
      ..close();

    return path;
  }

  /// True when the two films have met and should become one.
  static bool areTouching({
    required Offset centerA,
    required double radiusA,
    required Offset centerB,
    required double radiusB,
  }) {
    return (centerB - centerA).distance <= (radiusA + radiusB) * 0.96;
  }

  /// The size of the bubble the two of them make.
  ///
  /// Air is conserved, so the new bubble is bigger than either but smaller
  /// than the two added together.
  static double mergedRadius(double radiusA, double radiusB) {
    return pow(pow(radiusA, 3) + pow(radiusB, 3), 1 / 3).toDouble();
  }
}
