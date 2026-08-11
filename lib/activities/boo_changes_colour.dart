import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../boo/boo.dart';
import '../colors/color_library.dart';
import '../colors/color_picker_logic.dart';
import '../settings/settings.dart';
import '../world/bubble.dart';
import 'pop_the_colour.dart';

/// "What colour am I?"
///
/// Boo drifts to the middle, grows, and turns a colour. The child says which
/// one by popping the matching bubble.
///
/// This activity only exists because Boo is drawn in code rather than loaded
/// from pictures. A folder of images could never show him as all fifty
/// colours, and it is the moment the mascot stops being decoration and
/// becomes the lesson itself.
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

  String? _wobbling;

  /// Clears the shiver. Cancelled on dispose so nothing tries to
  /// rebuild a screen that has gone away.
  Timer? _wobbleTimer;

  @override
  void initState() {
    super.initState();

    _shownColor = widget.round.target.color;
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double shortest = min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Column(
          children: <Widget>[
            if (settings.words)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'What colour am I?',
                  style: AppTheme.booLine,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),

            // Boo, front and centre, wearing the colour in question.
            Expanded(
              flex: 5,
              child: Center(
                child: AnimatedBuilder(
                  animation: _transition,
                  builder: (BuildContext context, Widget? child) {
                    final double t = Curves.easeInOut.transform(
                      _transition.value,
                    );

                    return Transform.scale(
                      scale: 0.86 + (0.14 * t),
                      child: Boo(
                        color: _shownColor,
                        size: shortest * 0.52,
                        mood: BooMood.zoom,
                        onTap: widget.onBooTapped,
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(flex: 4, child: _answers(constraints)),
          ],
        );
      },
    );
  }

  Widget _answers(BoxConstraints outer) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<ColorEntry> options = widget.round.options;

        double diameter = AppSizing.bubbleDiameter(
          constraints.maxWidth,
          options.length,
        );
        diameter = min(diameter, constraints.maxHeight * 0.8);
        diameter = max(diameter, 56);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (final ColorEntry entry in options)
              Flexible(
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
          ],
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
