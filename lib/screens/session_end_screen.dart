import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../boo/boo.dart';
import '../boo/boo_asset_catalog.dart';
import '../colors/color_library.dart';
import '../session/session_summary.dart';
import '../world/bubble_field.dart';
import '../world/paper_background.dart';
import '../widgets/kid_controls.dart';

/// A warm session memory, never a score screen.
class SessionEndScreen extends StatefulWidget {
  const SessionEndScreen({
    super.key,
    required this.summary,
    required this.onPlayAgain,
    required this.onBackToStart,
    this.onBooTap,
  });

  final SessionSummary summary;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToStart;

  /// Lets the flow owner play Boo's optional “See you soon!” line.
  final VoidCallback? onBooTap;

  @override
  State<SessionEndScreen> createState() => _SessionEndScreenState();
}

class _SessionEndScreenState extends State<SessionEndScreen> {
  bool _showingGoodbye = false;

  bool get _isBigMilestone =>
      widget.summary.activitiesCompleted >= 10 ||
      widget.summary.successfulInteractions >= 20 ||
      widget.summary.uniqueColorCount >= 10;

  BooVisualState get _visualState {
    if (_showingGoodbye) return BooVisualState.goodbye;
    if (_isBigMilestone) return BooVisualState.bigCelebration;
    if (widget.summary.activitiesCompleted == 0 &&
        widget.summary.successfulInteractions == 0) {
      return BooVisualState.encouraging;
    }
    if (widget.summary.shadesDiscovered > 0) return BooVisualState.magic;
    return BooVisualState.celebration;
  }

  BooMood get _mood => switch (_visualState) {
    BooVisualState.goodbye || BooVisualState.encouraging => BooMood.gentle,
    BooVisualState.magic => BooMood.mixing,
    BooVisualState.bigCelebration => BooMood.zoom,
    _ => BooMood.cheer,
  };

  void _handleBooTap() {
    if (!_showingGoodbye) {
      setState(() => _showingGoodbye = true);
    }
    widget.onBooTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('session-end-screen'),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: PaperBackgroundPainter()),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: BubbleField(count: 24)),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SessionGlowPainter(
                  colors: widget.summary.uniqueColorsExplored,
                ),
              ),
            ),
          ),
          // end-master-sound-wrap
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 10, 0),
                child: MasterSoundButton(dark: false, showLabel: true),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final bool compactLandscape =
                    size.width > size.height && size.height < 520;
                final double horizontalPadding = compactLandscape ? 28 : 16;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: compactLandscape ? 10 : 18,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 920,
                        minHeight: max(
                          0,
                          constraints.maxHeight - (compactLandscape ? 20 : 36),
                        ),
                      ),
                      child: compactLandscape
                          ? _LandscapeEndContent(
                              summary: widget.summary,
                              onPlayAgain: widget.onPlayAgain,
                              onBackToStart: widget.onBackToStart,
                              onBooTap: _handleBooTap,
                              booVisualState: _visualState,
                              booMood: _mood,
                              availableSize: size,
                            )
                          : _PortraitEndContent(
                              summary: widget.summary,
                              onPlayAgain: widget.onPlayAgain,
                              onBackToStart: widget.onBackToStart,
                              onBooTap: _handleBooTap,
                              booVisualState: _visualState,
                              booMood: _mood,
                              availableSize: size,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitEndContent extends StatelessWidget {
  const _PortraitEndContent({
    required this.summary,
    required this.onPlayAgain,
    required this.onBackToStart,
    required this.onBooTap,
    required this.booVisualState,
    required this.booMood,
    required this.availableSize,
  });

  final SessionSummary summary;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToStart;
  final VoidCallback onBooTap;
  final BooVisualState booVisualState;
  final BooMood booMood;
  final Size availableSize;

  @override
  Widget build(BuildContext context) {
    final double booSize = (availableSize.shortestSide * 0.43).clamp(
      138.0,
      230.0,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const _EndHeading(),
        const SizedBox(height: 8),
        Boo(
          size: booSize,
          mood: booMood,
          visualState: booVisualState,
          onTap: onBooTap,
        ),
        const SizedBox(height: 4),
        _DiscoveredLights(summary: summary),
        const SizedBox(height: AppSpacing.md),
        _MemoryCards(summary: summary),
        const SizedBox(height: AppSpacing.lg),
        _EndActions(onPlayAgain: onPlayAgain, onBackToStart: onBackToStart),
      ],
    );
  }
}

class _LandscapeEndContent extends StatelessWidget {
  const _LandscapeEndContent({
    required this.summary,
    required this.onPlayAgain,
    required this.onBackToStart,
    required this.onBooTap,
    required this.booVisualState,
    required this.booMood,
    required this.availableSize,
  });

  final SessionSummary summary;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToStart;
  final VoidCallback onBooTap;
  final BooVisualState booVisualState;
  final BooMood booMood;
  final Size availableSize;

