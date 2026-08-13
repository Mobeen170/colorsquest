import 'package:colorsquest/activities/boo_changes_colour.dart';
import 'package:colorsquest/activities/colour_mixing_lab.dart';
import 'package:colorsquest/activities/light_to_dark.dart';
import 'package:colorsquest/activities/odd_one_out.dart';
import 'package:colorsquest/activities/pop_the_colour.dart';
import 'package:colorsquest/app_theme.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/colors/color_mixes.dart';
import 'package:colorsquest/colors/color_picker_logic.dart';
import 'package:colorsquest/colors/shade_ladder.dart';
import 'package:colorsquest/settings/settings.dart';
import 'package:colorsquest/world/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

final ColorEntry _red = ColorLibrary.byName('Red')!;
final ColorEntry _blue = ColorLibrary.byName('Blue')!;
final ColorEntry _yellow = ColorLibrary.byName('Yellow')!;

Widget _host(
  Widget child, {
  required Settings settings,
  bool reduceMotion = true,
}) {
  return SettingsScope(
    settings: settings,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Settings _settingsForTest() {
  final Settings settings = Settings();
  addTearDown(settings.dispose);
  return settings;
}

void main() {
  testWidgets('Odd One Out retries safely and then completes', (
    WidgetTester tester,
  ) async {
    final List<AnswerOutcome> outcomes = <AnswerOutcome>[];
    await tester.pumpWidget(
      _host(
        OddOneOut(
          common: _blue,
          odd: _red,
          total: 3,
          missCount: 0,
          onAnswer: outcomes.add,
          onBooTapped: () {},
        ),
        settings: _settingsForTest(),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Blue'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Red'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Blue').first);
    await tester.pump();
    expect(outcomes, hasLength(1));
    expect(outcomes.single.correct, isFalse);
    expect(outcomes.single.tapped.name, 'Blue');
    expect(find.byType(SoapBubble), findsNWidgets(3));

    await tester.tap(find.bySemanticsLabel('Red'));
    await tester.pump();
    expect(outcomes, hasLength(2));
    expect(outcomes.last.correct, isTrue);
    expect(outcomes.last.tapped.name, 'Red');
  });

  testWidgets('Boo’s Magic preserves the target after a retry and completes', (
    WidgetTester tester,
  ) async {
    final List<AnswerOutcome> outcomes = <AnswerOutcome>[];
    await tester.pumpWidget(
      _host(
        BooChangesColour(
          round: ColorRound(
            target: _red,
            options: <ColorEntry>[_red, _blue, _yellow],
          ),
          missCount: 0,
          onAnswer: outcomes.add,
          onBooTapped: () {},
        ),
        settings: _settingsForTest(),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Boo glowing Red'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Blue'));
    await tester.pump();
    expect(outcomes.single.correct, isFalse);
    expect(find.bySemanticsLabel('Red'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Red'));
    await tester.pump();
    expect(outcomes, hasLength(2));
    expect(outcomes.last.correct, isTrue);
    expect(outcomes.last.tapped.name, 'Red');
  });

  testWidgets('Mixing Lab completes once through its accessible action', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final List<ColorEntry> results = <ColorEntry>[];
    await tester.pumpWidget(
      _host(
        ColourMixingLab(
          mix: ColorMixes.all.first,
          onMixed: (ColorEntry result, Offset _) => results.add(result),
          onBooTapped: () {},
        ),
        settings: _settingsForTest(),
      ),
    );
    await tester.pump();

    final Finder mix = find.bySemanticsLabel(RegExp(r'^Mix Red and Yellow\.'));
    expect(mix, findsOneWidget);
    tester.semantics.tap(
      find.semantics.byLabel(RegExp(r'^Mix Red and Yellow\.')),
    );
    await tester.pump();

    expect(results.map((ColorEntry color) => color.name), <String>['Orange']);
    expect(find.text('Together they make'), findsOneWidget);
    expect(find.text('ORANGE'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);

    expect(
      tester
          .getSemantics(mix)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(results, hasLength(1));
    semantics.dispose();
  });

  testWidgets('Light to Dark completes a near-solved round exactly once', (
    WidgetTester tester,
  ) async {
    final ColorEntry green = ColorLibrary.byName('Green')!;
    final List<ShadeTile> answer = ShadeLadder.shadesFor(green);
    final List<ShadeRound> changes = <ShadeRound>[];
    int completions = 0;
    await tester.pumpWidget(
      _host(
        LightToDark(
          round: ShadeRound(
            base: green,
            correctOrder: answer,
            order: <ShadeTile>[answer[1], answer[0], answer[2], answer[3]],
          ),
          onRoundChanged: changes.add,
          onComplete: (ColorEntry base, Offset _) {
            expect(base.name, 'Green');
            completions++;
          },
          onBooTapped: () {},
        ),
        settings: _settingsForTest(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('shade-slot-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('shade-slot-1')));
    await tester.pump();

    expect(changes, hasLength(1));
    expect(changes.single.isComplete, isTrue);
    expect(completions, 1);
    expect(find.text('A perfect colour sunset!'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);

    await tester.tap(find.byKey(const ValueKey<String>('shade-slot-0')));
    await tester.tap(find.byKey(const ValueKey<String>('shade-slot-1')));
    await tester.pump();
    expect(completions, 1);
  });
}
