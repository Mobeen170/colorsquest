// Tests for the app itself.
//
// Everything here runs with no audio plugins available, which also proves the
// promise that Coloriboo plays normally when sound cannot start.

import 'package:colorsquest/activities/boo_changes_colour.dart';
import 'package:colorsquest/activities/colour_mixing_lab.dart';
import 'package:colorsquest/activities/light_to_dark.dart';
import 'package:colorsquest/activities/odd_one_out.dart';
import 'package:colorsquest/activities/pop_the_colour.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/settings/parent_panel.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:colorsquest/world/bubble.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, Size> _responsiveScreens = <String, Size>{
  'small phone': Size(320, 568),
  'normal phone': Size(390, 844),
  'large phone': Size(430, 932),
  'tablet': Size(834, 1194),
  'phone landscape': Size(844, 390),
  'tablet landscape': Size(1194, 834),
};

void _configureTestView(
  WidgetTester tester,
  Size size, {
  double textScaleFactor = 1,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Builds the app under a specific screen size.
///
/// The world animates forever, so `pump` is used throughout rather than
/// `pumpAndSettle`, which would wait for a world that never stops.
Future<void> pumpAppAt(
  WidgetTester tester,
  Size size, {
  double textScaleFactor = 1,
}) async {
  _configureTestView(tester, size, textScaleFactor: textScaleFactor);

  await tester.pumpWidget(
    ColorGameApp(
      worldInitializer: () async {},
      minimumLoadingDisplay: Duration.zero,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> enterDreamscape(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('play-button')));
  await tester.pump(const Duration(milliseconds: 300));
  for (int attempt = 0; attempt < 20; attempt++) {
    if (find.byType(Dreamscape).evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(Dreamscape), findsOneWidget);
}

Future<void> openActivity(
  WidgetTester tester,
  String name, {
  Size size = const Size(390, 844),
  bool reduceMotion = false,
  double textScaleFactor = 1,
}) async {
  _configureTestView(tester, size, textScaleFactor: textScaleFactor);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: reduceMotion),
      child: ColorGameApp(
        worldInitializer: () async {},
        minimumLoadingDisplay: Duration.zero,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await enterDreamscape(tester);
  await tester.tap(find.byKey(const Key('kid-games-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  final Finder choice = find.descendant(
    of: find.byType(PlayCompassSheet),
    matching: find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}\\.')),
  );
  final Finder compassScroll = find.descendant(
    of: find.byType(PlayCompassSheet),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(choice, 120, scrollable: compassScroll.last);
  await tester.tap(choice);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('opening the app', () {
    testWidgets('opens on the polished Coloriboo start screen', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      expect(find.text('START GAME'), findsNothing);
      expect(find.text('Pop. Play. Learn Colors!'), findsOneWidget);
      expect(find.byKey(const Key('play-button')), findsOneWidget);
      expect(find.byType(Dreamscape), findsNothing);
      expect(find.text('COLORIBOO'), findsOneWidget);
    });

    testWidgets('PLAY reaches the endless world', (WidgetTester tester) async {
      await pumpAppAt(tester, const Size(390, 844));
      await enterDreamscape(tester);
      expect(find.byType(SoapBubble), findsWidgets);
    });

    testWidgets('runs with no audio available and does not throw', (
      WidgetTester tester,
    ) async {
      // No plugins are registered in a widget test, so the audio engine and
      // the voice both fail to start. The app must not care.
      await pumpAppAt(tester, const Size(390, 844));
      await enterDreamscape(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    // A colour game is useless if it overflows, so every size class is
    // checked, in both orientations.
    _responsiveScreens.forEach((String name, Size size) {
      testWidgets('does not overflow on a $name', (WidgetTester tester) async {
        await pumpAppAt(tester, size);
        await enterDreamscape(tester);

        // Let the world drift a while in case anything grows over time.
        await tester.pump(const Duration(seconds: 2));

        expect(tester.takeException(), isNull);
      });
    });
  });

  group('the parent control', () {
    testWidgets('does not show the grown-up dot during child gameplay', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));
      await enterDreamscape(tester);

      expect(
        find.byType(ParentDot),
        findsNothing,
        reason: 'Grown-up settings must not float over child gameplay.',
      );
    });

    testWidgets('grown-up dot stays absent in compact landscape', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(844, 390));
      await enterDreamscape(tester);

      expect(
        find.byType(ParentDot),
        findsNothing,
        reason: 'No invisible grown-up hit target may overlap the kid nav.',
      );
    });

    testWidgets('start-screen grown-up access also requires a long press', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));

      final Finder grownUp = find.bySemanticsLabel(
        'Grown-up settings. Press and hold to open.',
      );
      expect(grownUp, findsOneWidget);

      await tester.tap(grownUp);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('For grown-ups'), findsNothing);

      await tester.longPress(grownUp);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('For grown-ups'), findsOneWidget);
    });

    testWidgets('turning words off hides the written colour', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));
      await enterDreamscape(tester);

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
      expect(wordShownBefore, isTrue);
    });
  });

  group('Boo’s play compass', () {
    testWidgets('keeps play immediate but offers all five activities', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));
      await enterDreamscape(tester);

      await tester.tap(find.byKey(const Key('kid-games-button')));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('CHOOSE A GAME!'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlayCompassSheet),
          matching: find.text('Pop the Colour'),
        ),
        findsOneWidget,
      );
      expect(find.text('Odd One Out'), findsOneWidget);
      expect(find.text('Boo’s Magic'), findsOneWidget);
      expect(find.text('Mixing Lab'), findsOneWidget);
      expect(find.text('Light to Dark'), findsOneWidget);
    });
  });

  group('all core activities', () {
    final Map<String, Type> coreActivities = <String, Type>{
      'Pop the Colour': PopTheColour,
      'Mixing Lab': ColourMixingLab,
      'Boo’s Magic': BooChangesColour,
      'Odd One Out': OddOneOut,
      'Light to Dark': LightToDark,
    };

    for (final MapEntry<String, Type> activity in coreActivities.entries) {
      for (final MapEntry<String, Size> screen in _responsiveScreens.entries) {
        testWidgets('${activity.key} renders on a ${screen.key}', (
          WidgetTester tester,
        ) async {
          await openActivity(tester, activity.key, size: screen.value);
          expect(find.byType(activity.value), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('${activity.key} supports 2x text on a small phone', (
        WidgetTester tester,
      ) async {
        await openActivity(
          tester,
          activity.key,
          size: const Size(320, 568),
          textScaleFactor: 2,
        );
        expect(find.byType(activity.value), findsOneWidget);
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
      await enterDreamscape(tester);

      final PopTheColour activity = tester.widget<PopTheColour>(
        find.byType(PopTheColour),
      );
      final int before = find.byType(SoapBubble).evaluate().length;
      final Finder wrongBubble = find.byWidgetPredicate(
        (Widget widget) =>
            widget is SoapBubble &&
            widget.semanticLabel != activity.round.target.name,
      );

      expect(wrongBubble, findsWidgets);
      await tester.tap(wrongBubble.first);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SoapBubble), findsNWidgets(before));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping is safe to repeat quickly', (
      WidgetTester tester,
    ) async {
      await pumpAppAt(tester, const Size(390, 844));
      await enterDreamscape(tester);

      final PopTheColour activity = tester.widget<PopTheColour>(
        find.byType(PopTheColour),
      );
      final Finder target = find.byWidgetPredicate(
        (Widget widget) =>
            widget is SoapBubble &&
            widget.semanticLabel == activity.round.target.name,
      );
      expect(target, findsOneWidget);

      for (int i = 0; i < 4; i++) {
        await tester.tap(target);
      }
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byType(Dreamscape), findsOneWidget);
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
