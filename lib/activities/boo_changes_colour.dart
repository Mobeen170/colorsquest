import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../boo/boo.dart';
import '../boo/boo_asset_catalog.dart';
import '../colors/color_library.dart';
import '../colors/color_picker_logic.dart';
import '../settings/settings.dart';
import '../world/bubble.dart';
import 'pop_the_colour.dart';

/// "What colour is Boo's magic?"
///
/// Boo drifts to the middle inside an exact, solid colour aura. The child
/// says which one by popping the matching bubble.
///
/// Boo's face and iridescent artwork are deliberately never recoloured. A
/// whole-image tint corrupts white, black and the facial features, while the
/// dedicated aura remains color-accurate for every taught colour.
class BooChangesColour extends StatefulWidget {
  const BooChangesColour({
    super.key,
    required this.round,
    required this.missCount,
    required this.onAnswer,
    required this.onBooTapped,
  });

  final ColorRound round;
  final int missCount;
  final void Function(AnswerOutcome outcome) onAnswer;
  final VoidCallback onBooTapped;

  @override
  State<BooChangesColour> createState() => _BooChangesColourState();
}

class _BooChangesColourState extends State<BooChangesColour>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transition;
  late Color _shownColor;
  late ColorEntry _shownEntry;

  String? _wobbling;

  /// Clears the shiver. Cancelled on dispose so nothing tries to
  /// rebuild a screen that has gone away.
  Timer? _wobbleTimer;

  @override
  void initState() {
    super.initState();

    _shownColor = widget.round.target.color;
    _shownEntry = widget.round.target;
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(BooChangesColour oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.round != oldWidget.round) {
      _shownColor = widget.round.target.color;
      _shownEntry = widget.round.target;
      _wobbling = null;
      _transition.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wobbleTimer?.cancel();
    _transition.dispose();
    super.dispose();
  }

  void _handleTap(ColorEntry entry, Offset position) {
    final bool correct = entry.name == widget.round.target.name;
    AudioService.instance.playSoftBubble();

    if (!correct) {
      setState(() => _wobbling = entry.name);
      _wobbleTimer?.cancel();
      _wobbleTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _wobbling = null);
      });
    }

    AudioService.instance.playColorNote(entry.semitone);
    widget.onAnswer(
      AnswerOutcome(correct: correct, tapped: entry, position: position),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Settings settings = SettingsScope.of(context);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double shortest = min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        final bool compact = constraints.maxHeight < 430;
        final int answerColumns = constraints.maxWidth < 430 ? 3 : 5;

        return Column(
          children: <Widget>[
            if (settings.words)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'What colour is my magic?',
                  style: AppTheme.booLine,
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),

            // Boo, front and centre, wearing the colour in question.
            Expanded(
              flex: compact ? 4 : 5,
              child: Center(
                child: AnimatedBuilder(
                  animation: reduceMotion
                      ? const AlwaysStoppedAnimation<double>(1)
                      : _transition,
                  builder: (BuildContext context, Widget? child) {
                    final double t = reduceMotion
                        ? 1
                        : Curves.easeInOut.transform(_transition.value);

                    return Transform.scale(
                      scale: 0.86 + (0.14 * t),
                      child: Boo(
                        // A real painted family asset supplies Boo's body;
                        // the exact target shade remains a flat, accurate aura.
                        tint: _shownColor,
                        color: _shownEntry,
                        visualState: BooVisualState.magic,
                        size: min(
                          shortest * 0.50,
                          constraints.maxHeight * 0.48,
                        ),
                        mood: BooMood.zoom,
                        onTap: widget.onBooTapped,
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              flex: compact ? 5 : 4,
              child: _answers(constraints, answerColumns),
            ),
          ],
        );
      },
    );
  }

  Widget _answers(BoxConstraints outer, int maxColumns) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<ColorEntry> options = widget.round.options;

        final int columns = min(maxColumns, options.length);
        final int rows = (options.length / columns).ceil();
        final double cellWidth = constraints.maxWidth / columns;
        final double cellHeight = constraints.maxHeight / rows;
        final double diameter = min(
          min(cellWidth - 10, cellHeight - 8),
          112.0,
        ).clamp(44.0, 112.0);

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 0,
            runSpacing: 2,
            children: <Widget>[
              for (final ColorEntry entry in options)
                SizedBox(
                  width: cellWidth,
                  height: cellHeight,
                  child: Center(
                    child: _Shiver(
                      active: _wobbling == entry.name,
                      child: Builder(
                        builder: (BuildContext bubbleContext) {
                          return SoapBubble(
                            color: entry.color,
                            diameter: diameter,
                            glow:
                                (entry.name == widget.round.target.name &&
                                    widget.missCount >= 2)
                                ? 1
                                : 0,
                            semanticLabel: entry.name,
                            onTap: () => _handleTap(
                              entry,
                              _screenFraction(bubbleContext, context),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Where a widget sits, as a share of the screen.
Offset _screenFraction(BuildContext widgetContext, BuildContext screenContext) {
  final RenderBox? box = widgetContext.findRenderObject() as RenderBox?;
  final RenderBox? overlay =
      Overlay.of(screenContext).context.findRenderObject() as RenderBox?;

  if (box == null || overlay == null || !overlay.hasSize || !box.hasSize) {
    return const Offset(0.5, 0.5);
  }

  final Offset global = box.localToGlobal(box.size.center(Offset.zero));
  return Offset(
    (global.dx / overlay.size.width).clamp(0.0, 1.0),
    (global.dy / overlay.size.height).clamp(0.0, 1.0),
  );
}

/// A gentle shake, used instead of any kind of error state.
class _Shiver extends StatefulWidget {
  const _Shiver({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Shiver> createState() => _ShiverState();
}

class _ShiverState extends State<_Shiver> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.active) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(_Shiver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        if (_controller.value == 0) return child!;
        final double decay = 1 - _controller.value;
        return Transform.translate(
          offset: Offset(sin(_controller.value * pi * 6) * 9 * decay, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
