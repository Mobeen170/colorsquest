// Visual smoke checks for the production Boo treatment.

import 'package:colorsquest/boo/boo.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/world/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Boo keeps one original image while exact colour auras change', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 240);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: <Widget>[
            const PaperBackground(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (final String name in <String>[
                  'White',
                  'Black',
                  'Red',
                  'Yellow',
                  'Purple',
                ])
                  Boo(
                    size: 170,
                    mood: BooMood.waiting,
                    tint: ColorLibrary.byName(name)!.color,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(Boo), findsNWidgets(5));
    expect(find.byType(Image), findsNWidgets(5));
    expect(find.byType(ColorFiltered), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
