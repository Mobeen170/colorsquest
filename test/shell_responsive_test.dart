import 'package:colorsquest/app_theme.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/screens/loading_screen.dart';
import 'package:colorsquest/screens/session_end_screen.dart';
import 'package:colorsquest/screens/start_screen.dart';
import 'package:colorsquest/session/session_summary.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, Size> _shellSizes = <String, Size>{
  'small phone': Size(320, 568),
  'normal phone': Size(390, 844),
  'large phone': Size(430, 932),
  'tablet': Size(834, 1194),
  'phone landscape': Size(844, 390),
  'tablet landscape': Size(1194, 834),
};

final SessionSummary _sampleSummary = SessionSummary(
  activitiesCompleted: 8,
  successfulInteractions: 11,
  shadesDiscovered: 4,
  colorsExplored: <ColorEntry>[
    ...ColorLibrary.core.take(5),
    ...ColorLibrary.extended.take(3),
  ],
);

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required Widget child,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    SettingsScope(
      settings: Settings(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: reduceMotion),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('responsive app shell', () {
    for (final MapEntry<String, Size> screen in _shellSizes.entries) {
      testWidgets('StartScreen fits a ${screen.key}', (
        WidgetTester tester,
      ) async {
        await _pumpShell(
          tester,
          size: screen.value,
          child: StartScreen(onPlay: () {}),
        );
        await tester.pump(const Duration(seconds: 2));

        expect(find.byKey(const Key('start-screen')), findsOneWidget);
        expect(find.text('COLORIBOO'), findsOneWidget);
        expect(find.byKey(const Key('play-button')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('LoadingScreen fits a ${screen.key}', (
        WidgetTester tester,
      ) async {
        await _pumpShell(
          tester,
          size: screen.value,
          child: LoadingScreen(
            task: () async {},
            onComplete: () {},
            minimumDisplay: Duration.zero,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const Key('loading-screen')), findsOneWidget);
        expect(find.text('BOO’S TWILIGHT\nPRISM GARDEN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('SessionEndScreen fits a ${screen.key}', (
        WidgetTester tester,
      ) async {
        await _pumpShell(
          tester,
          size: screen.value,
          child: SessionEndScreen(
            summary: _sampleSummary,
            onPlayAgain: () {},
            onBackToStart: () {},
          ),
        );
        await tester.pump(const Duration(seconds: 2));

        expect(find.byKey(const Key('session-end-screen')), findsOneWidget);
        expect(find.text('YOU MADE THE SKY GLOW!'), findsOneWidget);
        expect(find.byKey(const Key('play-again-button')), findsOneWidget);
        expect(find.byKey(const Key('back-to-start-button')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('reduced motion app shell', () {
    testWidgets('StartScreen reacts immediately and enters once', (
      WidgetTester tester,
    ) async {
      int feedbackCount = 0;
      int playCount = 0;
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        reduceMotion: true,
        child: StartScreen(
          onPlayFeedback: () => feedbackCount++,
          onPlay: () => playCount++,
        ),
      );

      await tester.tap(find.byKey(const Key('play-button')));
      await tester.pump(const Duration(milliseconds: 1));

      expect(feedbackCount, 1);
      expect(playCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoadingScreen completes without its motion tail', (
      WidgetTester tester,
    ) async {
      int taskCount = 0;
      int completionCount = 0;
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        reduceMotion: true,
        child: LoadingScreen(
          task: () async => taskCount++,
          onComplete: () => completionCount++,
          minimumDisplay: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(taskCount, 1);
      expect(completionCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SessionEndScreen actions stay usable', (
      WidgetTester tester,
    ) async {
      int playAgainCount = 0;
      int backCount = 0;
      int booTapCount = 0;
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        reduceMotion: true,
        child: SessionEndScreen(
          summary: _sampleSummary,
          onPlayAgain: () => playAgainCount++,
          onBackToStart: () => backCount++,
          onBooTap: () => booTapCount++,
        ),
      );

      final AnimatedScale playAgainScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byKey(const Key('play-again-button')),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(playAgainScale.duration, Duration.zero);

      await tester.tap(find.byKey(const Key('play-again-button')));
      await tester.tap(find.byKey(const Key('back-to-start-button')));
      await tester.tap(find.bySemanticsLabel('Boo'));
      await tester.pump();

      expect(playAgainCount, 1);
      expect(backCount, 1);
      expect(booTapCount, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
