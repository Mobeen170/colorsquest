import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Everything about how Boo looks at one instant.
///
/// Boo is drawn rather than loaded from an image, which is what lets him take
/// any of the fifty colours, blink, squash, and act. A folder of pictures
/// could only ever show one expression.
@immutable
class BooPose {
  const BooPose({
    required this.bodyColor,
    this.eyeOpen = 1,
    this.browRaise = 0,
    this.mouthOpen = 0.45,
    this.lean = 0,
    this.squash = 1,
    this.wobblePhase = 0,
    this.companionSpread = 1,
    this.companionPhase = 0,
    this.opacity = 1,
  });

  /// Boo's colour. He becomes whichever colour he is teaching.
  final Color bodyColor;

  /// 1 is wide open, 0 is a blink.
  final double eyeOpen;

  /// How surprised the eyebrows are, 0 to 1.
  final double browRaise;

  /// 0 is a closed smile, 1 is a delighted open mouth.
  final double mouthOpen;

  /// Tilt in radians. Positive leans right.
  final double lean;

  /// Below 1 is squat, above 1 is stretched.
  final double squash;

  /// Where Boo is in his surface wobble.
  final double wobblePhase;

  /// How far the little bubbles around him have flown out.
  final double companionSpread;

  final double companionPhase;

  final double opacity;

  BooPose copyWith({
    Color? bodyColor,
    double? eyeOpen,
    double? browRaise,
    double? mouthOpen,
    double? lean,
    double? squash,
    double? wobblePhase,
    double? companionSpread,
    double? companionPhase,
    double? opacity,
  }) {
    return BooPose(
      bodyColor: bodyColor ?? this.bodyColor,
      eyeOpen: eyeOpen ?? this.eyeOpen,
      browRaise: browRaise ?? this.browRaise,
      mouthOpen: mouthOpen ?? this.mouthOpen,
      lean: lean ?? this.lean,
      squash: squash ?? this.squash,
      wobblePhase: wobblePhase ?? this.wobblePhase,
      companionSpread: companionSpread ?? this.companionSpread,
      companionPhase: companionPhase ?? this.companionPhase,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Draws Boo.
class BooPainter extends CustomPainter {
  const BooPainter({required this.pose});

  final BooPose pose;

  // Ink colours for the face. These stay constant whatever colour Boo turns,
  // so his face is readable even when he is white or black.
  static const Color _ink = Color(0xFF1B2559);
  static const Color _blush = Color(0xFFFF9BC4);
  static const Color _mouth = Color(0xFF9E1F3D);
  static const Color _tongue = Color(0xFFFF6B7F);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = min(size.width, size.height);
    if (s <= 0) return;

    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double bodyR = s * 0.30;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(pose.lean);
    canvas.scale(1 / pose.squash, pose.squash);
    canvas.translate(-centre.dx, -centre.dy);

    _paintCompanions(canvas, centre, bodyR, s);
    _paintFeet(canvas, centre, bodyR);
    _paintArms(canvas, centre, bodyR);
    _paintTopknot(canvas, centre, bodyR);
    _paintBody(canvas, centre, bodyR);
    _paintFace(canvas, centre, bodyR);

    canvas.restore();
  }

  /// Boo's body, wobbling gently like real soap film.
  Path _bodyPath(Offset centre, double r) {
    final Path path = Path();
    const int steps = 56;

    for (int i = 0; i <= steps; i++) {
      final double t = (i / steps) * 2 * pi;
      // Kept subtle. Boo should read as a round bubble that breathes, not as
      // a lumpy blob.
      final double flex =
          (0.018 * sin(3 * t + pose.wobblePhase)) +
          (0.010 * sin(5 * t - pose.wobblePhase * 1.4));
      final double rr = r * (1 + flex);

      final Offset p = Offset(
        centre.dx + (rr * cos(t)),
        centre.dy + (rr * sin(t)),
      );

      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }

    path.close();
    return path;
  }

  void _paintBody(Canvas canvas, Offset centre, double r) {
    final Path body = _bodyPath(centre, r);
    final HSLColor hsl = HSLColor.fromColor(pose.bodyColor);

    final Color lit = hsl
        .withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
        .toColor();
    final Color deep = hsl
        .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
        .toColor();

    // Soft shadow where Boo meets the paper.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(0, r * 1.05),
        width: r * 1.7,
        height: r * 0.42,
      ),
      Paint()
        ..color = AppColors.paperShadow.withValues(alpha: 0.3 * pose.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );

    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          centre.translate(-r * 0.33, -r * 0.38),
          r * 1.5,
          <Color>[
            lit.withValues(alpha: pose.opacity),
            pose.bodyColor.withValues(alpha: pose.opacity),
            deep.withValues(alpha: pose.opacity),
          ],
          <double>[0.0, 0.55, 1.0],
        ),
    );

