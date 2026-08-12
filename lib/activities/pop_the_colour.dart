import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../colors/color_library.dart';
import '../colors/color_picker_logic.dart';
import '../settings/settings.dart';
import '../world/bubble.dart';
import '../world/wonder_chrome.dart';

/// What happened when a child touched a bubble.
class AnswerOutcome {
  const AnswerOutcome({
    required this.correct,
    required this.tapped,
    required this.position,
  });

  final bool correct;
  final ColorEntry tapped;

  /// Where on screen it happened, as a share of the screen, so a splash can
  /// be left behind.
  final Offset position;
}

/// "Can you find red?"
///
/// The fundamental loop of the whole app. A colour is named, several bubbles
/// drift, and the child pops the right one.
///
/// The old version of this game showed the correct colour as a swatch right
/// next to its name, which gave the answer away and meant nothing was ever
/// really being asked. Here the word stands alone.
class PopTheColour extends StatefulWidget {
  const PopTheColour({
    super.key,
    required this.round,
    required this.missCount,
    required this.onAnswer,
    required this.onBooTapped,
  });

  final ColorRound round;

  /// How many times the child has already tried this round.
  ///
  /// Drives how much help is offered.
  final int missCount;

  final void Function(AnswerOutcome outcome) onAnswer;
  final VoidCallback onBooTapped;

  @override
  State<PopTheColour> createState() => _PopTheColourState();
}

