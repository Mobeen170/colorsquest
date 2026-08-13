import 'package:colorsquest/dreamscape.dart';
import 'package:colorsquest/main.dart';
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

  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));

    if (find.byType(Dreamscape).evaluate().isNotEmpty) {
      break;
    }
  }

  await tester.pump(const Duration(milliseconds: 650));

  expect(find.byType(Dreamscape), findsOneWidget);
}

void main() {
  testWidgets('gameplay uses one compact compass navigation control', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester);

    expect(find.byKey(const Key('play-compass-button')), findsOneWidget);

    expect(find.byKey(const Key('kid-home-button')), findsNothing);

    expect(find.byKey(const Key('kid-sound-button')), findsNothing);

    expect(find.byKey(const Key('kid-hear-button')), findsNothing);

    expect(find.byKey(const Key('kid-games-button')), findsNothing);
  });

  testWidgets('compact compass still opens all games', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester);

    await tester.tap(find.byKey(const Key('play-compass-button')));

    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(PlayCompassSheet), findsOneWidget);

    expect(find.byType(PlayCompassSheet), findsOneWidget);
  });

  testWidgets('compact gameplay chrome fits landscape', (
    WidgetTester tester,
  ) async {
    await enterWorld(tester, size: const Size(844, 390));

    expect(tester.takeException(), isNull);

    expect(find.byKey(const Key('play-compass-button')), findsOneWidget);
  });
}
