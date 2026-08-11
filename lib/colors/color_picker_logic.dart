import 'dart:math';

import 'color_library.dart';

/// How far apart two colors look to a human eye.
///
/// This is the "redmean" formula: a cheap, well known approximation that is
/// much closer to human vision than simply comparing red, green and blue.
///
/// It matters because the library holds fifty colors. Picking wrong answers
/// at random would eventually ask a five year old to tell navy from midnight
/// blue, which is impossible and discouraging. Every round is checked so the
/// bubbles on screen are always far enough apart to tell apart.
///
/// The result runs from 0 (identical) to about 765 (black against white).
double colorDistance(int argbA, int argbB) {
  final int r1 = (argbA >> 16) & 0xFF;
  final int g1 = (argbA >> 8) & 0xFF;
  final int b1 = argbA & 0xFF;

  final int r2 = (argbB >> 16) & 0xFF;
  final int g2 = (argbB >> 8) & 0xFF;
  final int b2 = argbB & 0xFF;

  final double meanRed = (r1 + r2) / 2.0;
  final double dr = (r1 - r2).toDouble();
  final double dg = (g1 - g2).toDouble();
  final double db = (b1 - b2).toDouble();

  final double weightRed = 2 + (meanRed / 256.0);
  const double weightGreen = 4;
  final double weightBlue = 2 + ((255 - meanRed) / 256.0);

  return sqrt(
    (weightRed * dr * dr) + (weightGreen * dg * dg) + (weightBlue * db * db),
  );
}

/// Convenience wrapper for two library colors.
double distanceBetween(ColorEntry a, ColorEntry b) =>
    colorDistance(a.color.toARGB32(), b.color.toARGB32());

/// One step on the difficulty ladder.
class DifficultyStep {
  const DifficultyStep({
    required this.optionCount,
    required this.minDistance,
    required this.allowExtendedDistractors,
  });

  /// How many bubbles are on screen.
  final int optionCount;

  /// Closest two bubbles are allowed to look.
  final double minDistance;

  /// Whether colors outside the taught ten may appear as wrong answers.
  final bool allowExtendedDistractors;
}

/// The five levels, easiest first.
///
/// Difficulty only moves within a single sitting and resets when the app is
/// launched again. Nothing is saved, and there is no score.
const List<DifficultyStep> difficultyLadder = <DifficultyStep>[
  DifficultyStep(
    optionCount: 2,
    minDistance: 380,
    allowExtendedDistractors: false,
  ),
  DifficultyStep(
    optionCount: 3,
    minDistance: 300,
    allowExtendedDistractors: false,
  ),
  DifficultyStep(
    optionCount: 4,
    minDistance: 230,
    allowExtendedDistractors: false,
  ),
  DifficultyStep(
    optionCount: 4,
    minDistance: 170,
    allowExtendedDistractors: false,
  ),
  DifficultyStep(
    optionCount: 5,
    minDistance: 130,
    allowExtendedDistractors: true,
  ),
];

/// Keeps track of how well the child is doing right now.
///
/// Rises quietly when they are succeeding, drops back the moment they miss.
/// Nothing is displayed and nothing is stored.
class DifficultyTracker {
  DifficultyTracker({int startLevel = 2}) : _level = startLevel.clamp(1, 5);

  int _level;
  int _streak = 0;

  /// Current level, 1 to 5.
  int get level => _level;

  DifficultyStep get step => difficultyLadder[_level - 1];

  void recordCorrect() {
    _streak++;
    if (_streak >= 3 && _level < 5) {
      _level++;
      _streak = 0;
    }
  }

  void recordMiss() {
    _streak = 0;
    if (_level > 1) _level--;
  }
}

/// One question: the color to find, and the bubbles to choose between.
class ColorRound {
  const ColorRound({required this.target, required this.options});

  final ColorEntry target;

  /// Everything on screen, already shuffled. Always contains [target].
  final List<ColorEntry> options;
}

