import 'package:colorsquest/audio/audio_service.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/screens/start_screen.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (int attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _enter(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ColorGameApp(
      worldInitializer: () async {},
      minimumLoadingDisplay: Duration.zero,
    ),
  );

  await tester.pump();

  await tester.tap(find.byKey(const Key('play-button')));

  for (int attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));

    if (find.byType(Dreamscape).evaluate().isNotEmpty) {
      break;
    }
  }

  await tester.pump(const Duration(milliseconds: 700));

  expect(find.byType(Dreamscape), findsOneWidget);
}

void main() {
  testWidgets('kids can always find HOME SOUND HEAR and GAMES', (
    WidgetTester tester,
  ) async {
    await _enter(tester);

    expect(find.byKey(const Key('kid-home-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-sound-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-hear-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-games-button')), findsOneWidget);
  });

  testWidgets('master mute preserves parent audio choices', (
    WidgetTester tester,
  ) async {
    await _enter(tester);

    final Settings settings = SettingsScope.of(
      tester.element(find.byType(Dreamscape)),
    );

    expect(settings.music, isTrue);
    expect(settings.soundEffects, isTrue);
    expect(settings.voice, isTrue);
    expect(settings.masterMuted, isFalse);

    await tester.tap(find.byKey(const Key('kid-sound-button')));

    await tester.pump();

    expect(settings.masterMuted, isTrue);
    expect(settings.effectiveMusic, isFalse);
    expect(settings.effectiveSoundEffects, isFalse);
    expect(settings.effectiveVoice, isFalse);

    // The actual parent preferences are still intact.
    expect(settings.music, isTrue);
    expect(settings.soundEffects, isTrue);
    expect(settings.voice, isTrue);

    await tester.tap(find.byKey(const Key('kid-sound-button')));

    await tester.pump();

    expect(settings.masterMuted, isFalse);
    expect(settings.effectiveMusic, isTrue);
    expect(settings.effectiveSoundEffects, isTrue);
    expect(settings.effectiveVoice, isTrue);
  });

  testWidgets('GAMES opens the obvious activity chooser', (
    WidgetTester tester,
  ) async {
    await _enter(tester);

    await tester.tap(find.byKey(const Key('kid-games-button')));

    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(PlayCompassSheet), findsOneWidget);

    expect(find.text('CHOOSE A GAME!'), findsOneWidget);
  });

  testWidgets('HOME always confirms before leaving play', (
    WidgetTester tester,
  ) async {
    await _enter(tester);

    await tester.tap(find.byKey(const Key('kid-home-button')));

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('home-confirm-dialog')), findsOneWidget);

    expect(find.text('Go back home?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keep-playing-home-button')));

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(Dreamscape), findsOneWidget);
  });

  testWidgets('confirming HOME returns to the start screen', (
    WidgetTester tester,
  ) async {
    await _enter(tester);

    await tester.tap(find.byKey(const Key('kid-home-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('home-confirm-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-home-button')));
    await tester.pump();
    await _pumpUntil(tester, find.byType(StartScreen));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('start-screen')), findsOneWidget);
    expect(find.byType(Dreamscape), findsNothing);
    expect(find.byKey(const Key('home-confirm-dialog')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HEAR repeats the current learning prompt', (
    WidgetTester tester,
  ) async {
    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final List<String> spoken = <String>[];

    messenger.setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
      if (call.method == 'speak') {
        final Object? arguments = call.arguments;
        spoken.add(
          arguments is Map<Object?, Object?>
              ? '${arguments['text']}'
              : '$arguments',
        );
        return 1;
      }
      return 1;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(ttsChannel, null);
      AudioService.instance.dispose();
    });

    await _enter(tester);
    for (
      int attempt = 0;
      attempt < 20 && !AudioService.instance.voiceReady;
      attempt++
    ) {
      await tester.pump();
    }
    expect(AudioService.instance.voiceReady, isTrue);

    await tester.pump();
    final int before = spoken.length;

    await tester.tap(find.byKey(const Key('kid-hear-button')));
    await tester.pump();
    for (int attempt = 0; attempt < 20 && spoken.length == before; attempt++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(spoken, hasLength(before + 1));
    expect(spoken.last, startsWith('Can you find '));
    expect(spoken.last, endsWith('?'));
  });

  testWidgets('compact landscape has no layout exception', (
    WidgetTester tester,
  ) async {
    await _enter(tester, size: const Size(844, 390));

    expect(tester.takeException(), isNull);

    expect(find.byKey(const Key('kid-games-button')), findsOneWidget);
  });
}
