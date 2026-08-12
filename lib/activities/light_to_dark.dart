import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../colors/color_library.dart';
import '../colors/shade_ladder.dart';
import '../settings/settings.dart';
import '../world/bubble.dart';

typedef ShadeRoundComplete = void Function(ColorEntry base, Offset position);

/// Put one colour's shades in order from light to dark.
///
/// A child taps any two lights to exchange them. Nothing is marked wrong:
/// correctly placed lights quietly gain a star, then Boo starts pointing out
/// the next useful move if the puzzle is taking a while.
class LightToDark extends StatefulWidget {
  const LightToDark({
    super.key,
    required this.round,
    required this.onComplete,
    required this.onBooTapped,
    this.onRoundChanged,
  });

  final ShadeRound round;
  final ShadeRoundComplete onComplete;
  final VoidCallback onBooTapped;

  /// Optional hook for previews and analytics-free session UI. The activity
  /// owns its in-progress order, so callers do not need to rebuild each move.
  final ValueChanged<ShadeRound>? onRoundChanged;

  @override
  State<LightToDark> createState() => _LightToDarkState();
}

class _LightToDarkState extends State<LightToDark> {
  late ShadeRound _round;
  int? _selectedIndex;
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
  }

  @override
  void didUpdateWidget(LightToDark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.round, oldWidget.round)) {
      _round = widget.round;
      _selectedIndex = null;
      _announced = false;
    }
  }

  void _tapShade(int index) {
    if (_round.isComplete || _announced) return;

    if (_selectedIndex == null) {
      setState(() => _selectedIndex = index);
      AudioService.instance.playSoftBubble();
      AudioService.instance.playColorNote(_round.order[index].semitone);
      return;
    }

    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      return;
    }

    final ShadeRound next = _round.swap(_selectedIndex!, index);
    setState(() {
      _round = next;
      _selectedIndex = null;
    });
    AudioService.instance.playSoftBubble();
    widget.onRoundChanged?.call(next);

    if (next.isComplete && !_announced) {
      _announced = true;
      widget.onComplete(next.base, const Offset(0.5, 0.46));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Settings settings = SettingsScope.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compactHeight = constraints.maxHeight < 360;

        return Column(
          children: <Widget>[
            _Prompt(
              base: _round.base,
              showWord: settings.words,
              compact: compactHeight,
              onTap: widget.onBooTapped,
            ),
            SizedBox(height: compactHeight ? AppSpacing.xs : AppSpacing.md),
            Expanded(
              child: _ShadeSorter(
                round: _round,
                selectedIndex: _selectedIndex,
                onTap: _tapShade,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.base,
    required this.showWord,
    required this.compact,
    required this.onTap,
  });

  final ColorEntry base;
  final bool showWord;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Put the ${base.name} shades in order from light to dark. '
          'Tap to hear again.',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Make a colour sunset',
                style: AppTheme.booLine,
                textAlign: TextAlign.center,
              ),
              if (!compact) const SizedBox(height: AppSpacing.xs),
              if (showWord)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${base.name.toUpperCase()}  •  LIGHT TO DARK',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.darkInk,
                      fontSize: compact ? 24 : 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                )
              else
                SizedBox(height: compact ? 28 : 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShadeSorter extends StatelessWidget {
  const _ShadeSorter({
    required this.round,
    required this.selectedIndex,
    required this.onTap,
  });

  final ShadeRound round;
  final int? selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final int? hintDestination = round.moveCount >= 4
        ? round.firstIncorrectIndex
        : null;
    final int? hintSource =
        round.moveCount >= 2 && round.firstIncorrectIndex != null
        ? round.currentIndexForTarget(round.firstIncorrectIndex!)
        : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double slotWidth = constraints.maxWidth / round.order.length;
        final double diameter = min(
          128.0,
          min(slotWidth * 0.88, constraints.maxHeight * 0.58),
        ).clamp(56.0, 128.0);

        return Column(
          children: <Widget>[
            const _DirectionLabels(),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> value) {
                  return FadeTransition(
                    opacity: value,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1).animate(value),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey<int>(round.moveCount),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    for (int index = 0; index < round.order.length; index++)
                      Expanded(
                        child: _ShadeChoice(
                          key: ValueKey<String>(
                            'shade-${round.order[index].rank}',
                          ),
                          tile: round.order[index],
                          position: index,
                          total: round.order.length,
                          diameter: diameter,
                          selected: selectedIndex == index,
                          correctlyPlaced:
                              round.order[index] == round.correctOrder[index],
                          hinted: hintSource == index,
                          hintDestination: hintDestination == index,
                          onTap: () => onTap(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _HelpLine(
              complete: round.isComplete,
              hasSelection: selectedIndex != null,
              moveCount: round.moveCount,
            ),
          ],
        );
      },
    );
  }
}

class _DirectionLabels extends StatelessWidget {
  const _DirectionLabels();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.light_mode_rounded,
              size: 22,
              color: AppColors.sunnyPop,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('LIGHT', style: AppTheme.microLabel),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Divider(color: AppColors.paperShadow),
              ),
            ),
            Text('DARK', style: AppTheme.microLabel),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.dark_mode_rounded,
              size: 22,
              color: AppColors.bubblePurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShadeChoice extends StatefulWidget {
  const _ShadeChoice({
    super.key,
    required this.tile,
    required this.position,
    required this.total,
    required this.diameter,
    required this.selected,
    required this.correctlyPlaced,
    required this.hinted,
    required this.hintDestination,
    required this.onTap,
  });

  final ShadeTile tile;
  final int position;
  final int total;
  final double diameter;
  final bool selected;
  final bool correctlyPlaced;
  final bool hinted;
  final bool hintDestination;
  final VoidCallback onTap;

  @override
  State<_ShadeChoice> createState() => _ShadeChoiceState();
}

class _ShadeChoiceState extends State<_ShadeChoice> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final String place = widget.position == 0
        ? 'light end'
        : widget.position == widget.total - 1
        ? 'dark end'
        : 'position ${widget.position + 1}';

    return Semantics(
      key: ValueKey<String>('shade-slot-${widget.position}'),
      button: true,
      selected: widget.selected,
      label:
          'Shade at the $place.'
          '${widget.correctlyPlaced ? ' In the right place.' : ''}'
          '${widget.hinted ? ' Boo suggests moving this shade.' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                width: widget.diameter + 10,
                height: widget.diameter + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.selected || widget.hintDestination
                        ? AppColors.bubblePurple
                        : AppColors.white.withValues(alpha: 0),
                    width: widget.selected ? 5 : 3,
                  ),
                ),
                child: Center(
                  child: SoapBubble(
                    color: widget.tile.color,
                    diameter: widget.diameter,
                    glow: widget.hinted ? 1 : 0,
                  ),
                ),
              ),
              if (widget.correctlyPlaced)
                Positioned(
                  right: 0,
                  top: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.bubbleMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpLine extends StatelessWidget {
  const _HelpLine({
    required this.complete,
    required this.hasSelection,
    required this.moveCount,
  });

  final bool complete;
  final bool hasSelection;
  final int moveCount;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;

    if (complete) {
      text = 'A perfect colour sunset!';
      icon = Icons.auto_awesome_rounded;
    } else if (hasSelection) {
      text = 'Now tap the light you want to swap with.';
      icon = Icons.swap_horiz_rounded;
    } else if (moveCount >= 4) {
      text = 'Boo marked a light and the place it belongs.';
      icon = Icons.assistant_rounded;
    } else if (moveCount >= 2) {
      text = 'The glowing light can help with the next step.';
      icon = Icons.assistant_rounded;
    } else {
      text = 'Tap two lights to swap them.';
      icon = Icons.touch_app_rounded;
    }

    return Semantics(
      liveRegion: true,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.softInk),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                text,
                style: AppTheme.microLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
