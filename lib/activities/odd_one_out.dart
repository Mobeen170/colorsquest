import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../colors/color_library.dart';
import '../settings/settings.dart';
import '../world/bubble.dart';
import 'pop_the_colour.dart';

/// "Which one is different?"
///
/// Several bubbles of one colour and a single bubble of another. The child
/// pops the odd one.
///
/// This is the most inclusive activity in the app, because it needs no colour
/// vocabulary at all. A three year old who knows no colour names can still
/// play it and still be right. Boo names both colours afterwards, so it
/// quietly teaches the words anyway.
class OddOneOut extends StatefulWidget {
  const OddOneOut({
    super.key,
    required this.common,
    required this.odd,
    required this.total,
    required this.missCount,
    required this.onAnswer,
    required this.onBooTapped,
  });

  final ColorEntry common;
  final ColorEntry odd;

  /// How many bubbles altogether, including the odd one.
  final int total;

  final int missCount;
  final void Function(AnswerOutcome outcome) onAnswer;
  final VoidCallback onBooTapped;

  @override
  State<OddOneOut> createState() => _OddOneOutState();
}

class _OddOneOutState extends State<OddOneOut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  /// Which slot holds the odd bubble this time.
  late int _oddSlot;

  String? _wobbling;

  /// Clears the shiver. Cancelled on dispose so nothing tries to
  /// rebuild a screen that has gone away.
  Timer? _wobbleTimer;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _oddSlot = Random().nextInt(widget.total);
  }

  @override
  void didUpdateWidget(OddOneOut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.odd != oldWidget.odd || widget.common != oldWidget.common) {
      _oddSlot = Random().nextInt(widget.total);
      _wobbling = null;
    }
  }

  @override
  void dispose() {
    _wobbleTimer?.cancel();
    _drift.dispose();
    super.dispose();
  }

  void _handleTap(int slot, ColorEntry entry, Offset position) {
    final bool correct = slot == _oddSlot;

    if (!correct) {
      setState(() => _wobbling = '$slot');
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
      builder: (BuildContext context, BoxConstraints outer) {
        return Column(
          children: <Widget>[
            Semantics(
              label: 'Find the bubble that is different. Tap to hear again.',
              button: true,
              child: GestureDetector(
                onTap: widget.onBooTapped,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Which one is', style: AppTheme.booLine),
                      const SizedBox(height: AppSpacing.xs),
                      if (settings.words)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'DIFFERENT?',
                            style: AppTheme.heroWord(outer.maxWidth),
                            maxLines: 1,
                          ),
                        )
                      else
                        SizedBox(
                          height: AppSizing.heroTextSize(outer.maxWidth) * 1.1,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _grid()),
          ],
        );
      },
    );
  }

  Widget _grid() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Lay the bubbles out in up to two rows so six still fit on a narrow
        // phone without overflowing.
        final int perRow = widget.total <= 3
            ? widget.total
            : (widget.total / 2).ceil();
        final int rows = (widget.total / perRow).ceil();

        double diameter = AppSizing.bubbleDiameter(
          constraints.maxWidth,
          perRow,
        );
        diameter = min(diameter, (constraints.maxHeight / rows) * 0.78);
        diameter = max(diameter, 56);

        return AnimatedBuilder(
          animation: _drift,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: <Widget>[
                for (int i = 0; i < widget.total; i++)
                  _bubbleAt(
                    slot: i,
                    perRow: perRow,
                    rows: rows,
                    diameter: diameter,
                    constraints: constraints,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bubbleAt({
    required int slot,
    required int perRow,
    required int rows,
    required double diameter,
    required BoxConstraints constraints,
  }) {
    final int row = slot ~/ perRow;
    final int column = slot % perRow;

    // The last row may hold fewer bubbles, so it is centred on its own.
    final int inThisRow = min(perRow, widget.total - (row * perRow));

    final double slotX = (column + 0.5) / inThisRow;
    final double slotY = rows == 1 ? 0.5 : (row + 0.5) / rows;

    final double sway =
        sin((_drift.value * 2 * pi) + (slot * 1.9)) * (diameter * 0.05);
    final double bob =
        cos((_drift.value * 2 * pi) + (slot * 2.1)) * (diameter * 0.09);

    final bool isOdd = slot == _oddSlot;
    final ColorEntry entry = isOdd ? widget.odd : widget.common;

    final double left = (slotX * constraints.maxWidth) - (diameter / 2) + sway;
    final double top = (slotY * constraints.maxHeight) - (diameter / 2) + bob;

    return Positioned(
      left: left.clamp(0.0, max(0.0, constraints.maxWidth - diameter)),
      top: top.clamp(0.0, max(0.0, constraints.maxHeight - diameter)),
      child: _WobbleWrapper(
        active: _wobbling == '$slot',
        child: Builder(
          builder: (BuildContext bubbleContext) {
            return SoapBubble(
              color: entry.color,
              diameter: diameter,
              glow: (isOdd && widget.missCount >= 2) ? 1 : 0,
              semanticLabel: entry.name,
              onTap: () =>
                  _handleTap(slot, entry, _fractionOf(bubbleContext, context)),
            );
          },
        ),
      ),
    );
  }
}

/// Where a widget sits on screen, as a share of the whole screen.
Offset _fractionOf(BuildContext widgetContext, BuildContext screenContext) {
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

/// A quick, harmless shiver.
class _WobbleWrapper extends StatefulWidget {
  const _WobbleWrapper({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_WobbleWrapper> createState() => _WobbleWrapperState();
}

class _WobbleWrapperState extends State<_WobbleWrapper>
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
  void didUpdateWidget(_WobbleWrapper oldWidget) {
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
          offset: Offset(sin(_controller.value * pi * 6) * 10 * decay, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
