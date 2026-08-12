import 'dart:io';

import 'package:colorsquest/boo/boo_asset_catalog.dart';
import 'package:colorsquest/colors/color_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BooAssetCatalog', () {
    test('contains every accepted production image exactly once', () {
      expect(BooAssetCatalog.all, hasLength(20));
      expect(BooAssetCatalog.allPaths, hasLength(20));
      expect(
        BooAssetCatalog.all.map((asset) => asset.path).toSet(),
        hasLength(20),
      );
      expect(BooAssetCatalog.allPaths.toSet(), hasLength(20));
      expect(
        BooAssetCatalog.all.map((asset) => asset.path).toSet(),
        BooAssetCatalog.allPaths.toSet(),
      );
    });

    test('all catalog paths are production PNGs that exist', () {
      for (final String path in BooAssetCatalog.allPaths) {
        expect(path, startsWith('assets/mascot/boo/'));
        expect(path, endsWith('.png'));
        expect(path, isNot(contains('to_put_in_use')));
        expect(File(path).existsSync(), isTrue, reason: 'Missing $path');
      }
      expect(File(BooAssetCatalog.fallbackPath).existsSync(), isTrue);
    });

    test('canonical and every semantic state resolve deterministically', () {
      expect(BooAssetCatalog.canonical.path, contains('boo_idle_blue.png'));
      expect(
        BooAssetCatalog.forState(BooVisualState.idle).path,
        BooAssetCatalog.canonical.path,
      );
      expect(
        BooAssetCatalog.forState(BooVisualState.welcome).path,
        BooAssetCatalog.canonical.path,
      );

      for (final BooVisualState state in BooVisualState.values) {
        final BooAssetSpec first = BooAssetCatalog.forState(state);
        final BooAssetSpec second = BooAssetCatalog.forState(state);
        expect(first.path, second.path);
        expect(BooAssetCatalog.allPaths, contains(first.path));
      }
    });

    test('all ten core color variants have dedicated artwork', () {
      expect(BooAssetCatalog.variantAssets, hasLength(10));
      for (final BooColorVariant variant in BooColorVariant.values) {
        expect(BooAssetCatalog.forVariant(variant).path, contains('.png'));
        expect(
          BooAssetCatalog.allPaths,
          contains(BooAssetCatalog.forVariant(variant).path),
        );
      }

      for (final ColorEntry color in ColorLibrary.core) {
        final String expectedFileName = color.name == 'Blue'
            ? 'boo_idle_blue.png'
            : 'boo_${color.name.toLowerCase()}.png';
        expect(
          BooAssetCatalog.forColor(color).path,
          contains(expectedFileName),
        );
      }
    });

    test('extended shades resolve to a stable nearest core family', () {
      expect(
        BooAssetCatalog.variantForColor(ColorLibrary.byName('Sky Blue')!),
        BooColorVariant.blue,
      );
      expect(
        BooAssetCatalog.variantForColor(ColorLibrary.byName('Forest')!),
        BooColorVariant.green,
      );
      expect(
        BooAssetCatalog.variantForColor(ColorLibrary.byName('Chocolate')!),
        BooColorVariant.brown,
      );
      expect(
        BooAssetCatalog.variantForColor(ColorLibrary.byName('Cream')!),
        BooColorVariant.white,
      );

      for (final ColorEntry color in ColorLibrary.all) {
        final String first = BooAssetCatalog.forColor(color).path;
        final String second = BooAssetCatalog.forColor(color).path;
        expect(first, second);
        expect(BooAssetCatalog.allPaths, contains(first));
      }
    });

    test('resolve applies color, then variant, then state precedence', () {
      final ColorEntry green = ColorLibrary.byName('Green')!;
      expect(
        BooAssetCatalog.resolve(
          state: BooVisualState.loading,
          variant: BooColorVariant.red,
          color: green,
        ).path,
        BooAssetCatalog.green.path,
      );
      expect(
        BooAssetCatalog.resolve(
          state: BooVisualState.loading,
          variant: BooColorVariant.red,
        ).path,
        BooAssetCatalog.red.path,
      );
      expect(
        BooAssetCatalog.resolve(state: BooVisualState.loading).path,
        BooAssetCatalog.loadingYellow.path,
      );
    });

    test('viewport metadata is safe and preload excludes rare artwork', () {
      for (final BooAssetSpec asset in BooAssetCatalog.all) {
        expect(asset.displayScale, inInclusiveRange(1, 1.5));
        expect(asset.sourcePixelSize.width, greaterThan(0));
        expect(asset.sourcePixelSize.height, greaterThan(0));
      }
      expect(
        BooAssetCatalog.frequentPreloadPaths,
        isNot(contains(BooAssetCatalog.bigCelebrationBlack.path)),
      );
      expect(
        BooAssetCatalog.frequentPreloadPaths,
        contains(BooAssetCatalog.canonical.path),
      );
      expect(
        BooAssetCatalog.frequentPreloadPaths.toSet().length,
        BooAssetCatalog.frequentPreloadPaths.length,
      );
    });
  });
}