/// Builds the rounds a child plays.
///
/// This replaces the old `createOptions()`, which always took the first three
/// non-answer colors in list order, so the same wrong options came up every
/// single time.
class ColorPicker {
  ColorPicker({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// The last couple of targets, so the same color is not asked for twice
  /// in a row.
  final List<String> _recentTargets = <String>[];

  static const int _recentMemory = 2;

  /// Builds a normal "find this color" round.
  ColorRound buildRound(DifficultyStep step) {
    final ColorEntry target = _pickTarget();

    final List<ColorEntry> pool = <ColorEntry>[
      ...ColorLibrary.core,
      if (step.allowExtendedDistractors) ...ColorLibrary.extended,
    ]..removeWhere((ColorEntry c) => c.name == target.name);

    final List<ColorEntry> chosen = _pickSpacedColors(
      pool: pool,
      alreadyChosen: <ColorEntry>[target],
      wanted: step.optionCount - 1,
      minDistance: step.minDistance,
    );

    final List<ColorEntry> options = <ColorEntry>[target, ...chosen]
      ..shuffle(_random);

    return ColorRound(target: target, options: options);
  }

  /// Builds an "odd one out" round: several of one color, one of another.
  ///
  /// Returns the common color first and the odd color second.
  ({ColorEntry common, ColorEntry odd, int total}) buildOddOneOutRound(
    DifficultyStep step,
  ) {
    final ColorEntry common = _pickTarget();

    final List<ColorEntry> pool = <ColorEntry>[
      ...ColorLibrary.core,
      if (step.allowExtendedDistractors) ...ColorLibrary.extended,
    ]..removeWhere((ColorEntry c) => c.name == common.name);

    final List<ColorEntry> odd = _pickSpacedColors(
      pool: pool,
      alreadyChosen: <ColorEntry>[common],
      wanted: 1,
      minDistance: step.minDistance,
    );

    // One extra bubble than a normal round, since they are mostly identical
    // and therefore easier to scan.
    final int total = (step.optionCount + 1).clamp(3, 6);

    return (common: common, odd: odd.first, total: total);
  }

  /// Picks the color a child is asked to find.
  ///
  /// Always one of the taught ten, and never the same as the last one.
  ColorEntry _pickTarget() {
    final List<ColorEntry> candidates = ColorLibrary.core
        .where((ColorEntry c) => !_recentTargets.contains(c.name))
        .toList();

    final List<ColorEntry> from = candidates.isEmpty
        ? ColorLibrary.core
        : candidates;

    final ColorEntry target = from[_random.nextInt(from.length)];

    _recentTargets.add(target.name);
    while (_recentTargets.length > _recentMemory) {
      _recentTargets.removeAt(0);
    }

    return target;
  }

  /// Chooses [wanted] colors from [pool] that stay far enough away from
  /// [alreadyChosen] and from each other.
  ///
  /// If the requested spacing turns out to be impossible, the requirement is
  /// eased a little at a time rather than failing. A slightly easier round is
  /// always better than a crash or an empty screen.
  List<ColorEntry> _pickSpacedColors({
    required List<ColorEntry> pool,
    required List<ColorEntry> alreadyChosen,
    required int wanted,
    required double minDistance,
  }) {
    if (wanted <= 0) return <ColorEntry>[];

    double required = minDistance;

    for (int attempt = 0; attempt < 8; attempt++) {
      final List<ColorEntry> picked = <ColorEntry>[];
      final List<ColorEntry> shuffled = List<ColorEntry>.of(pool)
        ..shuffle(_random);

      for (final ColorEntry candidate in shuffled) {
        if (picked.length == wanted) break;

        final bool farEnough = <ColorEntry>[...alreadyChosen, ...picked].every(
          (ColorEntry other) => distanceBetween(candidate, other) >= required,
        );

        if (farEnough) picked.add(candidate);
      }

      if (picked.length == wanted) return picked;

      // Too strict for this palette. Loosen and try again.
      required *= 0.85;
    }

    // Last resort: take whichever colors sit furthest from what is already
    // on screen. This keeps the round playable in every case.
    final List<ColorEntry> byDistance = List<ColorEntry>.of(pool)
      ..sort((ColorEntry a, ColorEntry b) {
        final double da = _nearestDistance(a, alreadyChosen);
        final double db = _nearestDistance(b, alreadyChosen);
        return db.compareTo(da);
      });

    return byDistance.take(wanted).toList();
  }

  double _nearestDistance(ColorEntry candidate, List<ColorEntry> others) {
    double nearest = double.infinity;
    for (final ColorEntry other in others) {
      final double d = distanceBetween(candidate, other);
      if (d < nearest) nearest = d;
    }
    return nearest;
  }
}
