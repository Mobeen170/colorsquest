import 'dart:async';

import 'package:colorsquest/activities/pop_the_colour.dart';
import 'package:colorsquest/boo/boo.dart';
import 'package:colorsquest/boo/boo_asset_catalog.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/screens/session_end_screen.dart';
import 'package:colorsquest/world/bubble.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 50,
}) async {
  for (int attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _enterWorld(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ColorGameApp(
      worldInitializer: () async {},
      minimumLoadingDisplay: Duration.zero,
    ),
  );
  await tester.pump(const Duration(milliseconds: 3100));
  await tester.tap(find.byKey(const Key('play-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 280));
  await _pumpUntil(tester, find.byType(Dreamscape));
}

Future<void> _finish(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('play-compass-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 420));
  expect(find.byType(PlayCompassSheet), findsOneWidget);

  final Finder finish = find.byKey(const Key('finish-for-now-button'));
  await tester.ensureVisible(finish);
  await tester.pump();
  await tester.tap(finish);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 420));
  await tester.tap(find.byKey(const Key('confirm-finish-button')));
  await tester.pump();
  await _pumpUntil(tester, find.byType(SessionEndScreen));
}

List<int> _memoryValues(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(SessionEndScreen),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is Text && RegExp(r'^\d+$').hasMatch(widget.data ?? ''),
          ),
        ),
      )
      .map((Text text) => int.parse(text.data!))
      .toList(growable: false);
}

void main() {
  testWidgets(
    'a wrong answer recovers and rapid correct taps resolve only one round',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _enterWorld(tester);

      final PopTheColour activity = tester.widget<PopTheColour>(
        find.byType(PopTheColour),
      );
      final String targetName = activity.round.target.name;
      final Finder bubbles = find.descendant(
        of: find.byType(PopTheColour),
        matching: find.byType(SoapBubble),
      );
      final Finder wrongBubble = find.descendant(
        of: find.byType(PopTheColour),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is SoapBubble &&
              widget.semanticLabel != activity.round.target.name,
        ),
      );
      final Finder targetBubble = find.descendant(
        of: find.byType(PopTheColour),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is SoapBubble &&
              widget.semanticLabel == activity.round.target.name,
        ),
      );

      expect(wrongBubble, findsWidgets);
      expect(targetBubble, findsOneWidget);
      await tester.tap(wrongBubble.first);
      await tester.pump();

      // The retry returns control, preserves every option, and keeps the real
      // answer available instead of dead-ending or silently resolving.
      expect(bubbles, findsNWidgets(activity.round.options.length));
      expect(
        tester.widget<PopTheColour>(find.byType(PopTheColour)).missCount,
        1,
      );
      expect(targetBubble, findsOneWidget);

      // Wrong-answer feedback owns input for one short tactile beat, then
      // returns it independently of optional speech.
      await tester.pump(const Duration(milliseconds: 500));

      // Pointer-state rebuilds are not required for safety: the state-level
      // gate must reject all extra events delivered in this same frame.
      for (int tap = 0; tap < 4; tap++) {
        await tester.tap(targetBubble);
      }
      await tester.pump();

      final Finder successAnnouncement = find.bySemanticsLabel(
        RegExp(
          '${RegExp.escape(targetName)}\\. You found the color!',
          caseSensitive: false,
        ),
      );
      expect(find.byType(WonderCelebration), findsOneWidget);
      expect(successAnnouncement, findsOneWidget);
      expect(
        tester.getSemantics(successAnnouncement).flagsCollection.isLiveRegion,
        isTrue,
      );
      expect(
        tester.widget<Boo>(find.byType(Boo)).visualState,
        BooVisualState.correct,
      );

      await tester.pump(const Duration(milliseconds: 1400));

      expect(find.byType(Dreamscape), findsOneWidget);
      expect(find.byType(SessionEndScreen), findsNothing);
      expect(find.byType(WonderCelebration), findsNothing);
      await _finish(tester);

      // One wrong colour plus the target were explored, but only one activity
      // and one successful interaction were recorded.
      expect(_memoryValues(tester), <int>[2, 1, 0]);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('a stalled device voice never blocks retry or endless play', (
    WidgetTester tester,
  ) async {
    const MethodChannel ttsChannel = MethodChannel('flutter_tts');
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final List<Completer<dynamic>> pendingSpeech = <Completer<dynamic>>[];
    messenger.setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
      if (call.method == 'speak') {
        final Completer<dynamic> request = Completer<dynamic>();
        pendingSpeech.add(request);
        return request.future;
      }
      return 1;
    });
    addTearDown(() {
      for (final Completer<dynamic> request in pendingSpeech) {
        if (!request.isCompleted) request.complete(1);
      }
      messenger.setMockMethodCallHandler(ttsChannel, null);
    });

    await _enterWorld(tester);
    final PopTheColour activity = tester.widget<PopTheColour>(
      find.byType(PopTheColour),
    );
    final Finder wrongBubble = find.descendant(
      of: find.byType(PopTheColour),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is SoapBubble &&
            widget.semanticLabel != activity.round.target.name,
      ),
    );
    final Finder targetBubble = find.descendant(
      of: find.byType(PopTheColour),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is SoapBubble &&
            widget.semanticLabel == activity.round.target.name,
      ),
    );

    await tester.tap(wrongBubble.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The retry gate is a short tactile debounce, not a wait for TTS.
    await tester.tap(targetBubble);
    await tester.pump();
    expect(find.byType(WonderCelebration), findsOneWidget);

    // Leave every mocked utterance unresolved. Endless progression still
    // starts its next round on the visual timer.
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.byType(WonderCelebration), findsNothing);
    expect(find.byType(Dreamscape), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Resolve the fake platform Futures so the service's own bounded timeout
    // timers are cancelled rather than leaking into Flutter's test invariant.
    for (final Completer<dynamic> request in pendingSpeech) {
      if (!request.isCompleted) request.complete(1);
    }
    await tester.pump();
  });
}
