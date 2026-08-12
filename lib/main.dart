import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'audio/audio_service.dart';
import 'boo/boo.dart';
import 'dreamscape.dart';
import 'screens/loading_screen.dart';
import 'screens/session_end_screen.dart';
import 'screens/start_screen.dart';
import 'session/session_summary.dart';
import 'settings/parent_panel.dart';
import 'settings/settings.dart';

void main() {
  runApp(const ColorGameApp());
}

/// Coloriboo — Pop. Play. Learn Colors.
class ColorGameApp extends StatefulWidget {
  const ColorGameApp({
    super.key,
    this.worldInitializer,
    this.minimumLoadingDisplay = const Duration(milliseconds: 620),
  });

  /// A narrow test seam proving setup failures cannot trap the world entry.
  /// Production uses the real audio and image initialization below.
  final Future<void> Function()? worldInitializer;

  final Duration minimumLoadingDisplay;

  @override
  State<ColorGameApp> createState() => _ColorGameAppState();
}

class _ColorGameAppState extends State<ColorGameApp> {
  final Settings _settings = Settings();
  _AppStage _stage = _AppStage.start;
  SessionSummary _lastSummary = SessionSummary.empty;
  int _sessionSerial = 0;

  @override
  void initState() {
    super.initState();

    // Prepare quietly so PLAY can have instant feedback. Music remains off
    // until the child explicitly enters the garden.
    unawaited(AudioService.instance.start(_settings));
  }

  @override
  void dispose() {
    AudioService.instance.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: _settings,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coloriboo',
        theme: AppTheme.light(),
        home: Builder(
          builder: (BuildContext screenContext) {
            final bool reduced = MediaQuery.disableAnimationsOf(screenContext);
            return AnimatedSwitcher(
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _screenForStage(screenContext),
            );
          },
        ),
      ),
    );
  }

  Widget _screenForStage(BuildContext context) {
    switch (_stage) {
      case _AppStage.start:
        return StartScreen(
          key: const ValueKey<String>('start'),
          onPlayFeedback: _playStartFeedback,
          onPlay: _beginFreshSession,
          onSettings: () => showParentSettings(context),
        );

      case _AppStage.loading:
        return LoadingScreen(
          key: ValueKey<String>('loading-$_sessionSerial'),
          minimumDisplay: widget.minimumLoadingDisplay,
          task: () => _prepareWorld(context),
          onTwinkle: AudioService.instance.playLoadingTwinkle,
          onError: (Object error) {
            debugPrint(
              'Coloriboo: world setup unavailable; entering safely.',
            );
          },
          onComplete: _enterDreamscape,
        );

      case _AppStage.dreamscape:
        return Dreamscape(
          key: ValueKey<String>('dreamscape-$_sessionSerial'),
          onFinish: _finishSession,
        );

      case _AppStage.sessionEnd:
        return SessionEndScreen(
          key: ValueKey<String>('session-end-$_sessionSerial'),
          summary: _lastSummary,
          onPlayAgain: _playAgain,
          onBackToStart: _backToStart,
          onBooTap: () {
            unawaited(AudioService.instance.speak('See you soon!'));
          },
        );
    }
  }

  void _playStartFeedback() {
    AudioService.instance
      ..playButtonTap()
      ..playSparkle();
  }

  void _beginFreshSession() {
    if (_stage != _AppStage.start) return;
    setState(() {
      _sessionSerial++;
      _lastSummary = SessionSummary.empty;
      _stage = _AppStage.loading;
    });
  }

  Future<void> _prepareWorld(BuildContext context) async {
    try {
      final Future<void> Function()? override = widget.worldInitializer;
      if (override != null) {
        await override();
      } else {
        await Future.wait<void>(<Future<void>>[
          AudioService.instance.start(_settings),
          precacheImage(const AssetImage(Boo.artworkPath), context),
        ]);
      }
    } finally {
      // Entering audio is independently failure-safe, so neither an optional
      // image nor a plugin failure can block the child from the Dreamscape.
      await AudioService.instance.enterWorld();
    }
  }

  void _enterDreamscape() {
    if (!mounted || _stage != _AppStage.loading) return;
    setState(() => _stage = _AppStage.dreamscape);
  }

  void _finishSession(SessionSummary summary) {
    if (!mounted || _stage != _AppStage.dreamscape) return;
    setState(() {
      _lastSummary = summary;
      _stage = _AppStage.sessionEnd;
    });
  }

  void _playAgain() {
    if (_stage != _AppStage.sessionEnd) return;
    AudioService.instance.playButtonTap();
    setState(() {
      _sessionSerial++;
      _lastSummary = SessionSummary.empty;
      _stage = _AppStage.loading;
    });
  }

  void _backToStart() {
    if (_stage != _AppStage.sessionEnd) return;
    AudioService.instance.playButtonTap();
    setState(() {
      _lastSummary = SessionSummary.empty;
      _stage = _AppStage.start;
    });
    unawaited(AudioService.instance.returnToStart());
  }
}

enum _AppStage { start, loading, dreamscape, sessionEnd }
