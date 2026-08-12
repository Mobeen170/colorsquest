import 'package:colorsquest/activities/boo_changes_colour.dart';
import 'package:colorsquest/activities/pop_the_colour.dart';
import 'package:colorsquest/boo/boo.dart';
import 'package:colorsquest/boo/boo_asset_catalog.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  await tester.pump();
  await tester.tap(find.byKey(const Key('play-button')));
  await tester.pump(const Duration(milliseconds: 300));
  for (int attempt = 0; attempt < 20; attempt++) {
    if (find.byType(Dreamscape).evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(Dreamscape), findsOneWidget);
}

Future<void> _openActivity(WidgetTester tester, String name) async {
  await _enterWorld(tester);
  await tester.tap(find.byIcon(Icons.explore_rounded));
  await tester.pump(const Duration(milliseconds: 400));
  final Finder choice = find.bySemanticsLabel(
    RegExp('^${RegExp.escape(name)}\\.'),
  );
  await tester.scrollUntilVisible(
    choice,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(choice, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('Pop prompt never reveals the target through Boo', (
    WidgetTester tester,
  ) async {
    await _enterWorld(tester);

    final PopTheColour activity = tester.widget<PopTheColour>(
      find.byType(PopTheColour),
    );
    final Boo askingBoo = tester.widget<Boo>(find.byType(Boo));
    expect(askingBoo.color, isNull);
    expect(askingBoo.colorVariant, isNull);
    expect(
      askingBoo.visualState,
      isNot(anyOf(BooVisualState.correct, BooVisualState.bigCelebration)),
    );

    await tester.tap(
      find.bySemanticsLabel(activity.round.target.name),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 1));

    final Boo successBoo = tester.widget<Boo>(find.byType(Boo));
    expect(successBoo.visualState, BooVisualState.correct);
    expect(successBoo.color, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final MapEntry<String, BooVisualState> expected
      in <String, BooVisualState>{
        'Odd One Out': BooVisualState.thinking,
        'Mixing Lab': BooVisualState.magic,
        'Light to Dark': BooVisualState.thinking,
      }.entries) {
    testWidgets('${expected.key} question art is answer-independent', (
      WidgetTester tester,
    ) async {
      await _openActivity(tester, expected.key);
      final Boo boo = tester.widget<Boo>(find.byType(Boo));
      expect(boo.color, isNull);
      expect(boo.colorVariant, isNull);
      expect(boo.visualState, expected.value);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Boo’s Magic uses the real target-family mascot art', (
    WidgetTester tester,
  ) async {
    await _openActivity(tester, 'Boo’s Magic');

    final BooChangesColour activity = tester.widget<BooChangesColour>(
      find.byType(BooChangesColour),
    );
    final Boo boo = tester.widget<Boo>(find.byType(Boo));
    expect(boo.color?.name, activity.round.target.name);
    expect(boo.tint, activity.round.target.color);
    expect(
      BooAssetCatalog.forColor(boo.color!).path,
      BooAssetCatalog.forColor(activity.round.target).path,
    );
    expect(tester.takeException(), isNull);
  });
}
