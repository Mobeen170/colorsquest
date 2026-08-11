// Smoke test for Coloriboo.
//
// This checks that the app root builds and the home screen shows its branding
// and its start button.

import 'package:flutter_test/flutter_test.dart';

import 'package:colorsquest/main.dart';

void main() {
  testWidgets('Coloriboo home screen renders', (WidgetTester tester) async {
    // Build the real app root.
    await tester.pumpWidget(const ColorGameApp());

    // Draw a single frame.
    //
    // Do not use pumpAndSettle() here: the home screen runs a looping
    // background animation that never finishes, so pumpAndSettle would wait
    // forever and time out.
    await tester.pump();

    expect(find.text('Coloriboo'), findsOneWidget);
    expect(find.text('Pop. Play. Learn Colors!'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
  });
}
