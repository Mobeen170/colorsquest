import 'package:flutter/material.dart';

/// All Coloriboo brand colors live here.
///
/// Screens should use these instead of writing raw hex values.
///
/// Note: the colors a child is *learning* are not brand colors. Those live in
/// `lib/colors/color_library.dart`.
class AppColors {
  // This class only holds constants, so it is never created.
  const AppColors._();

  // ---- Original brand palette -------------------------------------------
  static const Color bubbleSky = Color(0xFFEAF9FF);
  static const Color booBlue = Color(0xFF58C9F5);
  static const Color bubblePurple = Color(0xFF8B7CFF);
  static const Color bubblePink = Color(0xFFFF83C6);
  static const Color bubbleMint = Color(0xFF6FE3BC);
  static const Color sunnyPop = Color(0xFFFFD965);
  static const Color darkInk = Color(0xFF26324A);
  static const Color softInk = Color(0xFF64748B);
  static const Color white = Color(0xFFFFFFFF);

  // ---- Soap & Sunlight paper surfaces -----------------------------------
  //
  // The world is a warm watercolour morning. These are the paper it is
  // painted on.

  /// Base paper of the whole world.
  static const Color paperCream = Color(0xFFFFF9F0);

  /// Slightly deeper paper, used for grain and soft shading.
  static const Color paperWarm = Color(0xFFFDEFE0);

  /// The play band: where answer bubbles live.
  ///
  /// Deliberately near-neutral. A bright, colourful background competes with
  /// the colors a child is trying to tell apart, so the middle of the screen
  /// is kept almost colorless and the colorful washes are pushed to the edges.
  static const Color playBand = Color(0xFFFEFCF8);

  /// Contact shadows where a bubble touches the paper.
  static const Color paperShadow = Color(0xFFE8D9C8);
}

/// Spacing steps, so screens never invent their own numbers.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Smallest size anything a child taps is allowed to be.
  ///
  /// The usual Material minimum is 48. Small children need more.
  static const double minTouchTarget = 72;

  /// Smallest gap allowed between two tappable bubbles.
  static const double minBubbleGap = 16;
}

/// How big things are on this particular screen.
///
/// Everything scales from the shortest side, so the layout behaves the same
/// in portrait and landscape and on phones and tablets.
class AppSizing {
  const AppSizing._();

  /// Widest the play area is allowed to get on a tablet.
  static const double maxPlayBandWidth = 900;

  /// How many answer bubbles fit comfortably on this width.
  static int bubbleCountFor(double width) {
    if (width < 360) return 3;
    if (width < 420) return 4;
    if (width < 600) return 5;
    return 6;
  }

  /// Size of the hero color word.
  static double heroTextSize(double width) {
    if (width < 360) return 44;
    if (width < 420) return 56;
    if (width < 600) return 64;
    return 88;
  }

  /// Boo's diameter, as a share of the shortest side.
  static double booFraction(double width) {
    if (width < 360) return 0.26;
    if (width < 600) return 0.28;
    return 0.22;
  }

  /// Diameter of an answer bubble, given the space available.
  ///
  /// The gaps between the bubbles are taken out of the width before it is
  /// divided up, so however many are on screen they always sit apart from
  /// each other. Two touching bubbles would read as one shape, which is no
  /// use at all in a game about telling colours apart.
  static double bubbleDiameter(double availableWidth, int count) {
    if (count <= 0) return 88;

    final double gaps = AppSpacing.minBubbleGap * (count + 1);
    final double raw = (availableWidth - gaps) / count;

    return raw.clamp(56.0, 190.0);
  }

  /// True when the layout should use the roomier tablet arrangement.
  static bool isTablet(double width) => width >= 600;
}

/// Builds the single ThemeData used by the whole app.
class AppTheme {
  // This class only holds the theme builder, so it is never created.
  const AppTheme._();

  /// The font bundled in `assets/fonts/`.
  ///
  /// Left null until the font file is added, so the app falls back to the
  /// system font instead of failing to build.
  static const String? fontFamily = null;

  /// Coloriboo's warm, papery theme.
  static ThemeData light() {
    // Start from Boo Blue, then force the exact brand colors so they are not
    // shifted by Material's automatic color generation.
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.booBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.booBlue,
          onPrimary: AppColors.white,
          secondary: AppColors.bubblePurple,
          onSecondary: AppColors.white,
          surface: AppColors.paperCream,
          onSurface: AppColors.darkInk,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperCream,

      // Dark Ink for normal text, Soft Ink for quieter supporting text.
      textTheme: ThemeData.light().textTheme
          .apply(bodyColor: AppColors.darkInk, displayColor: AppColors.darkInk)
          .copyWith(
            bodySmall: const TextStyle(color: AppColors.softInk),
            labelSmall: const TextStyle(color: AppColors.softInk),
          ),
    );
  }

  /// The big color word a child is looking for.
  static TextStyle heroWord(double width) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: AppSizing.heroTextSize(width),
      fontWeight: FontWeight.w800,
      color: AppColors.darkInk,
      letterSpacing: 1.5,
      height: 1.1,
    );
  }

  /// What Boo is saying, written down.
  static const TextStyle booLine = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.softInk,
    height: 1.3,
  );

  /// Quiet supporting label.
  static const TextStyle microLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.softInk,
  );

  /// Label on a parent-facing control.
  static const TextStyle settingLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkInk,
  );
}
