// Visual smoke checks for the production Boo treatment.

import 'package:colorsquest/boo/boo.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/world/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _assetNameOf(ImageProvider<Object> provider) {
  ImageProvider<Object> current = provider;

  while (current is ResizeImage) {
    current = current.imageProvider;
  }

  if (current is AssetImage) {
    return current.assetName;
  }

  return '';
}

void main() {
  testWidgets('Boo uses painted family art with exact colour auras', (
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
                  Builder(
                    builder: (BuildContext context) {
                      final ColorEntry entry = ColorLibrary.byName(name)!;
                      return Boo(
                        size: 170,
                        mood: BooMood.waiting,
                        color: entry,
                        tint: entry.color,
                      );
                    },
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
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .map((Image image) => _assetNameOf(image.image))
          .toSet(),
      hasLength(5),
    );
    expect(find.byType(ColorFiltered), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
