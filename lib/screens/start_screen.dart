import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../boo/boo.dart';
import '../boo/boo_asset_catalog.dart';
import '../world/bubble_field.dart';
import '../world/paper_background.dart';
import '../widgets/kid_controls.dart';

/// The quiet, premium doorway into Boo's Twilight Prism Garden.
///
/// Navigation and sound stay with the app-flow owner. [onPlay] fires after a
/// short mascot reaction, giving the owner one clear place to play the start
/// sound and show [LoadingScreen].
class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    required this.onPlay,
    this.onPlayFeedback,
    this.onSettings,
  });

  final VoidCallback onPlay;
  final VoidCallback? onPlayFeedback;
  final VoidCallback? onSettings;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  Timer? _playTimer;
  bool _starting = false;
  bool _pressed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _glowController.stop();
    } else if (!_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }
  }

  void _beginPlay() {
    if (_starting) return;
    widget.onPlayFeedback?.call();
    setState(() {
      _starting = true;
      _pressed = false;
    });

    _playTimer = Timer(
      _reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      widget.onPlay,
    );
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('start-screen'),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: PaperBackgroundPainter()),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: BubbleField(count: 20)),
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
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compactLandscape ? 34 : 18,
                        compactLandscape ? 10 : 20,
                        compactLandscape ? 34 : 18,
                        compactLandscape ? 10 : 18,
                      ),
                      child: compactLandscape
                          ? _landscapeContent(size)
                          : _portraitContent(size),
                    ),
                  ),
                );
              },
            ),
          ),
          // start-master-sound-wrap
          const SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 0, 0),
                child: MasterSoundButton(dark: false, showLabel: true),
              ),
            ),
          ),
          if (widget.onSettings != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  label: 'Sound and grown-up settings',
                  button: true,
                  child: IconButton(
                    onPressed: _starting ? null : widget.onSettings,
                    tooltip: 'Sound and settings',
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    icon: const Icon(Icons.volume_up_rounded),
                    color: AppColors.moonInk,
                    disabledColor: AppColors.softInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _portraitContent(Size size) {
    final double booSize = (size.shortestSide * 0.54).clamp(154.0, 260.0);
    final double titleSize = (size.width * 0.145).clamp(42.0, 66.0);

    return Column(
      children: <Widget>[
        const Spacer(flex: 2),
        _BrandTitle(titleSize: titleSize),
        const SizedBox(height: 8),
        Flexible(flex: 8, child: Center(child: _booHero(booSize))),
        const Text(
          'Explore colors with Boo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.softInk,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _playButton(),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _landscapeContent(Size size) {
    final double booSize = (size.height * 0.62).clamp(160.0, 260.0);
    final double titleSize = (size.height * 0.13).clamp(38.0, 58.0);

    return Row(
      children: <Widget>[
        Expanded(child: Center(child: _booHero(booSize))),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _BrandTitle(titleSize: titleSize),
              const SizedBox(height: 14),
              const Text(
                'Explore colors with Boo',
                style: TextStyle(
                  color: AppColors.softInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _playButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _booHero(double size) {
    return AnimatedScale(
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      scale: _starting ? 1.08 : 1,
      child: Boo(
        size: size,
        mood: _starting ? BooMood.cheer : BooMood.idle,
        visualState: BooVisualState.welcome,
      ),
    );
  }

  Widget _playButton() {
    return Semantics(
      label: _starting ? 'Entering Boo’s garden' : 'Play',
      button: true,
      enabled: !_starting,
      child: GestureDetector(
        key: const Key('play-button'),
        behavior: HitTestBehavior.opaque,
        onTapDown: _starting ? null : (_) => setState(() => _pressed = true),
        onTapCancel: _starting ? null : () => setState(() => _pressed = false),
        onTapUp: _starting ? null : (_) => setState(() => _pressed = false),
        onTap: _starting ? null : _beginPlay,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (BuildContext context, Widget? child) {
            final double glow = _reduceMotion ? 0.35 : _glowController.value;
            return AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                width: min(MediaQuery.sizeOf(context).width - 64, 330),
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget + 10,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.booBlue, AppColors.bubblePurple],
                  ),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.78),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.booBlue.withValues(
                        alpha: 0.28 + (glow * 0.20),
                      ),
                      blurRadius: 22 + (glow * 12),
                      spreadRadius: 2 + (glow * 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      _starting
                          ? Icons.auto_awesome_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.white,
                      size: 34,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _starting ? 'LET’S GO!' : 'PLAY',
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'COLORIBOO',
            maxLines: 1,
            style: TextStyle(
              color: AppColors.moonInk,
              fontSize: titleSize,
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.6,
              shadows: <Shadow>[
                Shadow(
                  color: AppColors.booBlue.withValues(alpha: 0.34),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pop. Play. Learn Colors!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.moonInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
