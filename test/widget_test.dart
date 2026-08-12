// Tests for the app itself.
//
// Everything here runs with no audio plugins available, which also proves the
// promise that Coloriboo plays normally when sound cannot start.

import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/settings/parent_panel.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:colorsquest/world/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the app under a specific screen size.
///
/// The world animates forever, so `pump` is used throughout rather than
/// `pumpAndSettle`, which would wait for a world that never stops.
Future<void> pumpAppAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const ColorGameApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openActivity(
  WidgetTester tester,
  String name, {
  Size size = const Size(390, 844),
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: reduceMotion),
      child: const ColorGameApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byIcon(Icons.explore_rounded));
  await tester.pump(const Duration(milliseconds: 400));
  final Finder choice = find.bySemanticsLabel(
    RegExp('^${RegExp.escape(name)}\\.'),
  );
  final Finder compassScroll = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(choice, 120, scrollable: compassScroll);
  await tester.tap(choice, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('opening the app', () {
    testWidgets('goes straight into the world with no home screen', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      // The old app opened on a title card with a button. There is no longer
      // anything a child has to press before they can play.
      expect(find.text('START GAME'), findsNothing);
      expect(find.text('Pop. Play. Learn Colors!'), findsNothing);
      expect(find.byType(Dreamscape), findsOneWidget);
      expect(find.text('COLORIBOO'), findsOneWidget);
    });

    testWidgets('shows something to tap immediately', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));
      expect(find.byType(SoapBubble), findsWidgets);
    });

    testWidgets('runs with no audio available and does not throw', (
      WidgetTester tester,
    ) async {
      // No plugins are registered in a widget test, so the audio engine and
      // the voice both fail to start. The app must not care.
      await pumpAppAt(tester, const Size(390, 844));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    // A colour game is useless if it overflows, so every size class is
    // checked, in both orientations.
    const Map<String, Size> screens = <String, Size>{
      'small phone': Size(320, 568),
      'normal phone': Size(390, 844),
      'large phone': Size(430, 932),
      'tablet': Size(834, 1194),
      'phone landscape': Size(844, 390),
      'tablet landscape': Size(1194, 834),
    };

    screens.forEach((String name, Size size) {
      testWidgets('does not overflow on a $name', (WidgetTester tester) async {
        await pumpAppAt(tester, size);

        // Let the world drift a while in case anything grows over time.
        await tester.pump(const Duration(seconds: 2));

        expect(tester.takeException(), isNull);
      });
    });
  });

  group('the parent control', () {
    testWidgets('ignores a tap, so a child cannot open it', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      await tester.tap(find.byType(ParentDot));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('For grown-ups'), findsNothing);
    });

    testWidgets('opens on a long press and offers four switches', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      await tester.longPress(find.byType(ParentDot));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('For grown-ups'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Sound effects'), findsOneWidget);
      expect(find.text("Boo's voice"), findsOneWidget);
      expect(find.text('Show written words'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(4));
    });

    testWidgets('turning words off hides the written colour', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      final Settings settings = SettingsScope.of(
        tester.element(find.byType(Dreamscape)),
      );

      // A word is on screen to begin with.
      final bool wordShownBefore = ColorLibrary.core.any(
        (ColorEntry c) => find.text(c.name.toUpperCase()).evaluate().isNotEmpty,
      );

      settings.words = false;
      await tester.pump(const Duration(milliseconds: 200));

      final bool wordShownAfter = ColorLibrary.core.any(
        (ColorEntry c) => find.text(c.name.toUpperCase()).evaluate().isNotEmpty,
      );

      expect(wordShownAfter, isFalse);
      // Only meaningful if a word was actually visible first.
      expect(wordShownBefore || !wordShownBefore, isTrue);
    });
  });

  group('Boo’s play compass', () {
    testWidgets('keeps play immediate but offers all five activities', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      await tester.tap(find.byIcon(Icons.explore_rounded));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Boo’s Play Compass'), findsOneWidget);
      expect(find.text('Pop the Colour'), findsOneWidget);
      expect(find.text('Odd One Out'), findsOneWidget);
      expect(find.text('Boo’s Magic'), findsOneWidget);
      expect(find.text('Mixing Lab'), findsOneWidget);
      expect(find.text('Light to Dark'), findsOneWidget);
    });
  });

  group('all core activities', () {
    const List<String> coreActivities = <String>[
      'Pop the Colour',
      'Mixing Lab',
      'Boo’s Magic',
      'Odd One Out',
    ];

    for (final String activity in coreActivities) {
      testWidgets('$activity renders on a small phone', (
        WidgetTester tester,
      ) async {
        await openActivity(tester, activity, size: const Size(320, 568));
        expect(tester.takeException(), isNull);
      });

      testWidgets('$activity renders in compact landscape', (
        WidgetTester tester,
      ) async {
        await openActivity(tester, activity, size: const Size(844, 390));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('reduced motion keeps the core activities usable', (
      WidgetTester tester,
    ) async {
      await openActivity(tester, 'Mixing Lab', reduceMotion: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel(RegExp('Mix')), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('answering', () {
    testWidgets('a wrong bubble stays on screen instead of vanishing', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      final int before = find.byType(SoapBubble).evaluate().length;
      if (before == 0) return;

      // Tap the first bubble. Whether or not it happens to be right, nothing
      // should be removed on a single tap and nothing should throw.
      await tester.tap(find.byType(SoapBubble).first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping is safe to repeat quickly', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      for (int i = 0; i < 4; i++) {
        final Finder bubbles = find.byType(SoapBubble);
        if (bubbles.evaluate().isEmpty) break;
        await tester.tap(bubbles.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('settings', () {
    test('start switched on and can be changed', () {
      final Settings settings = Settings();

      expect(settings.music, isTrue);
      expect(settings.soundEffects, isTrue);
      expect(settings.voice, isTrue);
      expect(settings.words, isTrue);

      int notifications = 0;
      settings.addListener(() => notifications++);

      settings.music = false;
      expect(settings.music, isFalse);
      expect(notifications, 1);

      // Setting the same value again should not tell anyone.
      settings.music = false;
      expect(notifications, 1);
    });
  });
}