    // The rainbow edge of a soap film.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..shader = ui.Gradient.sweep(
          centre,
          <Color>[
            AppColors.bubblePink.withValues(alpha: 0.85 * pose.opacity),
            AppColors.sunnyPop.withValues(alpha: 0.8 * pose.opacity),
            AppColors.bubbleMint.withValues(alpha: 0.85 * pose.opacity),
            AppColors.bubbleSky.withValues(alpha: 0.9 * pose.opacity),
            AppColors.bubblePurple.withValues(alpha: 0.75 * pose.opacity),
            AppColors.bubblePink.withValues(alpha: 0.85 * pose.opacity),
          ],
          <double>[0.0, 0.2, 0.42, 0.62, 0.82, 1.0],
        ),
    );

    _paintGloss(canvas, centre, r);
  }

  void _paintGloss(Canvas canvas, Offset centre, double r) {
    canvas.save();
    canvas.translate(centre.dx - (r * 0.36), centre.dy - (r * 0.46));
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.72, height: r * 0.38),
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.95 * pose.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.045),
    );
    canvas.restore();

    canvas.drawCircle(
      centre.translate(r * 0.42, r * 0.44),
      r * 0.18,
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.5 * pose.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.09),
    );
  }

  /// The two bubbles on top of his head.
  void _paintTopknot(Canvas canvas, Offset centre, double r) {
    void blob(Offset at, double size, double rotation) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(rotation);

      final Path drop = Path()
        ..moveTo(0, -size)
        ..quadraticBezierTo(size * 0.95, -size * 0.25, size * 0.5, size * 0.6)
        ..quadraticBezierTo(0, size * 1.05, -size * 0.5, size * 0.6)
        ..quadraticBezierTo(-size * 0.95, -size * 0.25, 0, -size)
        ..close();

      canvas.drawPath(
        drop,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(-size * 0.3, -size * 0.3),
            size * 1.6,
            <Color>[
              AppColors.white.withValues(alpha: 0.95 * pose.opacity),
              AppColors.bubbleSky.withValues(alpha: 0.8 * pose.opacity),
            ],
          ),
      );

      canvas.drawPath(
        drop,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.14
          ..color = AppColors.bubblePink.withValues(alpha: 0.4 * pose.opacity),
      );

      canvas.restore();
    }

    blob(centre.translate(r * 0.08, -r * 1.16), r * 0.22, 0.25);
    blob(centre.translate(r * 0.36, -r * 1.02), r * 0.15, 0.9);
  }

  /// Two little blob arms.
  void _paintArms(Canvas canvas, Offset centre, double r) {
    void arm(double dx, double rotation) {
      canvas.save();
      canvas.translate(centre.dx + dx, centre.dy + (r * 0.18));
      canvas.rotate(rotation);

      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 0.58, height: r * 0.38),
        Paint()
          ..shader =
              ui.Gradient.radial(Offset(-r * 0.1, -r * 0.1), r * 0.5, <Color>[
                AppColors.white.withValues(alpha: 0.9 * pose.opacity),
                pose.bodyColor.withValues(alpha: 0.75 * pose.opacity),
              ]),
      );

      canvas.restore();
    }

    arm(-r * 1.02, -0.35);
    arm(r * 1.02, 0.35);
  }

  /// Three small feet.
  void _paintFeet(Canvas canvas, Offset centre, double r) {
    void foot(double dx, double size) {
      canvas.drawOval(
        Rect.fromCenter(
          center: centre.translate(dx, r * 0.92),
          width: size * 1.15,
          height: size,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            centre.translate(dx - size * 0.2, r * 0.92 - size * 0.25),
            size,
            <Color>[
              AppColors.white.withValues(alpha: 0.85 * pose.opacity),
              pose.bodyColor.withValues(alpha: 0.8 * pose.opacity),
            ],
          ),
      );
    }

    foot(-r * 0.42, r * 0.3);
    foot(r * 0.02, r * 0.34);
    foot(r * 0.46, r * 0.28);
  }

  /// The bubbles that follow Boo around.
  void _paintCompanions(Canvas canvas, Offset centre, double r, double s) {
    const List<double> angles = <double>[-2.5, -1.2, 0.3, 1.5, 2.7];
    const List<double> sizes = <double>[0.16, 0.11, 0.14, 0.09, 0.12];

    for (int i = 0; i < angles.length; i++) {
      final double angle = angles[i] + (pose.companionPhase * 0.3);
      final double distance = r * (1.45 + (0.55 * (pose.companionSpread - 1)));
      final double bob = sin(pose.companionPhase + i) * r * 0.06;

      final Offset at = centre.translate(
        cos(angle) * distance,
        (sin(angle) * distance) + bob,
      );

      final double bubbleR = r * sizes[i];
      final double fade = (2.0 - pose.companionSpread).clamp(0.0, 1.0);

      canvas.drawCircle(
        at,
        bubbleR,
        Paint()
          ..shader = ui.Gradient.radial(
            at.translate(-bubbleR * 0.3, -bubbleR * 0.3),
            bubbleR * 1.8,
            <Color>[
              AppColors.white.withValues(alpha: 0.9 * pose.opacity * fade),
              AppColors.bubbleSky.withValues(alpha: 0.55 * pose.opacity * fade),
            ],
          ),
      );

      canvas.drawCircle(
        at,
        bubbleR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bubbleR * 0.18
          ..color = AppColors.bubblePink.withValues(
            alpha: 0.38 * pose.opacity * fade,
          ),
      );
    }
  }

  void _paintFace(Canvas canvas, Offset centre, double r) {
    // Big eyes are most of what makes a character read as young and friendly,
    // so they take up a lot of the face on purpose.
    final double eyeDx = r * 0.42;
    final double eyeDy = -r * 0.02;
    final double eyeR = r * 0.34;

    _paintBlush(canvas, centre.translate(-r * 0.62, r * 0.30), r);
    _paintBlush(canvas, centre.translate(r * 0.62, r * 0.30), r);

    _paintEye(canvas, centre.translate(-eyeDx, eyeDy), eyeR);
    _paintEye(canvas, centre.translate(eyeDx, eyeDy), eyeR);

    // Set well clear of the eyes. Brows sitting low and heavy read as cross,
    // which is the last thing this app should ever look.
    _paintBrow(canvas, centre.translate(-eyeDx, eyeDy - eyeR * 1.42), r, false);
    _paintBrow(canvas, centre.translate(eyeDx, eyeDy - eyeR * 1.42), r, true);

    _paintMouth(canvas, centre.translate(0, r * 0.50), r);
  }

  void _paintBlush(Canvas canvas, Offset at, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: at, width: r * 0.52, height: r * 0.30),
      Paint()
        ..color = _blush.withValues(alpha: 0.75 * pose.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.07),
    );
  }

  void _paintEye(Canvas canvas, Offset at, double eyeR) {
    // Blinking squashes the eye rather than hiding it.
    final double openness = pose.eyeOpen.clamp(0.06, 1.0);

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(1, openness);

    // White of the eye.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: eyeR * 1.65,
        height: eyeR * 2.0,
      ),
      Paint()..color = AppColors.white.withValues(alpha: pose.opacity),
    );

    // Iris.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, eyeR * 0.06),
        width: eyeR * 1.32,
        height: eyeR * 1.66,
      ),
      Paint()
        ..shader =
            ui.Gradient.radial(Offset(0, eyeR * 0.4), eyeR * 1.3, <Color>[
              const Color(0xFF3FA9F5).withValues(alpha: pose.opacity),
              _ink.withValues(alpha: pose.opacity),
            ]),
    );

    // Catchlight and sparkle, the things that make him look alive.
    canvas.drawCircle(
      Offset(eyeR * 0.28, -eyeR * 0.5),
      eyeR * 0.3,
      Paint()..color = AppColors.white.withValues(alpha: 0.95 * pose.opacity),
    );
    canvas.drawCircle(
      Offset(-eyeR * 0.32, eyeR * 0.28),
      eyeR * 0.15,
      Paint()..color = AppColors.white.withValues(alpha: 0.7 * pose.opacity),
    );

    _paintStar(
      canvas,
      Offset(-eyeR * 0.18, -eyeR * 0.18),
      eyeR * 0.26,
      AppColors.sunnyPop.withValues(alpha: 0.95 * pose.opacity),
    );

    canvas.restore();
  }

  void _paintStar(Canvas canvas, Offset at, double size, Color color) {
    final Path star = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = (i / 8) * 2 * pi;
      final double radius = i.isEven ? size : size * 0.34;
      final Offset p = Offset(
        at.dx + cos(angle) * radius,
        at.dy + sin(angle) * radius,
      );
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = color);
  }

  void _paintBrow(Canvas canvas, Offset at, double r, bool mirrored) {
    final double lift = pose.browRaise * r * 0.14;
    final double width = r * 0.26;

    // A shallow, even arch. Both ends sit at the same height so neither eye
    // looks like it is frowning.
    final Path brow = Path()
      ..moveTo(at.dx - width, at.dy - lift)
      ..quadraticBezierTo(
        at.dx,
        at.dy - lift - (r * 0.11),
        at.dx + width,
        at.dy - lift,
      );

    canvas.drawPath(
      brow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..strokeCap = StrokeCap.round
        ..color = _ink.withValues(alpha: 0.9 * pose.opacity),
    );
  }

  void _paintMouth(Canvas canvas, Offset at, double r) {
    final double open = pose.mouthOpen.clamp(0.0, 1.0);
    final double width = r * 0.34 + (open * r * 0.12);
    final double height = r * 0.08 + (open * r * 0.32);

    final Path mouth = Path()
      ..moveTo(at.dx - width, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + height * 1.9, at.dx + width, at.dy)
      ..quadraticBezierTo(at.dx, at.dy - height * 0.22, at.dx - width, at.dy)
      ..close();

    canvas.drawPath(
      mouth,
      Paint()..color = _mouth.withValues(alpha: pose.opacity),
    );

    if (open > 0.25) {
      final Path tongue = Path()
        ..moveTo(at.dx - width * 0.52, at.dy + height * 0.85)
        ..quadraticBezierTo(
          at.dx,
          at.dy + height * 2.1,
          at.dx + width * 0.52,
          at.dy + height * 0.85,
        )
        ..close();

      canvas.drawPath(
        tongue,
        Paint()..color = _tongue.withValues(alpha: pose.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(BooPainter old) =>
      old.pose.bodyColor != pose.bodyColor ||
      old.pose.eyeOpen != pose.eyeOpen ||
      old.pose.browRaise != pose.browRaise ||
      old.pose.mouthOpen != pose.mouthOpen ||
      old.pose.lean != pose.lean ||
      old.pose.squash != pose.squash ||
      old.pose.wobblePhase != pose.wobblePhase ||
      old.pose.companionSpread != pose.companionSpread ||
      old.pose.companionPhase != pose.companionPhase ||
      old.pose.opacity != pose.opacity;
}
