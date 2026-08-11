import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'boo_painter.dart';

/// What Boo is doing.
///
/// Boo has one drawn body and acts entirely through movement. A soap bubble is
/// the ideal shape for this: squash, stretch, lean and wobble read as feeling
/// without needing a different picture for every emotion.
enum BooMood {
  /// Bobbing quietly, blinking now and then.
  idle,

  /// Leaning in, interested in what the child is about to do.
  curious,

  /// Talking. The mouth moves along with the voice.
  speaking,

  /// Delighted. Hops, spins a little, scatters his bubbles.
  cheer,

  /// Kind and patient after a miss. Never disappointed.
  gentle,

  /// Front and centre for a big moment.
  zoom,
}

/// Boo, the only mascot in Coloriboo.
class Boo extends StatefulWidget {
  const Boo({
    super.key,
    required this.color,
    required this.size,
    this.mood = BooMood.idle,
    this.leanTowards = 0,
    this.onTap,
  });

  /// The colour Boo currently is.
  final Color color;

  /// Boo's drawn size in logical pixels.
  final double size;

  final BooMood mood;

  /// Nudges Boo to lean left or right, from -1 to 1.
  ///
  /// Used to point at the right answer when a child is stuck.
  final double leanTowards;

  final VoidCallback? onTap;

  @override
  State<Boo> createState() => _BooState();
}

class _BooState extends State<Boo> with TickerProviderStateMixin {
  /// Constant gentle motion: bobbing and surface wobble.
  late final AnimationController _idle;

  /// One-off reactions: hops and zooms.
  late final AnimationController _react;

  /// Blinking, which happens on its own schedule.
  late final AnimationController _blink;

  Timer? _blinkTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
    );

    _scheduleBlink();

    if (widget.mood == BooMood.cheer || widget.mood == BooMood.zoom) {
      _react.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(Boo oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-run the reaction whenever Boo starts being pleased or takes centre
    // stage.
    final bool reacting =
        widget.mood == BooMood.cheer || widget.mood == BooMood.zoom;
    if (reacting && widget.mood != oldWidget.mood) {
      _react.forward(from: 0);
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(
      Duration(milliseconds: 1800 + _random.nextInt(3200)),
      () async {
        if (!mounted) return;
        await _blink.forward(from: 0);
        if (!mounted) return;
        await _blink.reverse();
        if (mounted) _scheduleBlink();
      },
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idle.dispose();
    _react.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// Works out how Boo looks right now from his mood and his animations.
  BooPose _poseFor(double idleT, double reactT, double blinkT) {
    final double breathe = sin(idleT * 2 * pi);

    // Base pose, then each mood adjusts it.
    double eyeOpen = 1 - blinkT;
    double browRaise = 0;
    double mouthOpen = 0.4;
    double lean = widget.leanTowards * 0.14;
    double squash = 1 + (breathe * 0.012);
    double companionSpread = 1;

    switch (widget.mood) {
      case BooMood.idle:
        break;

      case BooMood.curious:
        browRaise = 0.8;
        mouthOpen = 0.25;
        lean += 0.10;
        squash = 1 + (breathe * 0.02);

      case BooMood.speaking:
        // Mouth flaps along with the voice.
        mouthOpen = 0.3 + (0.45 * (0.5 + (0.5 * sin(idleT * 2 * pi * 6))));
        browRaise = 0.3;

      case BooMood.cheer:
        // A hop with squash and stretch, overshooting then settling.
        final double hop = sin(reactT * pi);
        squash = 1 + (hop * 0.22) - (reactT < 0.15 ? 0.18 : 0);
        mouthOpen = 1;
        browRaise = 1;
        eyeOpen = (1 - blinkT) * (1 - (hop * 0.25));
        companionSpread = 1 + (hop * 0.9);
        lean += sin(reactT * pi * 2) * 0.12;

      case BooMood.gentle:
        browRaise = 0.15;
        mouthOpen = 0.18;
        eyeOpen = (1 - blinkT) * 0.82;
        squash = 1 + (breathe * 0.008);

      case BooMood.zoom:
        browRaise = 0.6;
        mouthOpen = 0.7;
        squash = 1 + (sin(reactT * pi) * 0.1);
    }

    return BooPose(
      bodyColor: widget.color,
      eyeOpen: eyeOpen.clamp(0.0, 1.0),
      browRaise: browRaise,
      mouthOpen: mouthOpen,
      lean: lean,
      squash: squash,
      wobblePhase: idleT * 2 * pi,
      companionSpread: companionSpread,
      companionPhase: idleT * 2 * pi,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Boo bobs up and down as he breathes.
    return Semantics(
      label: 'Boo',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_idle, _react, _blink]),
            builder: (BuildContext context, Widget? child) {
              final double idleT = reduceMotion ? 0.25 : _idle.value;
              final double bob = reduceMotion
                  ? 0
                  : sin(idleT * 2 * pi) * widget.size * 0.022;

              final BooPose pose = _poseFor(
                idleT,
                Curves.easeOutBack.transform(_react.value.clamp(0.0, 1.0)),
                reduceMotion ? 0 : _blink.value,
              );

              return Transform.translate(
                offset: Offset(0, bob),
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: BooPainter(pose: pose),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
