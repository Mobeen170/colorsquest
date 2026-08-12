import 'dart:math';

import 'package:colorsquest/boo/boo_asset_catalog.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:flutter/material.dart';

/// What Boo is doing.
///
/// Artwork and motion are intentionally separate: [BooVisualState] picks Boo's
/// expression/pose while [BooMood] controls the gentle movement around it.
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

  /// Delighted. A big buoyant hop.
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
    this.visualState = BooVisualState.idle,
    this.colorVariant,
    this.color,
    this.tint,
    this.leanTowards = 0,
    this.onTap,
  });

  /// Boo's drawn size in logical pixels.
  final double size;

  final BooMood mood;

  /// Chooses Boo's expression/pose without changing his movement.
  final BooVisualState visualState;

  /// Selects one of Boo's ten educational colour artworks.
  ///
  /// A [color] takes precedence when both are supplied.
  final BooColorVariant? colorVariant;

  /// Selects the nearest core Boo artwork for an exact library colour.
  ///
  /// Keep [tint] set to the exact colour too, so extended shades retain a
  /// colour-accurate aura without recolouring Boo's eyes or highlights.
  final ColorEntry? color;

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

  /// Legacy artwork kept as a safe fallback if a production asset cannot load.
  static const String artworkPath = BooAssetCatalog.fallbackPath;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
      _react.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  static bool _isReaction(BooMood mood) =>
      mood == BooMood.cheer || mood == BooMood.zoom;

  @override
  void didUpdateWidget(Boo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isReaction(widget.mood) &&
        widget.mood != oldWidget.mood &&
        !MediaQuery.disableAnimationsOf(context)) {
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
    final BooAssetSpec spec = BooAssetCatalog.resolve(
      state: widget.visualState,
      variant: widget.colorVariant,
      color: widget.color,
    );

    final Widget selectedImage = _assetFrame(spec);
    final Widget image = reduceMotion
        ? selectedImage
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[...previousChildren, ?currentChild],
                  );
                },
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: selectedImage,
          );

    final Widget artwork = SizedBox.square(
      dimension: widget.size,
      child: Stack(
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
      ),
    );

    return Semantics(
      label: 'Boo',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: widget.size,
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
      ),
    );
  }

  Widget _assetFrame(BooAssetSpec spec) {
    return SizedBox.square(
      key: ValueKey<String>('boo-artwork-${spec.path}'),
      dimension: widget.size,
      child: Image.asset(
        spec.path,
        width: widget.size,
        height: widget.size,
        cacheWidth: BooAssetCatalog.decodeWidth,
        alignment: spec.alignment,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        frameBuilder:
            (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              // Viewport compensation applies only to this successfully built
              // production asset. Error fallbacks get their own metadata.
              return Transform.scale(
                scale: spec.displayScale,
                alignment: spec.alignment,
                child: child,
              );
            },
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return _canonicalFallback(spec);
        },
      ),
    );
  }

  @visibleForTesting
  Widget buildFallbackFor(BooAssetSpec failedSpec) {
    return _canonicalFallback(failedSpec);
  }

  Widget _canonicalFallback(BooAssetSpec failedSpec) {
    if (failedSpec.path == BooAssetCatalog.canonical.path) {
      return _legacyFallback();
    }

    return Image.asset(
      BooAssetCatalog.canonical.path,
      width: widget.size,
      height: widget.size,
      cacheWidth: BooAssetCatalog.decodeWidth,
      alignment: BooAssetCatalog.canonical.alignment,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return Transform.scale(
          scale: BooAssetCatalog.canonical.displayScale,
          alignment: BooAssetCatalog.canonical.alignment,
          child: child,
        );
      },
      errorBuilder: (_, _, _) => _legacyFallback(),
    );
  }

  Widget _legacyFallback() {
    return Image.asset(
      BooAssetCatalog.fallbackPath,
      width: widget.size,
      height: widget.size,
      cacheWidth: BooAssetCatalog.decodeWidth,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => SizedBox.square(dimension: widget.size),
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
    double lean = widget.leanTowards * 0.14;
    double scale = 1 + (breathe * 0.008);

    switch (widget.mood) {
      case BooMood.idle:
        break;

      case BooMood.curious:
        lean += 0.10;
        scale = 1 + (breathe * 0.012);

      case BooMood.waiting:
        bob = breathe * widget.size * 0.014;
        scale = 1 + (breathe * 0.005);

      case BooMood.thinking:
        lean -= 0.08;
        bob = -max(0, breathe) * widget.size * 0.018;

      case BooMood.pointing:
        lean += widget.leanTowards == 0 ? 0.14 : 0;
        scale = 1 + (breathe * 0.008);

      case BooMood.mixing:
        lean += sin(_idle.value * 2 * pi) * 0.075;
        bob = -max(0, breathe) * widget.size * 0.028;

      case BooMood.speaking:
        // A small bounce on each beat, as though talking.
        bob = sin(_idle.value * 2 * pi * 6) * widget.size * 0.012;
        scale = 1 + (sin(_idle.value * 2 * pi * 6) * 0.012);

      case BooMood.cheer:
        // Up in the air, growing slightly and settling on the way down.
        final double hop = sin(react * pi);
        bob = -hop * widget.size * 0.16;
        lean += sin(react * pi * 2) * 0.12;
        scale = 1 + (hop * 0.10);

      case BooMood.gentle:
        bob = breathe * widget.size * 0.012;
        scale = 1 + (breathe * 0.004);

      case BooMood.zoom:
        scale = 1 + (react * 0.10);
    }

    return Transform.translate(
      offset: Offset(0, bob),
      child: Transform.rotate(
        angle: lean,
        child: Transform.scale(scale: scale, child: artwork),
      ),
    );
  }
}
