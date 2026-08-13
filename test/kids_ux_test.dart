import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/settings/parent_panel.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> enterWorld(
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
  testWidgets('gameplay has HOME SOUND HEAR and GAMES', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester);

    expect(find.byKey(const Key('kid-home-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-sound-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-hear-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-games-button')), findsOneWidget);
  });

  testWidgets('gameplay has no grown-up three-dot control', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester);

    expect(find.byType(ParentDot), findsNothing);
  });

  testWidgets('GAMES opens all five activities', (WidgetTester tester) async {
    await enterWorld(tester);

    await tester.tap(find.byKey(const Key('kid-games-button')));

    await tester.pump(const Duration(milliseconds: 450));

    final Finder sheet = find.byType(PlayCompassSheet);

    expect(sheet, findsOneWidget);

    for (final String activity in <String>[
      'Pop the Colour',
      'Odd One Out',
      'Boo’s Magic',
      'Mixing Lab',
      'Light to Dark',
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(activity)),
        findsOneWidget,
      );
    }
  });

  testWidgets('SOUND master mute preserves grown-up choices', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester);

    final Settings settings = SettingsScope.of(
      tester.element(find.byType(Dreamscape)),
    );

    final bool music = settings.music;
    final bool sfx = settings.soundEffects;
    final bool voice = settings.voice;

    expect(settings.masterMuted, isFalse);

    await tester.tap(find.byKey(const Key('kid-sound-button')));

    await tester.pump();

    expect(settings.masterMuted, isTrue);
    expect(settings.effectiveMusic, isFalse);
    expect(settings.effectiveSoundEffects, isFalse);
    expect(settings.effectiveVoice, isFalse);

    expect(settings.music, music);
    expect(settings.soundEffects, sfx);
    expect(settings.voice, voice);
  });

  testWidgets('HOME asks before leaving gameplay', (WidgetTester tester) async {
    await enterWorld(tester);

    await tester.tap(find.byKey(const Key('kid-home-button')));

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('home-confirm-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('keep-playing-home-button')));

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(Dreamscape), findsOneWidget);
  });

  testWidgets('four kid buttons fit compact landscape', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester, size: const Size(844, 390));

    expect(tester.takeException(), isNull);

    expect(find.byKey(const Key('kid-home-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-sound-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-hear-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-games-button')), findsOneWidget);
  });
}
