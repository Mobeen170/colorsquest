import 'dart:typed_data';

import 'package:colorsquest/audio/audio_service.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Coloriboo audio pack', () {
    test('contains all 13 original PCM sound effects', () async {
      expect(AudioService.effectAssetPaths, hasLength(13));

      for (final String path in AudioService.effectAssetPaths.values) {
        final ByteData data = await rootBundle.load(path);
        expect(_ascii(data, 0, 4), 'RIFF', reason: path);
        expect(_ascii(data, 8, 4), 'WAVE', reason: path);
        expect(data.getUint16(22, Endian.little), 2, reason: path);
        expect(data.getUint32(24, Endian.little), 44100, reason: path);
        expect(data.getUint16(34, Endian.little), 16, reason: path);
        expect(data.lengthInBytes, greaterThan(44), reason: path);
      }
    });

    test('twilight music is a quiet 24 second stereo PCM loop', () async {
      final ByteData data = await rootBundle.load(AudioService.musicAssetPath);

      expect(_ascii(data, 0, 4), 'RIFF');
      expect(_ascii(data, 8, 4), 'WAVE');
      expect(data.getUint16(22, Endian.little), 2);
      expect(data.getUint32(24, Endian.little), 44100);
      expect(data.getUint16(34, Endian.little), 16);
      final int bytesPerSecond = data.getUint32(28, Endian.little);
      final int dataBytes = data.getUint32(40, Endian.little);
      expect(dataBytes / bytesPerSecond, closeTo(24.0, 0.01));

      // Loop ends meet near zero without a hard full-scale discontinuity.
      final int first = data.getInt16(44, Endian.little);
      final int last = data.getInt16(data.lengthInBytes - 4, Endian.little);
      expect((last - first).abs(), lessThan(160));
    });
  });

  test(
    'initialization is idempotent and settings gate every audio family',
    () async {
      final Settings settings = Settings();
      final AudioService audio = AudioService.instance;

      final Future<void> first = audio.start(settings);
      final Future<void> second = audio.start(settings);
      expect(identical(first, second), isTrue);
      await first;

      expect(audio.worldAudioRequested, isFalse);
      expect(audio.musicWanted, isFalse);
      expect(audio.soundEffectsWanted, isTrue);
      expect(audio.voiceWanted, isTrue);

      await audio.enterWorld(playTransition: false);
      expect(audio.worldAudioRequested, isTrue);
      expect(audio.musicWanted, isTrue);

      settings
        ..music = false
        ..soundEffects = false
        ..voice = false;
      expect(audio.musicWanted, isFalse);
      expect(audio.soundEffectsWanted, isFalse);
      expect(audio.voiceWanted, isFalse);

      await audio.returnToStart();
      expect(audio.worldAudioRequested, isFalse);
      audio.dispose();
      settings.dispose();
    },
  );
}

String _ascii(ByteData data, int offset, int length) {
  return String.fromCharCodes(<int>[
    for (int index = offset; index < offset + length; index++)
      data.getUint8(index),
  ]);
}
