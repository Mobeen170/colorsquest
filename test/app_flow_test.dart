import 'dart:async';

import 'package:colorsquest/activities/pop_the_colour.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/screens/loading_screen.dart';
import 'package:colorsquest/screens/session_end_screen.dart';
import 'package:colorsquest/screens/start_screen.dart';
import 'package:colorsquest/world/bubble.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _phone = Size(390, 844);

Future<void> _pumpApp(
  WidgetTester tester, {
  Future<void> Function()? initializer,
  Duration minimumLoadingDisplay = Duration.zero,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ColorGameApp(
      worldInitializer: initializer ?? () async {},
      minimumLoadingDisplay: minimumLoadingDisplay,
    ),
  );
  await tester.pump();

  // Audio plugins are intentionally optional in widget tests. Advance past
  // their bounded startup timeout so no platform timer leaks between cases.
  await tester.pump(const Duration(milliseconds: 3100));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 50,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (int attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      // AnimatedSwitcher deliberately keeps the previous stage alive during
      // its short cross-fade; move beyond it before asserting one stage only.
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
    await tester.pump(step);
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapPlay(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('play-button')));
  await tester.pump();
  // StartScreen gives Boo a brief reaction before changing screens.
  await tester.pump(const Duration(milliseconds: 280));
}

Future<void> _enterDreamscape(WidgetTester tester) async {
  await _tapPlay(tester);
  await _pumpUntil(tester, find.byType(Dreamscape));
  expect(find.byKey(const Key('dreamscape-screen')), findsOneWidget);
}

Future<void> _openFinishDialog(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.explore_rounded));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 420));

  expect(find.byType(PlayCompassSheet), findsOneWidget);
  final Finder finish = find.byKey(const Key('finish-for-now-button'));
  await tester.ensureVisible(finish);
  await tester.pump();
  await tester.tap(finish);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 420));

  expect(find.byKey(const Key('finish-confirm-dialog')), findsOneWidget);
}

Future<void> _confirmFinish(WidgetTester tester) async {
  await _openFinishDialog(tester);
  await tester.tap(find.byKey(const Key('confirm-finish-button')));
  await tester.pump();
  await _pumpUntil(tester, find.byType(SessionEndScreen));
}

List<int> _sessionMemoryValues(WidgetTester tester) {
  final Finder numericMemories = find.descendant(
    of: find.byType(SessionEndScreen),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is Text && RegExp(r'^\d+$').hasMatch(widget.data ?? ''),
    ),
  );
  return tester
      .widgetList<Text>(numericMemories)
      .map((Text text) => int.parse(text.data!))
      .toList(growable: false);
}

void _expectZeroSessionSummary(WidgetTester tester) {
  expect(find.text('Colors\nexplored'), findsOneWidget);
  expect(find.text('Activities\nplayed'), findsOneWidget);
  expect(find.text('Shades\nexplored'), findsOneWidget);

  final List<int> values = _sessionMemoryValues(tester);
  expect(values, <int>[0, 0, 0]);
  expect(values, everyElement(greaterThanOrEqualTo(0)));
}

void main() {
  group('Coloriboo app shell', () {
    testWidgets('opens on the approved branded start screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);

      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byKey(const Key('start-screen')), findsOneWidget);
      expect(find.text('COLORIBOO'), findsOneWidget);
      expect(find.text('Pop. Play. Learn Colors!'), findsOneWidget);
      expect(find.text('Explore colors with Boo'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.byType(Dreamscape), findsNothing);
    });

    testWidgets('PLAY shows real loading before entering the Dreamscape', (
      WidgetTester tester,
    ) async {
      final Completer<void> initialization = Completer<void>();
      await _pumpApp(tester, initializer: () => initialization.future);

      await _tapPlay(tester);
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.byKey(const Key('loading-screen')), findsOneWidget);
      expect(find.byType(Dreamscape), findsNothing);

      initialization.complete();
      await _pumpUntil(tester, find.byType(Dreamscape));

      expect(find.byType(LoadingScreen), findsNothing);
      expect(find.byKey(const Key('dreamscape-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed world initializer can never trap the child', (
      WidgetTester tester,
    ) async {
      await _pumpApp(
        tester,
        initializer: () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          throw StateError('expected test setup failure');
        },
      );

      await _enterDreamscape(tester);

      expect(find.byType(LoadingScreen), findsNothing);
      expect(find.byType(Dreamscape), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('play remains endless until Finish for now is chosen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _enterDreamscape(tester);
      final Key? originalWorldKey = tester
          .widget<Dreamscape>(find.byType(Dreamscape))
          .key;

      // A large fake-time jump must not manufacture an automatic result or
      // session timeout. The drifting world deliberately keeps animating.
      await tester.pump(const Duration(minutes: 2));

      expect(find.byType(Dreamscape), findsOneWidget);
      expect(
        tester.widget<Dreamscape>(find.byType(Dreamscape)).key,
        originalWorldKey,
      );
      expect(find.byType(SessionEndScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'finish is confirmed, cancellable, and yields honest memories',
      (WidgetTester tester) async {
        await _pumpApp(tester);
        await _enterDreamscape(tester);

        await _openFinishDialog(tester);
        await tester.tap(find.byKey(const Key('keep-playing-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 420));

        expect(find.byKey(const Key('finish-confirm-dialog')), findsNothing);
        expect(find.byType(Dreamscape), findsOneWidget);
        expect(find.byType(SessionEndScreen), findsNothing);

        await _confirmFinish(tester);

        expect(find.byKey(const Key('session-end-screen')), findsOneWidget);
        _expectZeroSessionSummary(tester);
        expect(find.textContaining('score', findRichText: true), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('PLAY AGAIN is fresh and BACK TO START returns home', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await _enterDreamscape(tester);

      // Complete one real round so the first session has something truthful
      // to remember, then prove none of it leaks into Play Again.
      final PopTheColour activity = tester.widget<PopTheColour>(
        find.byType(PopTheColour),
      );
      final Finder targetBubble = find.descendant(
        of: find.byType(PopTheColour),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is SoapBubble &&
              widget.semanticLabel == activity.round.target.name,
        ),
      );
      expect(targetBubble, findsOneWidget);
      await tester.tap(targetBubble);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      final Key? firstWorldKey = tester
          .widget<Dreamscape>(find.byType(Dreamscape))
          .key;
      await _confirmFinish(tester);
      expect(_sessionMemoryValues(tester), <int>[1, 1, 0]);

      await tester.tap(find.byKey(const Key('play-again-button')));
      await tester.pump();
      await _pumpUntil(tester, find.byType(Dreamscape));

      final Key? secondWorldKey = tester
          .widget<Dreamscape>(find.byType(Dreamscape))
          .key;
      expect(secondWorldKey, isNot(firstWorldKey));

      await _confirmFinish(tester);
      _expectZeroSessionSummary(tester);

      await tester.tap(find.byKey(const Key('back-to-start-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byKey(const Key('start-screen')), findsOneWidget);
      expect(find.byType(SessionEndScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
