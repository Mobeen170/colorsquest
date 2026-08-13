import 'package:colorsquest/boo/boo.dart';
import 'package:colorsquest/boo/boo_asset_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required BooVisualState state,
  bool reduceMotion = false,
  double size = 180,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: Boo(
            key: const ValueKey<String>('test-boo'),
            size: size,
            mood: BooMood.cheer,
            visualState: state,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses a stable contain-only viewport for every artwork', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(state: BooVisualState.idle));

    final Finder boo = find.byType(Boo);
    final Finder frame = find.byKey(
      ValueKey<String>('boo-artwork-${BooAssetCatalog.canonical.path}'),
    );
    final Image image = tester.widget<Image>(
      find.descendant(of: frame, matching: find.byType(Image)).first,
    );

    expect(tester.getSize(boo), const Size.square(180));
    expect(tester.getSize(frame), const Size.square(180));
    expect(image.width, 180);
    expect(image.height, 180);
    expect(image.fit, BoxFit.contain);
    expect(image.gaplessPlayback, isTrue);
    expect(image.image, isA<ResizeImage>());
    expect(image.color, isNull);
    expect(
      find.descendant(of: boo, matching: find.byType(AnimatedSwitcher)),
      findsNothing,
    );

    for (final Transform transform in tester.widgetList<Transform>(
      find.descendant(of: boo, matching: find.byType(Transform)),
    )) {
      final List<double> matrix = transform.transform.storage;
      expect(matrix[0], closeTo(matrix[5], 0.000001));
    }
  });

  testWidgets('swaps artwork without changing Boo layout size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(state: BooVisualState.idle, size: 156));
    expect(tester.getSize(find.byType(Boo)), const Size.square(156));

    await tester.pumpWidget(_host(state: BooVisualState.correct, size: 156));
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      find.byKey(
        ValueKey<String>('boo-artwork-${BooAssetCatalog.correctRed.path}'),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(Boo)), const Size.square(156));

    for (final Image image in tester.widgetList<Image>(
      find.descendant(of: find.byType(Boo), matching: find.byType(Image)),
    )) {
      expect(image.fit, BoxFit.contain);
      expect(image.gaplessPlayback, isTrue);
    }

    expect(tester.getSize(find.byType(Boo)), const Size.square(156));
  });

  testWidgets('reduced motion swaps artwork immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(state: BooVisualState.loading, reduceMotion: true),
    );

    expect(
      find.descendant(
        of: find.byType(Boo),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );

    await tester.pumpWidget(
      _host(state: BooVisualState.tryAgain, reduceMotion: true),
    );
    await tester.pump();

    expect(
      find.byKey(
        ValueKey<String>('boo-artwork-${BooAssetCatalog.tryAgainOrange.path}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('boo-artwork-${BooAssetCatalog.loadingYellow.path}'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps Boo semantics and legacy fallback contract', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(_host(state: BooVisualState.welcome));

    expect(find.bySemanticsLabel('Boo'), findsOneWidget);
    expect(Boo.artworkPath, BooAssetCatalog.fallbackPath);
    semantics.dispose();
  });

  testWidgets('a failed state cascades to uncolored canonical artwork', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(state: BooVisualState.idle));

    final dynamic state = tester.state(find.byType(Boo));
    final Widget fallback = state.buildFallbackFor(
      BooAssetCatalog.tryAgainOrange,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: SizedBox.square(dimension: 180, child: fallback)),
      ),
    );
    await tester.pump();

    final Image canonical = tester.widget<Image>(find.byType(Image).first);
    final ResizeImage resized = canonical.image as ResizeImage;
    expect(
      resized.imageProvider,
      const AssetImage('assets/mascot/boo/core/boo_idle_blue.png'),
    );
    expect(canonical.fit, BoxFit.contain);
    expect(canonical.color, isNull);
    expect(tester.takeException(), isNull);
  });
}
