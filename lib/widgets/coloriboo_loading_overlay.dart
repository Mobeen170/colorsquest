import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../boo/boo.dart';
import '../boo/boo_asset_catalog.dart';

/// A compact, branded wait state for real asynchronous work.
///
/// The child underneath cannot interact while [isLoading] is true. The
/// overlay intentionally owns no Future, so the caller remains responsible
/// for the operation and error handling.
class ColoribooLoadingOverlay extends StatelessWidget {
  const ColoribooLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = 'Waking the colors...',
  });

  final bool isLoading;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ExcludeSemantics(excluding: isLoading, child: child),
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.twilight.withValues(alpha: 0.78),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.twilightLift.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColors.glassLine.withValues(alpha: 0.52),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.bubblePurple.withValues(
                                alpha: 0.30,
                              ),
                              blurRadius: 34,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: ColoribooOrbitLoader(
                            message: message,
                            size: 146,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Boo and six prism lights: Coloriboo's non-generic loading indicator.
class ColoribooOrbitLoader extends StatefulWidget {
  const ColoribooOrbitLoader({
    super.key,
    required this.message,
    this.size = 210,
    this.complete = false,
    this.visualState = BooVisualState.loading,
  });

  final String message;
  final double size;
  final bool complete;
  final BooVisualState visualState;

  @override
  State<ColoribooOrbitLoader> createState() => _ColoribooOrbitLoaderState();
}

class _ColoribooOrbitLoaderState extends State<ColoribooOrbitLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduceMotion = false;

  static const List<Color> _prismColors = <Color>[
    AppColors.booBlue,
    AppColors.bubbleMint,
    AppColors.sunnyPop,
    AppColors.bubblePink,
    AppColors.bubblePurple,
    AppColors.white,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
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
    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.complete
          ? 'Boo’s garden is ready'
          : 'Preparing Boo’s garden',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double t = _reduceMotion ? 0.16 : _controller.value;
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Transform.rotate(
                      angle: _reduceMotion ? 0 : t * 2 * pi,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          for (int index = 0; index < 6; index++)
                            Transform.translate(
                              offset: Offset.fromDirection(
                                (2 * pi * index / 6) - pi / 2,
                                widget.size * 0.40,
                              ),
                              child: _PrismLight(
                                color: _prismColors[index],
                                lit:
                                    widget.complete ||
                                    index == ((t * 6).floor() % 6),
                                size: widget.size * 0.105,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Boo(
                      size: widget.size * 0.63,
                      mood: widget.complete ? BooMood.cheer : BooMood.waiting,
                      visualState: widget.complete
                          ? BooVisualState.celebration
                          : widget.visualState,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ExcludeSemantics(
            child: AnimatedSwitcher(
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              child: Text(
                widget.message,
                key: ValueKey<String>(widget.message),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.starlight,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrismLight extends StatelessWidget {
  const _PrismLight({
    required this.color,
    required this.lit,
    required this.size,
  });

  final Color color;
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      width: lit ? size * 1.25 : size,
      height: lit ? size * 1.25 : size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: lit ? 0.98 : 0.22),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: lit ? 0.92 : 0.24),
          width: lit ? 2 : 1,
        ),
        boxShadow: lit
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.72),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
    );
  }
}
