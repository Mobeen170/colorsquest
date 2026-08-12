import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/settings.dart';

/// All sound in Coloriboo.
///
/// `flutter_soloud` owns the preloaded local WAV pack and quiet background
/// loop. `flutter_tts` speaks Boo's learning content. Both are optional: every
/// public operation is safe when a plugin or asset is unavailable.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const Duration _operationTimeout = Duration(seconds: 3);
  static const Duration _speechTimeout = Duration(seconds: 5);
  static const double _musicVolume = 0.16;
  static const double _duckedVolume = _musicVolume * 0.22;

  @visibleForTesting
  static const Map<String, String> effectAssetPaths = <String, String>{
    'button': 'assets/audio/sfx/button_tap.wav',
    'pop': 'assets/audio/sfx/bubble_pop.wav',
    'soft': 'assets/audio/sfx/bubble_soft.wav',
    'correct': 'assets/audio/sfx/correct_chime.wav',
    'cheer': 'assets/audio/sfx/happy_cheer.wav',
    'tryAgain': 'assets/audio/sfx/try_again.wav',
    'sparkle': 'assets/audio/sfx/sparkle.wav',
    'mixing': 'assets/audio/sfx/mixing_merge.wav',
    'transition': 'assets/audio/sfx/activity_transition.wav',
    'booMagic': 'assets/audio/sfx/boo_magic.wav',
    'loading': 'assets/audio/sfx/loading_twinkle.wav',
    'celebration': 'assets/audio/sfx/celebration.wav',
    'bigCelebration': 'assets/audio/sfx/big_celebration.wav',
    'finish': 'assets/audio/sfx/finish_session.wav',
  };

  @visibleForTesting
  static const String musicAssetPath =
      'assets/audio/music/coloriboo_pop_loop.wav';

  static const Map<String, Duration> _effectCooldowns = <String, Duration>{
    'button': Duration(milliseconds: 90),
    'pop': Duration(milliseconds: 85),
    'soft': Duration(milliseconds: 180),
    'correct': Duration(milliseconds: 280),
    'cheer': Duration(milliseconds: 900),
    'tryAgain': Duration(milliseconds: 480),
    'sparkle': Duration(milliseconds: 220),
    'mixing': Duration(milliseconds: 420),
    'transition': Duration(milliseconds: 520),
    'booMagic': Duration(milliseconds: 500),
    'loading': Duration(milliseconds: 650),
    'celebration': Duration(milliseconds: 1100),
    'bigCelebration': Duration(milliseconds: 1800),
    'finish': Duration(milliseconds: 1200),
  };

  Settings? _settings;
  Future<void>? _initialization;
  bool _engineReady = false;
  bool _voiceReady = false;
  bool _worldEntered = false;
  bool _musicStarting = false;
  bool _speechActive = false;
  int _speechGeneration = 0;

  FlutterTts? _tts;
  final Map<String, AudioSource> _effects = <String, AudioSource>{};
  final Map<String, DateTime> _lastEffectAt = <String, DateTime>{};
  AudioSource? _musicSource;
  SoundHandle? _musicHandle;
  AudioSource? _tone;

  /// Prepares both engines and preloads all local sources exactly once.
  ///
  /// This deliberately does not start music. The app shell calls [enterWorld]
  /// only after the child explicitly presses Play.
  Future<void> start(Settings settings) {
    if (!identical(_settings, settings)) {
      _settings?.removeListener(_onSettingsChanged);
      _settings = settings;
      settings.addListener(_onSettingsChanged);
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    // Game audio is the only preparation the world-entry screen waits for.
    // Platform TTS setup is opportunistic: some devices/plugins never answer
    // capability calls, and Boo's optional voice must not hold up play.
    await _startEngine();
    unawaited(_startVoice());
  }

  Future<void> _startEngine() async {
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init().timeout(_operationTimeout);
      }
      _engineReady = SoLoud.instance.isInitialized;
      if (!_engineReady) return;
      SoLoud.instance.setMaxActiveVoiceCount(16);
    } catch (_) {
      debugPrint('Coloriboo: game audio unavailable, continuing silently.');
      _engineReady = false;
      return;
    }

    // Loading is concurrent so one slow optional asset cannot make the branded
    // loading screen wait once the audio engine itself is ready.
    final List<Future<void>> sourceLoads = effectAssetPaths.entries
        .map((MapEntry<String, String> entry) => _loadEffect(entry))
        .toList();
    sourceLoads.add(_loadMusic());
    sourceLoads.add(_loadTone());
    try {
      await Future.wait(sourceLoads).timeout(_operationTimeout);
    } on TimeoutException {
      debugPrint('Coloriboo: some audio took too long; using what is ready.');
    }
  }

  Future<void> _loadEffect(MapEntry<String, String> entry) async {
    try {
      final AudioSource source = await SoLoud.instance
          .loadAsset(entry.value)
          .timeout(_operationTimeout);
      _effects[entry.key] = source;
    } catch (_) {
      // Each asset is optional and independent from every other asset.
    }
  }

  Future<void> _loadMusic() async {
    try {
      _musicSource = await SoLoud.instance
          .loadAsset(musicAssetPath)
          .timeout(_operationTimeout);
    } catch (_) {
      _musicSource = null;
    }
  }

  Future<void> _loadTone() async {
    try {
      _tone = await SoLoud.instance
          .loadWaveform(WaveForm.sin, false, 1, 0)
          .timeout(_operationTimeout);
    } catch (_) {
      _tone = null;
    }
  }

  Future<void> _startVoice() async {
    try {
      final FlutterTts tts = FlutterTts();
      await Future.wait(<Future<dynamic>>[
        tts.setPitch(1.35),
        tts.setSpeechRate(0.38),
        tts.setVolume(0.9),
        tts.awaitSpeakCompletion(true),
      ]);
      _tts = tts;
      _voiceReady = true;
    } catch (_) {
      debugPrint('Coloriboo: voice unavailable, continuing without speech.');
      _tts = null;
      _voiceReady = false;
    }
  }

  /// Marks explicit entry into play, fades in one music instance, and can play
  /// the tiny prism transition used at the end of the branded loader.
  Future<void> enterWorld({bool playTransition = true}) async {
    final Future<void>? initialization = _initialization;
    if (initialization != null) {
      try {
        await initialization.timeout(_operationTimeout);
      } catch (_) {
        // Loading/navigation must continue if either audio plugin stalls.
      }
    }
    _worldEntered = true;
    if (playTransition) playActivityTransition();
    await _updateMusic();
  }

  /// Fades the garden loop away before returning to the silent start screen.
  Future<void> returnToStart() async {
    _worldEntered = false;
    final SoundHandle? handle = _musicHandle;
    if (!_engineReady || handle == null) return;
    try {
      SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 450));
      await Future<void>.delayed(const Duration(milliseconds: 470));
      if (!_worldEntered && identical(handle, _musicHandle)) {
        await SoLoud.instance.stop(handle).timeout(_operationTimeout);
        _musicHandle = null;
      }
    } catch (_) {
      if (identical(handle, _musicHandle)) _musicHandle = null;
    }
  }

  void _onSettingsChanged() {
    unawaited(_updateMusic());
    if (_settings?.voice == false || _settings?.masterMuted == true) {
      unawaited(stopSpeaking());
    }
  }

  Future<void> _updateMusic() async {
    if (!_engineReady || _musicSource == null) return;
    final bool wanted = _worldEntered && (_settings?.effectiveMusic ?? false);

    if (wanted && _musicHandle != null) {
      try {
        SoLoud.instance.fadeVolume(
          _musicHandle!,
          _speechActive ? _duckedVolume : _musicVolume,
          const Duration(milliseconds: 350),
        );
      } catch (_) {
        _musicHandle = null;
      }
      return;
    }

    if (wanted && !_musicStarting) {
      _musicStarting = true;
      try {
        final SoundHandle handle = await SoLoud.instance
            .play(_musicSource!, volume: 0, looping: true)
            .timeout(_operationTimeout);
        if (_worldEntered && (_settings?.effectiveMusic ?? false)) {
          _musicHandle = handle;
          SoLoud.instance.setProtectVoice(handle, true);
          SoLoud.instance.fadeVolume(
            handle,
            _speechActive ? _duckedVolume : _musicVolume,
            const Duration(milliseconds: 650),
          );
        } else {
          await SoLoud.instance.stop(handle).timeout(_operationTimeout);
        }
      } catch (_) {
        _musicHandle = null;
      } finally {
        _musicStarting = false;
      }
      return;
    }

    if (!wanted && _musicHandle != null) {
      final SoundHandle handle = _musicHandle!;
      _musicHandle = null;
      try {
        await SoLoud.instance.stop(handle).timeout(_operationTimeout);
      } catch (_) {
        // Muting music remains safe even if its voice already ended.
      }
    }
  }

  /// Boo speaks while the loop ducks. A timeout, error, interruption, or newer
  /// speech request always restores music, so it cannot stay quietly stuck.
  Future<void> speak(String text) async {
    if (!_voiceReady ||
        _settings?.effectiveVoice != true ||
        text.trim().isEmpty) {
      return;
    }

    final int request = ++_speechGeneration;
    _speechActive = true;
    _duckMusic(down: true);
    try {
      await _tts!.speak(text).timeout(_speechTimeout);
    } on TimeoutException {
      try {
        await _tts?.stop().timeout(const Duration(seconds: 1));
      } catch (_) {
        // The platform voice is already considered abandoned.
      }
    } catch (_) {
      // Speech is an enhancement, never a gameplay requirement.
    } finally {
      if (request == _speechGeneration) {
        _speechActive = false;
        _duckMusic(down: false);
      }
    }
  }

  /// Stops Boo mid-sentence and restores the music even if stop itself fails.
  Future<void> stopSpeaking() async {
    _speechGeneration++;
    try {
      await _tts?.stop().timeout(const Duration(seconds: 1));
    } catch (_) {
      // Nothing usable to stop.
    } finally {
      _speechActive = false;
      _duckMusic(down: false);
    }
  }

  void _duckMusic({required bool down}) {
    final SoundHandle? handle = _musicHandle;
    if (!_engineReady || handle == null) return;
    try {
      SoLoud.instance.fadeVolume(
        handle,
        down ? _duckedVolume : _musicVolume,
        Duration(milliseconds: down ? 180 : 420),
      );
    } catch (_) {
      // Ducking is polish, not a requirement for speech or play.
    }
  }

  bool _claimEffect(String name) {
    if (!_engineReady || _settings?.effectiveSoundEffects != true) return false;
    final DateTime now = DateTime.now();
    final DateTime? previous = _lastEffectAt[name];
    final Duration cooldown =
        _effectCooldowns[name] ?? const Duration(milliseconds: 100);
    if (previous != null && now.difference(previous) < cooldown) return false;
    _lastEffectAt[name] = now;
    return true;
  }

  void _playEffect(String name, {double volume = 0.48}) {
    if (!_claimEffect(name)) return;
    final AudioSource? source = _effects[name];
    if (source == null) return;
    final double safeVolume = _speechActive ? min(volume, 0.34) : volume;
    unawaited(_playSource(source, safeVolume));
  }

  Future<void> _playSource(AudioSource source, double volume) async {
    try {
      await SoLoud.instance
          .play(source, volume: volume)
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // One missed sound must never interrupt touch feedback or navigation.
    }
  }

  void playButtonTap() => _playEffect('button', volume: 0.42);

  void playPop() => _playEffect('pop', volume: 0.50);

  void playSoftBubble() => _playEffect('soft', volume: 0.36);

  void playTryAgain() {
    if (_effects['tryAgain'] != null) {
      _playEffect('tryAgain', volume: 0.38);
    } else if (_claimEffect('tryAgain')) {
      _playTone(0, seconds: 0.20, volume: 0.17);
    }
  }

  /// Kept for the existing drag and shade-swap call sites.
  void playSnap() => playMixingMerge();

  void playMixingMerge() => _playEffect('mixing', volume: 0.44);

  void playSparkle() => _playEffect('sparkle', volume: 0.40);

  void playCorrect() => _playEffect('correct', volume: 0.50);

  /// Short happy success flourish layered under a correct answer.
  void playCheer() => _playEffect('cheer', volume: 0.36);

  void playActivityTransition() => _playEffect('transition', volume: 0.38);

  void playBooMagic() => _playEffect('booMagic', volume: 0.42);

  void playLoadingTwinkle() => _playEffect('loading', volume: 0.28);

  /// A small flourish used by ordinary celebrations.
  void playCelebration() => _playEffect('celebration', volume: 0.53);

  /// The larger flourish reserved for Wonder Sky milestones.
  void playBigCelebration() => _playEffect('bigCelebration', volume: 0.58);

  void playFinishSession() => _playEffect('finish', volume: 0.50);

  /// Plays the note belonging to a colour from Coloriboo's pentatonic scale.
  void playColorNote(int semitone, {bool withThird = false}) {
    if (!_engineReady ||
        _tone == null ||
        _settings?.effectiveSoundEffects != true) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? previous = _lastEffectAt['colorNote'];
    if (previous != null &&
        now.difference(previous) < const Duration(milliseconds: 65)) {
      return;
    }
    _lastEffectAt['colorNote'] = now;
    _playTone(semitone, seconds: 0.50, volume: 0.30);
    if (withThird) {
      Future<void>.delayed(const Duration(milliseconds: 90), () {
        _playTone(semitone + 4, seconds: 0.45, volume: 0.22);
      });
    }
  }

  void _playTone(int semitone, {double seconds = 0.4, double volume = 0.3}) {
    final AudioSource? tone = _tone;
    if (!_engineReady ||
        tone == null ||
        _settings?.effectiveSoundEffects != true) {
      return;
    }
    unawaited(_playToneSafely(tone, semitone, seconds, volume));
  }

  Future<void> _playToneSafely(
    AudioSource tone,
    int semitone,
    double seconds,
    double volume,
  ) async {
    try {
      final double frequency = 261.63 * pow(2, semitone / 12.0);
      SoLoud.instance.setWaveformFreq(tone, frequency);
      final SoundHandle handle = await SoLoud.instance
          .play(tone, volume: volume)
          .timeout(const Duration(seconds: 1));
      SoLoud.instance.fadeVolume(
        handle,
        0,
        Duration(milliseconds: (seconds * 1000).round()),
      );
      await Future<void>.delayed(
        Duration(milliseconds: (seconds * 1000).round() + 60),
      );
      await SoLoud.instance.stop(handle).timeout(const Duration(seconds: 1));
    } catch (_) {
      // No tone this time.
    }
  }

  @visibleForTesting
  bool get worldAudioRequested => _worldEntered;

  @visibleForTesting
  bool get musicWanted => _worldEntered && (_settings?.effectiveMusic ?? false);

  @visibleForTesting
  bool get soundEffectsWanted => _settings?.effectiveSoundEffects ?? false;

  @visibleForTesting
  bool get voiceWanted => _settings?.effectiveVoice ?? false;

  /// Releases both engines. Safe after partial or failed initialization.
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    _settings = null;
    _worldEntered = false;
    _speechGeneration++;
    try {
      _tts?.stop();
    } catch (_) {
      // Nothing to stop.
    }
    try {
      if (_engineReady) SoLoud.instance.deinit();
    } catch (_) {
      // Already down.
    }
    _tts = null;
    _effects.clear();
    _lastEffectAt.clear();
    _musicSource = null;
    _musicHandle = null;
    _tone = null;
    _engineReady = false;
    _voiceReady = false;
    _speechActive = false;
    _musicStarting = false;
    _initialization = null;
  }
}
