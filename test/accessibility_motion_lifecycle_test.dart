import 'dart:async';

import 'package:colorsquest/activities/boo_changes_colour.dart';
import 'package:colorsquest/activities/colour_mixing_lab.dart';
import 'package:colorsquest/activities/light_to_dark.dart';
import 'package:colorsquest/activities/odd_one_out.dart';
import 'package:colorsquest/activities/pop_the_colour.dart';
import 'package:colorsquest/app_theme.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/colors/color_picker_logic.dart';
import 'package:colorsquest/colors/color_mixes.dart';
import 'package:colorsquest/colors/shade_ladder.dart';
import 'package:colorsquest/screens/loading_screen.dart';
import 'package:colorsquest/screens/start_screen.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:colorsquest/widgets/kid_controls.dart';
import 'package:colorsquest/world/bubble.dart';
import 'package:colorsquest/world/bubble_field.dart';
import 'package:colorsquest/world/splash_marks.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final ColorEntry _red = ColorLibrary.core.firstWhere(
  (ColorEntry color) => color.name == 'Red',
);
final ColorEntry _blue = ColorLibrary.core.firstWhere(
  (ColorEntry color) => color.name == 'Blue',
);
final ColorEntry _yellow = ColorLibrary.core.firstWhere(
  (ColorEntry color) => color.name == 'Yellow',
);
final ColorRound _round = ColorRound(
  target: _red,
  options: <ColorEntry>[_red, _blue, _yellow],
);

Widget _host({
  required Widget child,
  required Settings settings,
  bool reduceMotion = false,
  Size size = const Size(390, 844),
}) {
  return SettingsScope(
    settings: settings,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: reduceMotion),
        child: Scaffold(body: SizedBox.expand(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('reduced motion leaves no activity or ambient ticker running', (
    WidgetTester tester,
  ) async {
    final Settings settings = Settings();
    addTearDown(settings.dispose);

    final Map<String, Widget> cases = <String, Widget>{
      'Pop the Colour': PopTheColour(
        round: _round,
        missCount: 0,
        onAnswer: (_) {},
        onBooTapped: () {},
      ),
      'Odd One Out': OddOneOut(
        common: _blue,
        odd: _red,
        total: 3,
        missCount: 0,
        onAnswer: (_) {},
        onBooTapped: () {},
      ),
      'Boo Changes Colour': BooChangesColour(
        round: _round,
        missCount: 0,
        onAnswer: (_) {},
        onBooTapped: () {},
      ),
      'Colour Mixing Lab': ColourMixingLab(
        mix: ColorMixes.all.first,
        onMixed: (_, _) {},
        onBooTapped: () {},
      ),
      'Light to Dark': LightToDark(
        round: ShadeLadder.buildRound(base: _red),
        onComplete: (_, _) {},
        onBooTapped: () {},
      ),
      'ambient world': Stack(
        children: <Widget>[
          const Positioned.fill(child: BubbleField(count: 8)),
          Positioned.fill(
            child: SplashMarksLayer(
              marks: <SplashMark>[
                SplashMark(
                  position: const Offset(0.5, 0.5),
                  color: _red.color,
                  radius: 0.12,
                  seed: 7,
                  bornAt: DateTime(2026),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: WonderCelebration(
              color: Colors.red,
              label: 'Red',
              big: true,
            ),
          ),
        ],
      ),
    };

    for (final MapEntry<String, Widget> entry in cases.entries) {
      await tester.pumpWidget(
        _host(child: entry.value, settings: settings, reduceMotion: true),
      );
      await tester.pump();

      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: '${entry.key} must render a settled frame',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets('enabling reduced motion stops already-running tickers', (
    WidgetTester tester,
  ) async {
    final Settings settings = Settings();
    addTearDown(settings.dispose);

    Widget activity() => PopTheColour(
      key: const ValueKey<String>('motion-activity'),
      round: _round,
      missCount: 0,
      onAnswer: (_) {},
      onBooTapped: () {},
    );

    await tester.pumpWidget(_host(child: activity(), settings: settings));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(
      _host(child: activity(), settings: settings, reduceMotion: true),
    );
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visible color information and success feedback are announced', (
    WidgetTester tester,
  ) async {
    final Settings settings = Settings();
    addTearDown(settings.dispose);
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        settings: settings,
        reduceMotion: true,
        child: BooChangesColour(
          round: _round,
          missCount: 0,
          onAnswer: (_) {},
          onBooTapped: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Boo glowing Red'), findsOneWidget);
    expect(find.bySemanticsLabel('Red'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        settings: settings,
        reduceMotion: true,
        child: const WonderCelebration(
          color: Colors.red,
          label: 'Red',
          big: false,
        ),
      ),
    );

    final Finder feedback = find.bySemanticsLabel(
      RegExp(r'.*Red\. You found the color!'),
    );
    expect(feedback, findsOneWidget);
    expect(tester.getSemantics(feedback).flagsCollection.isLiveRegion, isTrue);

    semantics.dispose();
  });

  testWidgets('small visuals retain meaningful child tap targets', (
    WidgetTester tester,
  ) async {
    final Settings settings = Settings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _host(
        settings: settings,
        size: const Size(844, 390),
        child: Center(
          child: SizedBox(
            width: 180,
            child: KidNavButton(
              label: 'GAMES',
              semanticLabel: 'Choose another game',
              icon: Icons.explore_rounded,
              accent: AppColors.bubblePurple,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(KidNavButton)).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );

    await tester.pumpWidget(
      _host(
        settings: settings,
        child: const Center(
          child: SoapBubble(
            color: Colors.blue,
            diameter: 30,
            semanticLabel: 'Blue',
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(SoapBubble)),
      const Size.square(AppSpacing.minTouchTarget),
    );
  });

  testWidgets('activity and shell timers cannot outlive their widgets', (
    WidgetTester tester,
  ) async {
    final Settings settings = Settings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _host(
        settings: settings,
        child: PopTheColour(
          round: _round,
          missCount: 0,
          onAnswer: (_) {},
          onBooTapped: () {},
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Blue'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));

    int playCount = 0;
    await tester.pumpWidget(
      _host(
        settings: settings,
        child: StartScreen(onPlay: () => playCount++),
      ),
    );
    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    expect(playCount, 0);

    final Completer<void> loadingTask = Completer<void>();
    int completionCount = 0;
    await tester.pumpWidget(
      _host(
        settings: settings,
        child: LoadingScreen(
          task: () => loadingTask.future,
          onComplete: () => completionCount++,
          minimumDisplay: Duration.zero,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    loadingTask.complete();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(completionCount, 0);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
