import 'package:flutter/material.dart';

import '../colors/color_library.dart';

/// The story or feedback role Boo is playing right now.
///
/// These states are intentionally semantic. Callers ask for a role and the
/// catalog chooses the artwork, so asset paths never leak into game widgets.
enum BooVisualState {
  idle,
  welcome,
  waiting,
  alert,
  thinking,
  pointing,
  encouraging,
  tryAgain,
  correct,
  loading,
  mixing,
  magic,
  celebration,
  bigCelebration,
  goodbye,
}

/// The ten Boo color families that have dedicated painted artwork.
enum BooColorVariant {
  red,
  orange,
  yellow,
  green,
  blue,
  purple,
  pink,
  brown,
  white,
  black,
}

/// One production Boo image and the non-destructive viewport tuning it needs.
///
/// [displayScale] and [alignment] compensate for the source canvas shape in
/// Flutter. The source pixels themselves remain untouched and every renderer
/// must continue to use `BoxFit.contain`.
@immutable
class BooAssetSpec {
  const BooAssetSpec({
    required this.path,
    required this.sourcePixelSize,
    this.displayScale = 1,
    this.alignment = Alignment.center,
  });

  final String path;
  final Size sourcePixelSize;
  final double displayScale;
  final Alignment alignment;
}

/// The single source of truth for every Boo image shipped by Coloriboo.
abstract final class BooAssetCatalog {
  /// The V1 image is retained solely as a defensive decode/load fallback.
  static const String fallbackPath = 'assets/images/boo.png';

  /// Mascot art never renders larger than roughly 260 logical pixels.
  ///
  /// Decoding the original 1536px exports at this width keeps them crisp on
  /// high-density screens without placing dozens of full-resolution bitmaps
  /// in Flutter's image cache.
  static const int decodeWidth = 1024;

  static ImageProvider<Object> providerFor(String path) =>
      ResizeImage.resizeIfNeeded(decodeWidth, null, AssetImage(path));

