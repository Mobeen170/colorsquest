import 'package:colorsquest/activities/boo_changes_colour.dart';
import 'package:colorsquest/boo/boo.dart';
import 'package:colorsquest/boo/boo_asset_catalog.dart';
import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
import 'package:colorsquest/world/wonder_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _enterWorld(
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

  expect(find.byKey(const Key('play-button')), findsOneWidget);

  await tester.tap(find.byKey(const Key('play-button')));

  for (int attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));

    if (find.byType(Dreamscape).evaluate().isNotEmpty) {
      break;
    }
  }

  // Clear Start/Loading AnimatedSwitcher remnants.
  await tester.pump(const Duration(milliseconds: 800));

  expect(find.byType(Dreamscape), findsOneWidget);
}

Future<void> _openActivity(WidgetTester tester, String activityName) async {
  final Finder games = find.byKey(const Key('play-compass-button'));

  expect(games, findsOneWidget);

  await tester.tap(games);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));

  expect(find.byType(PlayCompassSheet), findsOneWidget);

  final Finder choice = find.descendant(
    of: find.byType(PlayCompassSheet),
    matching: find.bySemanticsLabel(
      RegExp('^${RegExp.escape(activityName)}\\.'),
    ),
  );

  expect(
    choice,
    findsOneWidget,
    reason: 'Could not find $activityName in the game chooser.',
  );

  final Finder sheetScrollable = find.descendant(
    of: find.byType(PlayCompassSheet),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    choice,
    120,
    scrollable: sheetScrollable.last,
  );
  await tester.pump();

  await tester.tap(choice);
  await tester.pump();

  // Let the bottom sheet fully disappear before inspecting Boo.
  await tester.pump(const Duration(milliseconds: 850));

  expect(find.byType(PlayCompassSheet), findsNothing);
}

void _expectNoAnswerColoredBoo(
  WidgetTester tester,
  String activity,
  BooVisualState expectedState,
) {
  final List<Boo> boos = tester.widgetList<Boo>(find.byType(Boo)).toList();

  expect(boos, isNotEmpty, reason: '$activity should still show Boo.');
  for (final Boo boo in boos) {
    expect(
      boo.color,
      isNull,
      reason: '$activity must not select target-family artwork before success.',
    );
    expect(
      boo.colorVariant,
      isNull,
      reason:
          '$activity must not select a target color variant before success.',
    );
    expect(
      boo.tint,
      isNull,
      reason: '$activity must not show a target-colored aura before success.',
    );
    expect(
      boo.visualState,
      expectedState,
      reason: '$activity should use answer-independent question artwork.',
    );
  }
}

void main() {
  testWidgets('Pop prompt never reveals the target through Boo', (
    WidgetTester tester,
  ) async {
    await _enterWorld(tester);

    _expectNoAnswerColoredBoo(tester, 'Pop the Colour', BooVisualState.idle);
  });

  for (final MapEntry<String, BooVisualState> activity
      in <String, BooVisualState>{
        'Odd One Out': BooVisualState.thinking,
        'Mixing Lab': BooVisualState.magic,
        'Light to Dark': BooVisualState.thinking,
      }.entries) {
    testWidgets('${activity.key} question art is answer-independent', (
      WidgetTester tester,
    ) async {
      await _enterWorld(tester);
      await _openActivity(tester, activity.key);

      _expectNoAnswerColoredBoo(tester, activity.key, activity.value);
    });
  }

  testWidgets('Boo’s Magic uses the real target-family mascot art', (
    WidgetTester tester,
  ) async {
    await _enterWorld(tester);
    await _openActivity(tester, 'Boo’s Magic');

    final Finder activityFinder = find.byType(BooChangesColour);

    expect(activityFinder, findsOneWidget);

    final BooChangesColour activity = tester.widget<BooChangesColour>(
      activityFinder,
    );

    final target = activity.round.target;

    final Finder targetBoo = find.byWidgetPredicate(
      (Widget widget) =>
          widget is Boo &&
          widget.color?.name == target.name &&
          widget.tint == target.color,
    );

    expect(
      targetBoo,
      findsOneWidget,
      reason: 'Boo’s Magic should intentionally show the target color family.',
    );

    final String expectedPath = BooAssetCatalog.forColor(target).path;
    final Finder artworkFrame = find.descendant(
      of: targetBoo,
      matching: find.byKey(ValueKey<String>('boo-artwork-$expectedPath')),
    );
    expect(artworkFrame, findsOneWidget);

    final Image renderedImage = tester.widget<Image>(
      find.descendant(of: artworkFrame, matching: find.byType(Image)).first,
    );
    ImageProvider<Object> provider = renderedImage.image;
    while (provider is ResizeImage) {
      provider = provider.imageProvider;
    }

    expect(provider, isA<AssetImage>());
    expect((provider as AssetImage).assetName, expectedPath);
    expect(renderedImage.fit, BoxFit.contain);
  });
}
