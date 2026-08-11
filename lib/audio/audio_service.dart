import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/settings.dart';

/// All the sound in Coloriboo.
///
/// Two engines, each doing what it is best at:
///
/// * `flutter_tts` speaks. Boo names colours and encourages the child using
///   the device's own voice, so nothing has to be recorded.
/// * `flutter_soloud` plays the game audio. It is used because a bubble pop
///   has to sound the instant a finger lands, and because it can synthesise a
///   tone without any file, which is how every colour gets its own note.
///
/// Everything here is optional. If the engine will not start, or the audio
/// files have not been added yet, the app carries on silently rather than
/// failing. That is deliberate: the game shipped before the sound did.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  Settings? _settings;

  bool _engineReady = false;
  bool _voiceReady = false;

  FlutterTts? _tts;

  final Map<String, AudioSource> _effects = <String, AudioSource>{};
  AudioSource? _musicSource;
  SoundHandle? _musicHandle;

  /// A synthesised tone, retuned each time it is played.
  AudioSource? _tone;

  /// How loud the music sits under everything else.
  static const double _musicVolume = 0.28;

  /// How far the music drops while Boo is talking.
  static const double _duckedVolume = _musicVolume * 0.25;

  /// The polished sound effects. Missing files are simply skipped.
  static const Map<String, String> _effectFiles = <String, String>{
    'pop': 'assets/audio/sfx/bubble_pop.mp3',
    'soft': 'assets/audio/sfx/bubble_soft.mp3',
    'sparkle': 'assets/audio/sfx/sparkle.mp3',
    'correct': 'assets/audio/sfx/correct.mp3',
    'tryAgain': 'assets/audio/sfx/try_again.mp3',
    'snap': 'assets/audio/sfx/drag_snap.mp3',
    'celebration': 'assets/audio/sfx/celebration.mp3',
  };

  static const String _musicFile =
      'assets/audio/music/coloriboo_dream_loop.mp3';

  /// Starts whatever is available. Never throws.
  Future<void> start(Settings settings) async {
    _settings = settings;
    settings.addListener(_onSettingsChanged);

    await _startEngine();
    await _startVoice();
  }

  Future<void> _startEngine() async {
    try {
      await SoLoud.instance.init();
      _engineReady = SoLoud.instance.isInitialized;
    } catch (error) {
      debugPrint('Coloriboo: game audio unavailable, continuing silently.');
      _engineReady = false;
      return;
    }

    // Each effect is loaded on its own so one missing file cannot stop the
    // rest from working.
    for (final MapEntry<String, String> entry in _effectFiles.entries) {
      try {
        _effects[entry.key] = await SoLoud.instance.loadAsset(entry.value);
      } catch (_) {
        // No such file yet. That sound just stays quiet.
      }
    }

    try {
      // A pure sine: the softest waveform available, and the only one that
      // does not sound harsh to a small child.
      _tone = await SoLoud.instance.loadWaveform(WaveForm.sin, false, 1, 0);
    } catch (_) {
      _tone = null;
    }

    try {
      _musicSource = await SoLoud.instance.loadAsset(_musicFile);
    } catch (_) {
      _musicSource = null;
    }

    await _updateMusic();
  }

  Future<void> _startVoice() async {
    try {
      final FlutterTts tts = FlutterTts();

      // Small, bright and gentle: raised in pitch so Boo sounds like a little
      // creature, and slowed down so a four year old can actually catch the
      // word.
      await tts.setPitch(1.35);
      await tts.setSpeechRate(0.38);
      await tts.setVolume(0.9);

      // Needed so the music knows when to come back up.
      await tts.awaitSpeakCompletion(true);

      _tts = tts;
      _voiceReady = true;
    } catch (_) {
      debugPrint('Coloriboo: voice unavailable, continuing without speech.');
      _voiceReady = false;
    }
  }

  void _onSettingsChanged() {
    _updateMusic();
    if (_settings?.voice == false) {
      _tts?.stop();
    }
  }

  Future<void> _updateMusic() async {
    if (!_engineReady || _musicSource == null) return;

    final bool wanted = _settings?.music ?? false;

    try {
      if (wanted && _musicHandle == null) {
        _musicHandle = await SoLoud.instance.play(
          _musicSource!,
          volume: _musicVolume,
          looping: true,
        );
        // Music must never be dropped to make room for a pop.
        SoLoud.instance.setProtectVoice(_musicHandle!, true);
      } else if (!wanted && _musicHandle != null) {
        SoLoud.instance.stop(_musicHandle!);
        _musicHandle = null;
      }
    } catch (_) {
      _musicHandle = null;
    }
  }

  /// Boo says something out loud.
  ///
  /// The music dips while he talks and eases back afterwards, so his voice is
  /// always the clearest thing in the room.
  Future<void> speak(String text) async {
    if (!_voiceReady || _settings?.voice != true) return;

    _duckMusic(down: true);
    try {
      await _tts?.speak(text);
    } catch (_) {
      // Speech failed. Not worth interrupting play over.
    }
    _duckMusic(down: false);
  }

  /// Stops Boo mid-sentence, for when a child moves on.
  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // Nothing to stop.
    }
    _duckMusic(down: false);
  }

  void _duckMusic({required bool down}) {
    final SoundHandle? handle = _musicHandle;
    if (!_engineReady || handle == null) return;

    try {
      SoLoud.instance.fadeVolume(
        handle,
        down ? _duckedVolume : _musicVolume,
        Duration(milliseconds: down ? 200 : 400),
      );
    } catch (_) {
      // Fading is a nicety, not a requirement.
    }
  }

  void _playEffect(String name, {double volume = 1}) {
    if (!_engineReady || _settings?.soundEffects != true) return;

    final AudioSource? source = _effects[name];
    if (source == null) return;

    try {
      SoLoud.instance.play(source, volume: volume);
    } catch (_) {
      // A missed sound effect is not worth a crash.
    }
  }

  /// A bubble bursting.
  void playPop() => _playEffect('pop');

  /// The soft, forgiving sound of a wrong tap. Never a buzzer.
  void playTryAgain() {
    _playEffect('tryAgain', volume: 0.7);
    if (_effects['tryAgain'] == null) _playTone(48, seconds: 0.16, volume: 0.2);
  }

  /// Two bubbles snapping together in the mixing lab.
  void playSnap() => _playEffect('snap');

  /// A small shimmer.
  void playSparkle() => _playEffect('sparkle', volume: 0.8);

  /// The reward for getting it right.
  void playCorrect() => _playEffect('correct');

  /// The big one, saved for occasional moments.
  void playCelebration() => _playEffect('celebration');

  /// Plays the note belonging to a colour.
  ///
  /// Every colour has its own note, drawn from a pentatonic scale so any run
  /// of taps sounds pleasant. It is also the third way a colour identifies
  /// itself, alongside its spoken name and its written word, which is what
  /// lets a colour-blind child play.
  void playColorNote(int semitone, {bool withThird = false}) {
    // Nothing to schedule when there is no engine, which also keeps stray
    // timers out of the app when sound is unavailable.
    if (!_engineReady || _tone == null || _settings?.soundEffects != true) {
      return;
    }

    _playTone(semitone, seconds: 0.5, volume: 0.35);
    if (withThird) {
      Future<void>.delayed(const Duration(milliseconds: 90), () {
        _playTone(semitone + 4, seconds: 0.45, volume: 0.26);
      });
    }
  }

  /// Synthesises a short, soft tone.
  ///
  /// Used only for the small musical moments. The polished sounds a child
  /// hears most often come from real recordings, because synthesised audio
  /// sounds electronic and would wear thin quickly.
  void _playTone(int semitone, {double seconds = 0.4, double volume = 0.3}) {
    final AudioSource? tone = _tone;
    if (!_engineReady || tone == null || _settings?.soundEffects != true) {
      return;
    }

    try {
      // Middle C, moved by the requested number of semitones.
      final double frequency = 261.63 * pow(2, semitone / 12.0);
      SoLoud.instance.setWaveformFreq(tone, frequency);
      SoLoud.instance.play(tone, volume: volume).then((SoundHandle handle) {
        // Fade out rather than cutting, so it sounds like a chime.
        SoLoud.instance.fadeVolume(
          handle,
          0,
          Duration(milliseconds: (seconds * 1000).round()),
        );
        Future<void>.delayed(
          Duration(milliseconds: (seconds * 1000).round() + 60),
          () {
            try {
              SoLoud.instance.stop(handle);
            } catch (_) {
              // Already gone.
            }
          },
        );
      });
    } catch (_) {
      // No tone this time.
    }
  }

  /// Shuts everything down.
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
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
    _engineReady = false;
  }
}