  static const BooAssetSpec red = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_red.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec orange = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_orange.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec yellow = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_yellow.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec green = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_green.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec blue = BooAssetSpec(
    path: 'assets/mascot/boo/core/boo_idle_blue.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec purple = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_purple.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec pink = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_pink.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec brown = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_brown.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec white = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_white.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );
  static const BooAssetSpec black = BooAssetSpec(
    path: 'assets/mascot/boo/colors/boo_black.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.36,
  );

  static const BooAssetSpec correctRed = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_correct_red.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.34,
  );
  static const BooAssetSpec tryAgainOrange = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_try_again_orange.png',
    sourcePixelSize: Size(1024, 1536),
    displayScale: 1.1,
    alignment: Alignment(0, 0.05),
  );
  static const BooAssetSpec loadingYellow = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_loading_yellow.png',
    sourcePixelSize: Size(1254, 1254),
    displayScale: 1.02,
  );
  static const BooAssetSpec waitingGreen = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_waiting_green.png',
    sourcePixelSize: Size(1024, 1536),
    displayScale: 1.1,
    alignment: Alignment(0, 0.05),
  );
  static const BooAssetSpec alertBlue = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_alert_blue.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.34,
  );
  static const BooAssetSpec thinkingPurple = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_thinking_purple.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.34,
  );
  static const BooAssetSpec encouragingPink = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_encouraging_pink.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.34,
  );
  static const BooAssetSpec pointingBrown = BooAssetSpec(
    path: 'assets/mascot/boo/states/boo_pointing_brown.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.34,
  );
  static const BooAssetSpec bigCelebrationBlack = BooAssetSpec(
    path: 'assets/mascot/boo/special/boo_big_celebration_black.png',
    sourcePixelSize: Size(1536, 1024),
    displayScale: 1.3,
  );
  static const BooAssetSpec magicPearl = BooAssetSpec(
    path: 'assets/mascot/boo/special/boo_magic_pearl.png',
    sourcePixelSize: Size(1024, 1536),
    displayScale: 1.08,
  );

  /// The canonical blue Boo used for idle, welcome, and defensive fallback.
  static const BooAssetSpec canonical = blue;

  /// Artwork for the ten named color families.
  static const Map<BooColorVariant, BooAssetSpec> variantAssets =
      <BooColorVariant, BooAssetSpec>{
        BooColorVariant.red: red,
        BooColorVariant.orange: orange,
        BooColorVariant.yellow: yellow,
        BooColorVariant.green: green,
        BooColorVariant.blue: blue,
        BooColorVariant.purple: purple,
        BooColorVariant.pink: pink,
        BooColorVariant.brown: brown,
        BooColorVariant.white: white,
        BooColorVariant.black: black,
      };

  /// Stable artwork choices for every semantic state.
  static const Map<BooVisualState, BooAssetSpec> stateAssets =
      <BooVisualState, BooAssetSpec>{
        BooVisualState.idle: canonical,
        BooVisualState.welcome: canonical,
        BooVisualState.waiting: waitingGreen,
        BooVisualState.alert: alertBlue,
        BooVisualState.thinking: thinkingPurple,
        BooVisualState.pointing: pointingBrown,
        BooVisualState.encouraging: encouragingPink,
        BooVisualState.tryAgain: tryAgainOrange,
        BooVisualState.correct: correctRed,
        BooVisualState.loading: loadingYellow,
        BooVisualState.mixing: magicPearl,
        BooVisualState.magic: magicPearl,
        BooVisualState.celebration: correctRed,
        BooVisualState.bigCelebration: bigCelebrationBlack,
        BooVisualState.goodbye: encouragingPink,
      };

  /// Every accepted production image, once each.
  static const List<BooAssetSpec> all = <BooAssetSpec>[
    blue,
    red,
    orange,
    yellow,
    green,
    purple,
    pink,
    brown,
    white,
    black,
    correctRed,
    tryAgainOrange,
    loadingYellow,
    waitingGreen,
    alertBlue,
    thinkingPurple,
    encouragingPink,
    pointingBrown,
    bigCelebrationBlack,
    magicPearl,
  ];

  static const List<String> allPaths = <String>[
    'assets/mascot/boo/core/boo_idle_blue.png',
    'assets/mascot/boo/colors/boo_red.png',
    'assets/mascot/boo/colors/boo_orange.png',
    'assets/mascot/boo/colors/boo_yellow.png',
    'assets/mascot/boo/colors/boo_green.png',
    'assets/mascot/boo/colors/boo_purple.png',
    'assets/mascot/boo/colors/boo_pink.png',
    'assets/mascot/boo/colors/boo_brown.png',
    'assets/mascot/boo/colors/boo_white.png',
    'assets/mascot/boo/colors/boo_black.png',
    'assets/mascot/boo/states/boo_correct_red.png',
    'assets/mascot/boo/states/boo_try_again_orange.png',
    'assets/mascot/boo/states/boo_loading_yellow.png',
    'assets/mascot/boo/states/boo_waiting_green.png',
    'assets/mascot/boo/states/boo_alert_blue.png',
    'assets/mascot/boo/states/boo_thinking_purple.png',
    'assets/mascot/boo/states/boo_encouraging_pink.png',
    'assets/mascot/boo/states/boo_pointing_brown.png',
    'assets/mascot/boo/special/boo_big_celebration_black.png',
    'assets/mascot/boo/special/boo_magic_pearl.png',
  ];

  /// Common shell and feedback images to warm up at startup.
  ///
  /// Color variants and the black milestone image intentionally load on
  /// demand, avoiding a large eager decode cost for rare artwork.
  static const List<String> frequentPreloadPaths = <String>[
    'assets/mascot/boo/core/boo_idle_blue.png',
    'assets/mascot/boo/states/boo_loading_yellow.png',
    'assets/mascot/boo/states/boo_correct_red.png',
    'assets/mascot/boo/states/boo_try_again_orange.png',
    'assets/mascot/boo/states/boo_waiting_green.png',
    'assets/mascot/boo/states/boo_alert_blue.png',
    'assets/mascot/boo/states/boo_thinking_purple.png',
    'assets/mascot/boo/states/boo_encouraging_pink.png',
    'assets/mascot/boo/states/boo_pointing_brown.png',
    'assets/mascot/boo/special/boo_magic_pearl.png',
  ];

  static BooAssetSpec forState(BooVisualState state) =>
      stateAssets[state] ?? canonical;

  static BooAssetSpec forVariant(BooColorVariant variant) =>
      variantAssets[variant] ?? canonical;

  /// Returns the nearest painted core family for any Coloriboo shade.
  ///
  /// Chromatic shades use the nearest core hue. Earth tones and neutrals need
  /// small semantic rules because brown, black, and white do not occupy useful
  /// positions on a hue wheel. Future colors still receive a deterministic
  /// fallback from their hue and luminance.
  static BooColorVariant variantForColor(ColorEntry color) {
    final String name = color.name.toLowerCase();
    final BooColorVariant? exactCore = _exactCoreVariant(name);
    if (exactCore != null) return exactCore;

    const Set<String> earthTones = <String>{
      'chocolate',
      'copper',
      'bronze',
      'tan',
      'beige',
    };
    if (earthTones.contains(name)) return BooColorVariant.brown;

    const Set<String> softWhites = <String>{'cream', 'ivory', 'silver'};
    if (softWhites.contains(name)) return BooColorVariant.white;

    const Set<String> redShades = <String>{
      'crimson',
      'scarlet',
      'maroon',
      'burgundy',
      'coral',
      'salmon',
    };
    if (redShades.contains(name)) return BooColorVariant.red;

    const Set<String> pinkShades = <String>{'rose', 'blush'};
    if (pinkShades.contains(name)) return BooColorVariant.pink;

    if (color.hue < 0) {
      return color.color.computeLuminance() >= 0.55
          ? BooColorVariant.white
          : BooColorVariant.black;
    }

    final double hue = color.hue % 360;
    if (hue < 15 || hue >= 345) return BooColorVariant.red;
    if (hue < 38) return BooColorVariant.orange;
    if (hue < 89) return BooColorVariant.yellow;
    if (hue < 172) return BooColorVariant.green;
    if (hue < 243) return BooColorVariant.blue;
    if (hue < 301) return BooColorVariant.purple;
    return BooColorVariant.pink;
  }

  static BooAssetSpec forColor(ColorEntry color) =>
      forVariant(variantForColor(color));

  /// Resolves one stable image. A concrete color takes priority over an
  /// explicit family, which takes priority over the semantic state.
  static BooAssetSpec resolve({
    BooVisualState state = BooVisualState.idle,
    BooColorVariant? variant,
    ColorEntry? color,
  }) {
    if (color != null) return forColor(color);
    if (variant != null) return forVariant(variant);
    return forState(state);
  }

  static BooColorVariant? _exactCoreVariant(String name) {
    return switch (name) {
      'red' => BooColorVariant.red,
      'orange' => BooColorVariant.orange,
      'yellow' => BooColorVariant.yellow,
      'green' => BooColorVariant.green,
      'blue' => BooColorVariant.blue,
      'purple' => BooColorVariant.purple,
      'pink' => BooColorVariant.pink,
      'brown' => BooColorVariant.brown,
      'white' => BooColorVariant.white,
      'black' => BooColorVariant.black,
      _ => null,
    };
  }
}