  @override
  Widget build(BuildContext context) {
    final double booSize = (availableSize.height * 0.48).clamp(140.0, 215.0);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const _EndHeading(),
              const SizedBox(height: 2),
              Boo(
                size: booSize,
                mood: booMood,
                visualState: booVisualState,
                onTap: onBooTap,
              ),
              _DiscoveredLights(summary: summary),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _MemoryCards(summary: summary),
              const SizedBox(height: AppSpacing.md),
              _EndActions(
                onPlayAgain: onPlayAgain,
                onBackToStart: onBackToStart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EndHeading extends StatelessWidget {
  const _EndHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.bubblePurple,
          size: 30,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'YOU MADE THE SKY GLOW!',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.moonInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
              shadows: <Shadow>[
                Shadow(
                  color: AppColors.bubblePurple.withValues(alpha: 0.30),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'YOU DID AMAZING WITH BOO!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.softInk,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DiscoveredLights extends StatelessWidget {
  const _DiscoveredLights({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final List<ColorEntry> colors = summary.uniqueColorsExplored
        .take(12)
        .toList(growable: false);
    if (colors.isEmpty) return const SizedBox(height: 8);

    return Semantics(
      label: '${summary.uniqueColorCount} colors explored this time',
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: colors
              .map((ColorEntry entry) {
                return Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: entry.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: entry.color.withValues(alpha: 0.54),
                        blurRadius: 11,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _MemoryCards extends StatelessWidget {
  const _MemoryCards({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.glassLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Memory(
                icon: Icons.palette_rounded,
                value: summary.uniqueColorCount,
                label: 'Colors\nexplored',
                color: AppColors.bubblePink,
              ),
            ),
            const _MemoryDivider(),
            Expanded(
              child: _Memory(
                icon: Icons.bubble_chart_rounded,
                value: summary.activitiesCompleted,
                label: 'Activities\nplayed',
                color: AppColors.booBlue,
              ),
            ),
            const _MemoryDivider(),
            Expanded(
              child: _Memory(
                icon: Icons.gradient_rounded,
                value: summary.shadesDiscovered,
                label: 'Shades\nexplored',
                color: AppColors.bubblePurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Memory extends StatelessWidget {
  const _Memory({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${label.replaceAll('\n', ' ')}: $value',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 23),
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.moonInk,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.softInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDivider extends StatelessWidget {
  const _MemoryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: AppColors.softInk.withValues(alpha: 0.14),
    );
  }
}

class _EndActions extends StatelessWidget {
  const _EndActions({required this.onPlayAgain, required this.onBackToStart});

  final VoidCallback onPlayAgain;
  final VoidCallback onBackToStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _EndActionButton(
          key: const Key('play-again-button'),
          label: 'PLAY AGAIN',
          semanticLabel: 'Play again with Boo',
          icon: Icons.replay_rounded,
          primary: true,
          onTap: onPlayAgain,
        ),
        const SizedBox(height: 10),
        _EndActionButton(
          key: const Key('back-to-start-button'),
          label: 'HOME',
          semanticLabel: 'Back to the Coloriboo start screen',
          icon: Icons.home_rounded,
          primary: false,
          onTap: onBackToStart,
        ),
      ],
    );
  }
}

class _EndActionButton extends StatefulWidget {
  const _EndActionButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  State<_EndActionButton> createState() => _EndActionButtonState();
}

class _EndActionButtonState extends State<_EndActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final Color foreground = widget.primary
        ? AppColors.white
        : AppColors.moonInk;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 100),
          scale: _pressed ? 0.95 : 1,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            decoration: BoxDecoration(
              gradient: widget.primary
                  ? const LinearGradient(
                      colors: <Color>[
                        AppColors.booBlue,
                        AppColors.bubblePurple,
                      ],
                    )
                  : null,
              color: widget.primary
                  ? null
                  : AppColors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.primary
                    ? AppColors.white.withValues(alpha: 0.70)
                    : AppColors.bubblePurple.withValues(alpha: 0.24),
              ),
              boxShadow: widget.primary
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.booBlue.withValues(alpha: 0.32),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(widget.icon, color: foreground, size: 27),
                const SizedBox(width: 9),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A static constellation built from only this session's actual colors.
class _SessionGlowPainter extends CustomPainter {
  const _SessionGlowPainter({required this.colors});

  final List<ColorEntry> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;
    final Paint paint = Paint();
    final int count = min(colors.length, 12);

    for (int index = 0; index < count; index++) {
      final double angle = (index / count) * 2 * pi;
      final Offset centre = Offset(
        size.width * (0.5 + cos(angle) * 0.44),
        size.height * (0.5 + sin(angle) * 0.42),
      );
      final Color color = colors[index].color;
      paint
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.12);
      canvas.drawCircle(centre, 30 + (index.isEven ? 12 : 0), paint);
      paint.color = color.withValues(alpha: 0.55);
      canvas.drawCircle(centre, index.isEven ? 4.5 : 3.2, paint);
    }
  }

  @override
  bool shouldRepaint(_SessionGlowPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
