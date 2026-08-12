import 'dart:math';

import 'package:flutter/material.dart';

/// What Boo is doing.
///
/// Boo is the original artwork, not something drawn in code. He acts entirely
/// through movement instead: a bubble that squashes, stretches, leans and hops
/// reads as feeling without needing a different picture for every emotion.
///
/// When more poses arrive, [Boo] can pick a different image per mood without
/// anything else in the app changing.
enum BooMood {
  /// Bobbing quietly.
  idle,

  /// Leaning in, interested in what the child is about to do.
  curious,

  /// Pausing while a child decides what to try.
  waiting,

  /// Working something out alongside the child.
  thinking,

  /// Guiding attention towards a useful place.
  pointing,

  /// Watching two colours meet.
  mixing,

  /// Talking, with a gentle bounce on each beat.
  speaking,

  /// Delighted. A big hop with a squash and a stretch.
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
    required this.size,
    this.mood = BooMood.idle,
    this.tint,
    this.leanTowards = 0,
    this.onTap,
  });

  /// Boo's drawn size in logical pixels.
  final double size;

  final BooMood mood;

  /// Gives Boo a colour-accurate magic aura.
  ///
  /// The mascot artwork itself is never recoloured: doing so changes his
  /// eyes, highlights and face and makes pale colours educationally wrong.
  /// Null leaves only Boo's usual blue companion glow.
  final Color? tint;

  /// Nudges Boo to lean left or right, from -1 to 1.
  ///
  /// Used to point at the right answer when a child is stuck.
  final double leanTowards;

  final VoidCallback? onTap;

  /// The artwork. One image today, a set of poses later.
  static const String _artwork = 'assets/images/boo.png';

  @override
  State<Boo> createState() => _BooState();
}

class _BooState extends State<Boo> with TickerProviderStateMixin {
  /// Constant gentle motion: the breathing bob.
  late final AnimationController _idle;

  /// One-off reactions: hops and zooms.
  late final AnimationController _react;

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

    if (_isReaction(widget.mood)) _react.forward(from: 0);
  }

  static bool _isReaction(BooMood mood) =>
      mood == BooMood.cheer || mood == BooMood.zoom;

  @override
  void didUpdateWidget(Boo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isReaction(widget.mood) && widget.mood != oldWidget.mood) {
      _react.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget image = Image.asset(
      Boo._artwork,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // If the artwork is ever missing the app must still play, so fall back
      // to empty space rather than a broken image box.
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          SizedBox(width: widget.size, height: widget.size),
    );

    final Widget artwork = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        if (widget.tint != null)
          Container(
            width: widget.size * 0.90,
            height: widget.size * 0.90,
            decoration: BoxDecoration(
              color: widget.tint,
              shape: BoxShape.circle,
              border: Border.all(
                color: _rimFor(widget.tint!),
                width: max(3, widget.size * 0.035),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.tint!.withValues(alpha: 0.52),
                  blurRadius: widget.size * 0.18,
                  spreadRadius: widget.size * 0.035,
                ),
              ],
            ),
          ),
        image,
      ],
    );

    return Semantics(
      label: 'Boo',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_idle, _react]),
            builder: (BuildContext context, Widget? child) {
              return _posed(child!, reduceMotion);
            },
            child: artwork,
          ),
        ),
      ),
    );
  }

  Color _rimFor(Color color) {
    if (color.computeLuminance() < 0.7) return Colors.white;
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.28).clamp(0, 1)).toColor();
  }

  /// Works out how Boo is moving right now from his mood.
  Widget _posed(Widget artwork, bool reduceMotion) {
    if (reduceMotion) return artwork;

    final double breathe = sin(_idle.value * 2 * pi);
    final double react = Curves.easeOutBack.transform(
      _react.value.clamp(0.0, 1.0),
    );

    double bob = breathe * widget.size * 0.022;
    double squash = 1 + (breathe * 0.012);
    double lean = widget.leanTowards * 0.14;
    double scale = 1;

    switch (widget.mood) {
      case BooMood.idle:
        break;

      case BooMood.curious:
        lean += 0.10;
        squash = 1 + (breathe * 0.02);

      case BooMood.waiting:
        bob = breathe * widget.size * 0.014;
        squash = 1 + (breathe * 0.008);

      case BooMood.thinking:
        lean -= 0.08;
        bob = -max(0, breathe) * widget.size * 0.018;

      case BooMood.pointing:
        lean += widget.leanTowards == 0 ? 0.14 : 0;
        squash = 1 + (breathe * 0.014);

      case BooMood.mixing:
        lean += sin(_idle.value * 2 * pi) * 0.075;
        bob = -max(0, breathe) * widget.size * 0.028;

      case BooMood.speaking:
        // A small bounce on each beat, as though talking.
        bob = sin(_idle.value * 2 * pi * 6) * widget.size * 0.012;
        squash = 1 + (sin(_idle.value * 2 * pi * 6) * 0.02);

      case BooMood.cheer:
        // Up in the air, squashing on the way and settling on the way down.
        final double hop = sin(react * pi);
        bob = -hop * widget.size * 0.16;
        squash = 1 + (hop * 0.18);
        lean += sin(react * pi * 2) * 0.12;
        scale = 1 + (hop * 0.06);

      case BooMood.gentle:
        squash = 1 + (breathe * 0.008);
        bob = breathe * widget.size * 0.012;

      case BooMood.zoom:
        scale = 1 + (react * 0.10);
        squash = 1 + (sin(react * pi) * 0.08);
    }

    return Transform.translate(
      offset: Offset(0, bob),
      child: Transform.rotate(
        angle: lean,
        child: Transform.scale(
          scaleX: scale / squash,
          scaleY: scale * squash,
          child: artwork,
        ),
      ),
    );
  }
}
