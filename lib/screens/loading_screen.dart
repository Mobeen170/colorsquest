import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../widgets/coloriboo_loading_overlay.dart';
import '../world/bubble_field.dart';
import '../world/paper_background.dart';

typedef ColoribooLoadingTask = Future<void> Function();

/// Runs real world-entry work behind a brief branded transition.
///
/// Errors and timeouts are reported through [onError] but never strand the
/// child on this screen. [onComplete] is always called once while mounted.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.task,
    required this.onComplete,
    this.onError,
    this.onTwinkle,
    this.minimumDisplay = const Duration(milliseconds: 620),
    this.maximumTaskWait = const Duration(seconds: 8),
  });

  final ColoribooLoadingTask task;
  final VoidCallback onComplete;
  final ValueChanged<Object>? onError;
  final VoidCallback? onTwinkle;

  /// Prevents a one-frame flash when initialization is already warm.
  final Duration minimumDisplay;

  /// Safety boundary for plugins that neither complete nor throw.
  final Duration maximumTaskWait;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const List<String> _messages = <String>[
    'Waking the colors...',
    'Polishing the bubbles...',
    'Lighting Boo’s garden...',
    'Almost ready!',
  ];

  Timer? _copyTimer;
  bool _started = false;
  bool _complete = false;
  int _messageIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _runTask();
  }

  Future<void> _runTask() async {
    widget.onTwinkle?.call();
    _copyTimer = Timer.periodic(const Duration(milliseconds: 720), (_) {
      if (!mounted || _complete) return;
      widget.onTwinkle?.call();
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });

    final Duration minimumDuration = widget.minimumDisplay.isNegative
        ? Duration.zero
        : widget.minimumDisplay;
    final Duration maximumWait = widget.maximumTaskWait <= Duration.zero
        ? const Duration(seconds: 8)
        : widget.maximumTaskWait;
    final Future<void> minimum = Future<void>.delayed(minimumDuration);
    final Future<void> operation = Future<void>.sync(widget.task).timeout(
      maximumWait,
      onTimeout: () {
        widget.onError?.call(
          TimeoutException('Coloriboo world entry exceeded $maximumWait.'),
        );
      },
    );

    try {
      await Future.wait<void>(<Future<void>>[operation, minimum]);
    } catch (error) {
      widget.onError?.call(error);
      await minimum;
    }

    if (!mounted) return;
    _copyTimer?.cancel();
    setState(() {
      _complete = true;
      _messageIndex = _messages.length - 1;
    });

    final bool reduced = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(
      reduced ? Duration.zero : const Duration(milliseconds: 240),
    );
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      key: const Key('loading-screen'),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: PaperBackgroundPainter()),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: BubbleField(count: 16)),
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
                final double loaderSize = compactLandscape
                    ? (size.height * 0.62).clamp(160.0, 230.0)
                    : (size.shortestSide * 0.62).clamp(184.0, 268.0);

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: compactLandscape
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                ColoribooOrbitLoader(
                                  message: _messages[_messageIndex],
                                  size: loaderSize,
                                  complete: _complete,
                                ),
                                const SizedBox(width: AppSpacing.xxl),
                                const Flexible(child: _WorldEntryCopy()),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const _WorldEntryCopy(),
                                const SizedBox(height: AppSpacing.lg),
                                ColoribooOrbitLoader(
                                  message: _messages[_messageIndex],
                                  size: loaderSize,
                                  complete: _complete,
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                opacity: _complete ? 0.54 : 0,
                child: const ColoredBox(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldEntryCopy extends StatelessWidget {
  const _WorldEntryCopy();

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
        const SizedBox(height: 8),
        const Text(
          'BOO’S TWILIGHT\nPRISM GARDEN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.moonInk,
            fontSize: 23,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Follow the little lights in.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.softInk.withValues(alpha: 0.92),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
