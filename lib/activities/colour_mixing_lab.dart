import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../colors/color_library.dart';
import '../colors/color_mixes.dart';
import '../settings/settings.dart';
import '../world/merge_physics.dart';

/// How far along the merge is.
enum _MergeStage {
  /// Two separate bubbles, waiting for the child.
  apart,

  /// The films have met and are becoming one.
  merging,

  /// One bubble of the new colour, wobbling as it settles.
  settled,
}

/// "Put these two together and see what happens."
///
/// The child drags one bubble into the other. Their skins reach for each
/// other, pinch into a neck, and snap into a single bubble of a new colour.
///
/// Two soap bubbles merging is literally what happens in the real world, so
/// this is the one mechanic in the app that is physically honest rather than
/// merely decorative. It is also the clearest way to show a child that blue
/// and yellow make green.
class ColourMixingLab extends StatefulWidget {
  const ColourMixingLab({
    super.key,
    required this.mix,
    required this.onMixed,
    required this.onBooTapped,
  });

  final ColorMix mix;

  /// Called once the two colours have become one.
  final void Function(ColorEntry result, Offset position) onMixed;

  final VoidCallback onBooTapped;

  @override
  State<ColourMixingLab> createState() => _ColourMixingLabState();
}

class _ColourMixingLabState extends State<ColourMixingLab>
    with TickerProviderStateMixin {
  /// Drives the snap from two bubbles into one.
  late final AnimationController _merge;

  /// The wobble after they join.
  late final AnimationController _settle;

  _MergeStage _stage = _MergeStage.apart;

  /// Where the draggable bubble has been pulled to, in local coordinates.
  Offset? _dragged;

  /// Resting positions, worked out from the space available.
  Offset _homeA = Offset.zero;
  Offset _homeB = Offset.zero;
  double _radius = 60;

  bool _announced = false;

  ColorEntry get _first => ColorLibrary.byName(widget.mix.firstName)!;
  ColorEntry get _second => ColorLibrary.byName(widget.mix.secondName)!;
  ColorEntry get _result => ColorLibrary.byName(widget.mix.resultName)!;

  @override
  void initState() {
    super.initState();

    _merge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(ColourMixingLab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mix != oldWidget.mix) {
      setState(() {
        _stage = _MergeStage.apart;
        _dragged = null;
        _announced = false;
      });
      _merge.reset();
      _settle.reset();
    }
  }

  @override
  void dispose() {
    _merge.dispose();
    _settle.dispose();
    super.dispose();
  }

  Offset get _positionA => _dragged ?? _homeA;

  void _onDragUpdate(DragUpdateDetails details, Size size) {
    if (_stage != _MergeStage.apart) return;

    final Offset next = (_dragged ?? _homeA) + details.delta;

    setState(() {
      _dragged = Offset(
        next.dx.clamp(_radius, size.width - _radius),
        next.dy.clamp(_radius, size.height - _radius),
      );
    });

    if (MergeShape.areTouching(
      centerA: _positionA,
      radiusA: _radius,
      centerB: _homeB,
      radiusB: _radius,
    )) {
      _beginMerge();
    }
  }

  void _onDragEnd() {
    if (_stage != _MergeStage.apart) return;
    // Not close enough. Let it drift back so the child can try again.
    setState(() => _dragged = null);
  }

  void _beginMerge() {
    if (_stage != _MergeStage.apart) return;

    setState(() => _stage = _MergeStage.merging);
    AudioService.instance.playSnap();

    _merge.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _stage = _MergeStage.settled);
      _settle.forward(from: 0);

      if (_announced) return;
      _announced = true;

      AudioService.instance.playColorNote(_result.semitone, withThird: true);
      widget.onMixed(_result, const Offset(0.5, 0.45));
    });
  }

  @override
  Widget build(BuildContext context) {
    final Settings settings = SettingsScope.of(context);

    return Column(
      children: <Widget>[
        Semantics(
          label:
              'Drag the ${_first.name} bubble into the ${_second.name} bubble '
              'to mix them. Tap to hear again.',
          button: true,
          child: GestureDetector(
            onTap: widget.onBooTapped,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _stage == _MergeStage.settled
                        ? 'Together they make'
                        : 'Push them together!',
                    style: AppTheme.booLine,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (settings.words && _stage == _MergeStage.settled)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _result.name.toUpperCase(),
                        style: AppTheme.heroWord(
                          MediaQuery.sizeOf(context).width,
                        ),
                        maxLines: 1,
                      ),
                    )
                  else
                    SizedBox(
                      height:
                          AppSizing.heroTextSize(
                            MediaQuery.sizeOf(context).width,
                          ) *
                          1.1,
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _playArea()),
      ],
    );
  }

  Widget _playArea() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);

        // Both bubbles sized from the space available so they always fit.
        _radius = min(size.width * 0.19, size.height * 0.28).clamp(36.0, 110.0);

        _homeA = Offset(size.width * 0.27, size.height * 0.5);
        _homeB = Offset(size.width * 0.73, size.height * 0.5);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (DragUpdateDetails d) => _onDragUpdate(d, size),
          onPanEnd: (_) => _onDragEnd(),
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_merge, _settle]),
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                size: size,
                painter: _MergePainter(
                  colorA: _first.color,
                  colorB: _second.color,
                  colorResult: _result.color,
                  centerA: _positionA,
                  centerB: _homeB,
                  radius: _radius,
                  mergeProgress: _merge.value,
                  settleProgress: _settle.value,
                  merged: _stage != _MergeStage.apart,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Draws the two bubbles reaching for each other and becoming one.
class _MergePainter extends CustomPainter {
  const _MergePainter({
    required this.colorA,
    required this.colorB,
    required this.colorResult,
    required this.centerA,
    required this.centerB,
    required this.radius,
    required this.mergeProgress,
    required this.settleProgress,
    required this.merged,
  });

  final Color colorA;
  final Color colorB;
  final Color colorResult;
  final Offset centerA;
  final Offset centerB;
  final double radius;
  final double mergeProgress;
  final double settleProgress;
  final bool merged;

  @override
  void paint(Canvas canvas, Size size) {
    if (merged) {
      _paintMerged(canvas);
    } else {
      _paintApart(canvas);
    }
  }

  /// Two bubbles, with a neck of film between them once they are close.
  void _paintApart(Canvas canvas) {
    final Path shape = MergeShape.build(
      centerA: centerA,
      radiusA: radius,
      centerB: centerB,
      radiusB: radius,
    );

    // The two colours meet in the middle of the joined shape.
    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        centerA,
        centerB,
        <Color>[colorA, colorA, colorB, colorB],
        <double>[0.0, 0.34, 0.66, 1.0],
      );

    _paintShadow(canvas, shape);
    canvas.drawPath(shape, paint);
    _paintRim(canvas, shape);

    _paintGloss(canvas, centerA, radius);
    _paintGloss(canvas, centerB, radius);
  }

  /// One bubble of the new colour, still wobbling from the join.
  void _paintMerged(Canvas canvas) {
    final Offset middle = Offset.lerp(centerA, centerB, 0.5)!;
    final double target = MergeShape.mergedRadius(radius, radius);

    // Grows into its new size as the merge completes.
    final double grown = radius + ((target - radius) * mergeProgress);

    // Then wobbles like a struck drum, dying away.
    final double decay = 1 - settleProgress;
    final double wobble = sin(settleProgress * pi * 5) * 0.12 * decay;

    final Path shape = Path()
      ..addOval(
        Rect.fromCenter(
          center: middle,
          width: grown * 2 * (1 + wobble),
          height: grown * 2 * (1 - wobble),
        ),
      );

    // The colour changes over as the two become one.
    final Color blended =
        Color.lerp(colorA, colorResult, mergeProgress.clamp(0.0, 1.0)) ??
        colorResult;

    _paintShadow(canvas, shape);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = ui.Gradient.radial(
          middle.translate(-grown * 0.33, -grown * 0.38),
          grown * 1.5,
          <Color>[_lighten(blended, 0.26), blended, _darken(blended, 0.16)],
          <double>[0.0, 0.52, 1.0],
        ),
    );
    _paintRim(canvas, shape);
    _paintGloss(canvas, middle, grown);
  }

  void _paintShadow(Canvas canvas, Path shape) {
    canvas.drawPath(
      shape.shift(Offset(0, radius * 0.16)),
      Paint()
        ..color = AppColors.paperShadow.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.24),
    );
  }

  void _paintRim(Canvas canvas, Path shape) {
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.075
        ..shader = ui.Gradient.sweep(
          Offset.lerp(centerA, centerB, 0.5)!,
          <Color>[
            AppColors.bubblePink.withValues(alpha: 0.85),
            AppColors.sunnyPop.withValues(alpha: 0.8),
            AppColors.bubbleMint.withValues(alpha: 0.85),
            AppColors.bubbleSky.withValues(alpha: 0.9),
            AppColors.bubblePurple.withValues(alpha: 0.75),
            AppColors.bubblePink.withValues(alpha: 0.85),
          ],
          <double>[0.0, 0.2, 0.42, 0.62, 0.82, 1.0],
        ),
    );
  }

  void _paintGloss(Canvas canvas, Offset centre, double r) {
    canvas.save();
    canvas.translate(centre.dx - (r * 0.36), centre.dy - (r * 0.42));
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.6, height: r * 0.32),
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.9)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05),
    );
    canvas.restore();
  }

  Color _lighten(Color color, double amount) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(_MergePainter old) =>
      old.centerA != centerA ||
      old.centerB != centerB ||
      old.radius != radius ||
      old.mergeProgress != mergeProgress ||
      old.settleProgress != settleProgress ||
      old.merged != merged ||
      old.colorA != colorA ||
      old.colorB != colorB;
}
