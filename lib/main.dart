import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'audio/audio_service.dart';
import 'boo/boo_asset_catalog.dart';
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

class _ColorGameAppState extends State<ColorGameApp>
    with WidgetsBindingObserver {
  final Settings _settings = Settings();
  _AppStage _stage = _AppStage.start;
  SessionSummary _lastSummary = SessionSummary.empty;
  int _sessionSerial = 0;
  bool _shellArtworkWarmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.detached) {
      unawaited(
        AudioService.instance.setAppActive(
          lifecycle == AppLifecycleState.resumed,
        ),
      );
    }

    // Prepare quietly so PLAY can have instant feedback. Music remains off
    // until the child explicitly enters the garden.
    unawaited(AudioService.instance.start(_settings));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shellArtworkWarmed) return;
    _shellArtworkWarmed = true;

    // The first shell moments should never wait for a large PNG decode. These
    // four cover Start and the deterministic loading sequence; rarer artwork
    // remains demand-loaded to keep the image cache responsible.
    for (final String path in <String>[
      BooAssetCatalog.canonical.path,
      BooAssetCatalog.loadingYellow.path,
      BooAssetCatalog.magicPearl.path,
      BooAssetCatalog.alertBlue.path,
    ]) {
      unawaited(_precacheBoo(path));
    }
  }

  Future<void> _precacheBoo(String path) async {
    try {
      await precacheImage(BooAssetCatalog.providerFor(path), context);
    } catch (error) {
      // Rendering still has the legacy Boo fallback. Preloading is a polish
      // optimization, never a reason to block or crash the child's flow.
      debugPrint(
        'Coloriboo: optional Boo preload unavailable for $path: $error',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService.instance.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      AudioService.instance.setAppActive(state == AppLifecycleState.resumed),
    );
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
            debugPrint('Coloriboo: world setup unavailable; entering safely.');
          },
          onComplete: _enterDreamscape,
        );

      case _AppStage.dreamscape:
        return Dreamscape(
          key: ValueKey<String>('dreamscape-$_sessionSerial'),
          onFinish: _finishSession,
          onHome: _homeFromDreamscape,
        );

      case _AppStage.sessionEnd:
        return SessionEndScreen(
          key: ValueKey<String>('session-end-$_sessionSerial'),
          summary: _lastSummary,
          onPlayAgain: _playAgain,
          onBackToStart: _backToStart,
          onBooTap: () {
            AudioService.instance.playSparkle();
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
          for (final String path in BooAssetCatalog.frequentPreloadPaths)
            _precacheBoo(path),
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

  void _homeFromDreamscape() {
    if (_stage != _AppStage.dreamscape) return;
    unawaited(_leaveWorldFrom(_AppStage.dreamscape));
  }

  void _backToStart() {
    if (_stage != _AppStage.sessionEnd) return;
    AudioService.instance.playButtonTap();
    unawaited(_leaveWorldFrom(_AppStage.sessionEnd));
  }

  Future<void> _leaveWorldFrom(_AppStage expectedStage) async {
    await AudioService.instance.returnToStart();

    if (!mounted || _stage != expectedStage) return;

    setState(() {
      _lastSummary = SessionSummary.empty;
      _stage = _AppStage.start;
    });
  }
}

enum _AppStage { start, loading, dreamscape, sessionEnd }
