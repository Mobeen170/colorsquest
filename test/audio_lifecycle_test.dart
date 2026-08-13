import 'dart:async';

import 'package:colorsquest/audio/audio_service.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'speech interruption and mute preserve the newest voice lifecycle',
    () async {
      const MethodChannel ttsChannel = MethodChannel('flutter_tts');
      final TestDefaultBinaryMessenger messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final List<Completer<dynamic>> speechRequests = <Completer<dynamic>>[];
      Completer<dynamic>? pendingStop;
      int stopCalls = 0;

      messenger.setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
        switch (call.method) {
          case 'speak':
            final Completer<dynamic> request = Completer<dynamic>();
            speechRequests.add(request);
            return request.future;
          case 'stop':
            stopCalls++;
            return pendingStop?.future ?? 1;
          default:
            // Pitch, rate, volume, and completion-mode setup all succeed.
            return 1;
        }
      });

      final Settings settings = Settings();
      final AudioService audio = AudioService.instance;
      addTearDown(() {
        audio.dispose();
        settings.dispose();
        messenger.setMockMethodCallHandler(ttsChannel, null);
      });

      await audio.start(settings);
      for (int attempt = 0; attempt < 20 && !audio.voiceReady; attempt++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(audio.voiceReady, isTrue);
      await audio.enterWorld(playTransition: false);

      final Future<void> firstSpeech = audio.speak('First prompt');
      await Future<void>.delayed(Duration.zero);
      expect(audio.speechActive, isTrue);
      expect(speechRequests, hasLength(1));

      // Activity changes issue stop and the new prompt back-to-back. A delayed
      // completion from the old stop must not unduck or finish the new prompt.
      pendingStop = Completer<dynamic>();
      final Future<void> stopping = audio.stopSpeaking();
      await Future<void>.delayed(Duration.zero);
      final Future<void> secondSpeech = audio.speak('Newest prompt');
      await Future<void>.delayed(Duration.zero);
      expect(speechRequests, hasLength(1));
      expect(audio.speechActive, isTrue);

      pendingStop.complete(1);
      await stopping;
      await Future<void>.delayed(Duration.zero);
      expect(speechRequests, hasLength(2));
      expect(audio.speechActive, isTrue);

      speechRequests[0].complete(1);
      await firstSpeech;
      expect(audio.speechActive, isTrue);

      speechRequests[1].complete(1);
      await secondSpeech;
      expect(audio.speechActive, isFalse);

      await audio.setAppActive(false);
      await audio.speak('Do not speak in the background');
      expect(speechRequests, hasLength(2));
      expect(audio.voiceWanted, isFalse);
      await audio.setAppActive(true);

      // The child-facing master mute must interrupt an active utterance and a
      // late platform completion must not make voice active again.
      pendingStop = null;
      final Future<void> mutedSpeech = audio.speak('Mute this prompt');
      await Future<void>.delayed(Duration.zero);
      expect(audio.speechActive, isTrue);

      settings.masterMuted = true;
      await Future<void>.delayed(Duration.zero);
      expect(audio.voiceWanted, isFalse);
      expect(audio.speechActive, isFalse);
      expect(stopCalls, greaterThanOrEqualTo(2));

      speechRequests[2].complete(1);
      await mutedSpeech;
      expect(audio.speechActive, isFalse);

      settings.masterMuted = false;
      final Future<void> backgroundedSpeech = audio.speak(
        'Stop when the app backgrounds',
      );
      await Future<void>.delayed(Duration.zero);
      expect(audio.speechActive, isTrue);
      await audio.setAppActive(false);
      expect(audio.speechActive, isFalse);
      expect(audio.voiceWanted, isFalse);
      speechRequests.last.complete(1);
      await backgroundedSpeech;
      expect(audio.speechActive, isFalse);
    },
  );
}
