import 'dart:io';

import 'package:colorsquest/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A lightweight cross-form-factor render check for the V2 composition.
void main() {
  testWidgets('renders the V2 world at phone, landscape and tablet sizes', (
    WidgetTester tester,
  ) async {
    const Map<String, Size> frames = <String, Size>{
      'phone': Size(390, 844),
      'landscape': Size(844, 390),
      'tablet': Size(834, 1194),
    };

    for (final MapEntry<String, Size> frame in frames.entries) {
      // Fully remove the previous ColorGameApp so every frame starts at the
      // real StartScreen instead of preserving the last loop's state.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.physicalSize = frame.value;
      tester.view.devicePixelRatio = 1;
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
        if (find.byKey(const Key('dreamscape-screen')).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ColorGameApp), findsOneWidget, reason: frame.key);
      expect(find.byKey(const Key('dreamscape-screen')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: frame.key);

      if (const String.fromEnvironment('COLORIBOO_CAPTURE') == 'true') {
        await expectLater(
          find.byType(ColorGameApp),
          matchesGoldenFile(
            '${Directory.systemTemp.path}/coloriboo-v2-${frame.key}.png',
          ),
        );
      }
    }
    tester.view.reset();
  });
}