class _PopTheColourState extends State<PopTheColour>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  /// Bubbles the child has already ruled out, which have floated away.
  final Set<String> _driftedAway = <String>{};

  /// The one currently wobbling because it was just tapped.
  String? _wobbling;

  /// Clears the shiver. Cancelled on dispose so nothing tries to
  /// rebuild a screen that has gone away.
  Timer? _wobbleTimer;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat();
  }

  @override
  void didUpdateWidget(PopTheColour oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new question means everything comes back.
    if (widget.round != oldWidget.round) {
      _driftedAway.clear();
      _wobbling = null;
    }

    // Third time round, start quietly clearing the wrong answers away so the
    // child cannot help but succeed.
    if (widget.missCount >= 3 && widget.missCount != oldWidget.missCount) {
      _removeOneWrongOption();
    }
  }

  void _removeOneWrongOption() {
    final List<ColorEntry> remaining = widget.round.options
        .where(
          (ColorEntry c) =>
              c.name != widget.round.target.name &&
              !_driftedAway.contains(c.name),
        )
        .toList();

    if (remaining.length <= 1) return;

    setState(() => _driftedAway.add(remaining.first.name));
  }

  @override
  void dispose() {
    _wobbleTimer?.cancel();
    _drift.dispose();
    super.dispose();
  }

  void _handleTap(ColorEntry tapped, Offset position) {
    final bool correct = tapped.name == widget.round.target.name;
    AudioService.instance.playSoftBubble();

    if (!correct) {
      setState(() => _wobbling = tapped.name);
      _wobbleTimer?.cancel();
      _wobbleTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _wobbling = null);
      });
    }

    widget.onAnswer(
      AnswerOutcome(correct: correct, tapped: tapped, position: position),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Settings settings = SettingsScope.of(context);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final bool tablet = AppSizing.isTablet(width);

        final List<ColorEntry> visible = widget.round.options
            .where((ColorEntry c) => !_driftedAway.contains(c.name))
            .toList();

        return Column(
          children: <Widget>[
            _Prompt(
              target: widget.round.target,
              showWord: settings.words,
              width: width,
              onTap: widget.onBooTapped,
            ),
            SizedBox(height: tablet ? AppSpacing.xl : AppSpacing.md),
            Expanded(
              child: _BubbleRow(
                options: visible,
                target: widget.round.target,
                drift: _drift,
                reduceMotion: reduceMotion,
                wobbling: _wobbling,
                missCount: widget.missCount,
                onTap: _handleTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The colour a child is looking for, written large.
class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.target,
    required this.showWord,
    required this.width,
    required this.onTap,
  });

  final ColorEntry target;
  final bool showWord;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Deliberately no colour swatch here. Showing the answer beside the
    // question is what made the old game pointless.
    return ActivityPromptCard(
      eyebrow: 'Can you find',
      hero: target.name,
      showHero: showWord,
      width: width,
      semanticLabel: 'Find the colour ${target.name}. Tap to hear it again.',
      onTap: onTap,
    );
  }
}

/// The drifting answer bubbles.
class _BubbleRow extends StatelessWidget {
  const _BubbleRow({
    required this.options,
    required this.target,
    required this.drift,
    required this.reduceMotion,
    required this.wobbling,
    required this.missCount,
    required this.onTap,
  });

  final List<ColorEntry> options;
  final ColorEntry target;
  final AnimationController drift;
  final bool reduceMotion;
  final String? wobbling;
  final int missCount;
  final void Function(ColorEntry, Offset) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double shortest = min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final int count = max(options.length, 1);

        // Hard rounds wrap onto two rows when one row cannot preserve the
        // full 72px child hit target plus a clean gap.
        final int perRow = constraints.maxWidth < count * 88
            ? (count / 2).ceil()
            : count;
        final int rows = (count / perRow).ceil();
        final double cellWidth = constraints.maxWidth / perRow;
        final double cellHeight = constraints.maxHeight / rows;
        double diameter = min(cellWidth - 10, cellHeight - 8);
        diameter = min(diameter, shortest * 0.46);
        diameter = diameter.clamp(44.0, 145.0);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BubbleOrbitPainter(count: options.length),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: reduceMotion
                  ? const AlwaysStoppedAnimation<double>(0)
                  : drift,
              builder: (BuildContext context, Widget? child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    for (int i = 0; i < options.length; i++)
                      _positioned(
                        context: context,
                        constraints: constraints,
                        entry: options[i],
                        index: i,
                        total: options.length,
                        diameter: diameter,
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _positioned({
    required BuildContext context,
    required BoxConstraints constraints,
    required ColorEntry entry,
    required int index,
    required int total,
    required double diameter,
  }) {
    final int perRow = constraints.maxWidth < total * 88
        ? (total / 2).ceil()
        : total;
    final int rows = (total / perRow).ceil();
    final int row = index ~/ perRow;
    final int column = index % perRow;
    final int inThisRow = min(perRow, total - row * perRow);
    final double slot = (column + 0.5) / inThisRow;
    final double sway =
        (reduceMotion ? 0 : sin((drift.value * 2 * pi) + (index * 1.7))) *
        (diameter * 0.05);
    final double bob =
        (reduceMotion ? 0 : cos((drift.value * 2 * pi) + (index * 2.3))) *
        (diameter * 0.08);

    // Sit every other bubble higher than its neighbours. Bubbles rising
    // through water are never in a tidy line, and staggering them fills the
    // space so the screen looks like a world rather than a row of buttons.
    final double rowHeight = constraints.maxHeight / rows;
    final double spare = max(0.0, rowHeight - diameter);
    final double stagger = (index.isEven ? -1 : 1) * (spare * 0.08);

    final double left = (slot * constraints.maxWidth) - (diameter / 2) + sway;
    final double top = row * rowHeight + (spare / 2) + stagger + bob;
    final double tapExtent = max(diameter, AppSpacing.minTouchTarget);

    final bool isWobbling = wobbling == entry.name;
    final bool isTarget = entry.name == target.name;

    // After a second miss the right answer starts to glow. Boo is helping,
    // not judging.
    final double glow = (isTarget && missCount >= 2) ? 1 : 0;

    return Positioned(
      left: (left - (tapExtent - diameter) / 2).clamp(
        0.0,
        max(0.0, constraints.maxWidth - tapExtent),
      ),
      top: (top - (tapExtent - diameter) / 2).clamp(
        0.0,
        max(0.0, constraints.maxHeight - tapExtent),
      ),
      child: _WobbleOnMiss(
        active: isWobbling,
        child: Builder(
          builder: (BuildContext bubbleContext) {
            return SoapBubble(
              color: entry.color,
              diameter: diameter,
              glow: glow,
              semanticLabel: entry.name,
              onTap: () {
                final RenderBox? box =
                    bubbleContext.findRenderObject() as RenderBox?;
                final RenderBox? overlay =
                    Overlay.of(context).context.findRenderObject()
                        as RenderBox?;

                Offset fraction = const Offset(0.5, 0.5);
                if (box != null && overlay != null && overlay.hasSize) {
                  final Offset global = box.localToGlobal(
                    box.size.center(Offset.zero),
                  );
                  fraction = Offset(
                    (global.dx / overlay.size.width).clamp(0.0, 1.0),
                    (global.dy / overlay.size.height).clamp(0.0, 1.0),
                  );
                }

                AudioService.instance.playColorNote(entry.semitone);
                onTap(entry, fraction);
              },
            );
          },
        ),
      ),
    );
  }
}

class _BubbleOrbitPainter extends CustomPainter {
  const _BubbleOrbitPainter({required this.count});

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.bubblePurple.withValues(alpha: 0.12);
    final Rect orbit = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.86,
      height: size.height * 0.58,
    );
    canvas.drawArc(orbit, 0.12, pi * 0.72, false, line);
    canvas.drawArc(orbit, pi + 0.12, pi * 0.72, false, line);

    final Paint dot = Paint()
      ..color = AppColors.softInk.withValues(alpha: 0.10);
    for (int i = 0; i < count; i++) {
      final double angle = (2 * pi * i / max(count, 1)) - pi / 2;
      canvas.drawCircle(
        Offset(
          orbit.center.dx + cos(angle) * orbit.width / 2,
          orbit.center.dy + sin(angle) * orbit.height / 2,
        ),
        3,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_BubbleOrbitPainter oldDelegate) =>
      oldDelegate.count != count;
}

/// Shakes a bubble gently when it was not the one.
///
/// It stays exactly where it was. Nothing is taken away, nothing turns red,
/// and the child can simply try again.
class _WobbleOnMiss extends StatefulWidget {
  const _WobbleOnMiss({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_WobbleOnMiss> createState() => _WobbleOnMissState();
}

class _WobbleOnMissState extends State<_WobbleOnMiss>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(_WobbleOnMiss oldWidget) {
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

        // A quick shiver that settles.
        final double decay = 1 - _controller.value;
        final double shake = sin(_controller.value * pi * 6) * 10 * decay;

        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: widget.child,
    );
  }
}
