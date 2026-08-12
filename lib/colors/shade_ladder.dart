import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'color_library.dart';

/// One place on a light-to-dark ladder.
///
/// [rank] is stable even while the child moves the shade around: zero is the
/// lightest shade and the largest rank is the darkest. Keeping a stable id
/// makes swaps, semantics and tests independent of tiny colour conversions.
@immutable
class ShadeTile {
  const ShadeTile({
    required this.rank,
    required this.color,
    required this.lightness,
    required this.semitone,
  });

  final int rank;
  final Color color;
  final double lightness;

  /// A pentatonic note that rises with brightness.
  ///
  /// This gives children who cannot distinguish every shade by sight a
  /// second, consistent clue without turning the activity into a reading
  /// exercise.
  final int semitone;

  @override
  bool operator ==(Object other) {
    return other is ShadeTile &&
        other.rank == rank &&
        other.color == color &&
        other.lightness == lightness &&
        other.semitone == semitone;
  }

  @override
  int get hashCode => Object.hash(rank, color, lightness, semitone);
}

/// An immutable light-to-dark puzzle.
@immutable
class ShadeRound {
  ShadeRound({
    required this.base,
    required List<ShadeTile> correctOrder,
    required List<ShadeTile> order,
    this.moveCount = 0,
  }) : correctOrder = List<ShadeTile>.unmodifiable(correctOrder),
       order = List<ShadeTile>.unmodifiable(order) {
    if (this.correctOrder.length < 3) {
      throw ArgumentError.value(
        this.correctOrder.length,
        'correctOrder',
        'A shade round needs at least three shades.',
      );
    }
    if (this.correctOrder.length != this.order.length) {
      throw ArgumentError('The answer and play order must be the same size.');
    }
    if (moveCount < 0) {
      throw ArgumentError.value(moveCount, 'moveCount', 'Cannot be negative.');
    }

    final Set<int> answerRanks = this.correctOrder
        .map((ShadeTile tile) => tile.rank)
        .toSet();
    final Set<int> playRanks = this.order
        .map((ShadeTile tile) => tile.rank)
        .toSet();
    if (answerRanks.length != this.correctOrder.length ||
        playRanks.length != this.order.length ||
        !setEquals(answerRanks, playRanks)) {
      throw ArgumentError(
        'The play order must contain every answer shade exactly once.',
      );
    }
    if (!setEquals(this.correctOrder.toSet(), this.order.toSet())) {
      throw ArgumentError(
        'The play order contains a shade that is not in the answer.',
      );
    }

    for (int i = 1; i < this.correctOrder.length; i++) {
      if (this.correctOrder[i - 1].lightness <=
          this.correctOrder[i].lightness) {
        throw ArgumentError('The answer must run strictly light to dark.');
      }
    }
  }

  final ColorEntry base;
  final List<ShadeTile> correctOrder;
  final List<ShadeTile> order;
  final int moveCount;

  bool get isComplete => listEquals(order, correctOrder);

  int get correctPositionCount {
    int count = 0;
    for (int i = 0; i < order.length; i++) {
      if (order[i] == correctOrder[i]) count++;
    }
    return count;
  }

  /// The first place Boo can gently help with, or null when solved.
  int? get firstIncorrectIndex {
    for (int i = 0; i < order.length; i++) {
      if (order[i] != correctOrder[i]) return i;
    }
    return null;
  }

  /// Where the shade needed at [targetIndex] currently sits.
  int currentIndexForTarget(int targetIndex) {
    RangeError.checkValidIndex(targetIndex, correctOrder, 'targetIndex');
    return order.indexOf(correctOrder[targetIndex]);
  }

  /// Returns a new round after exchanging two positions.
  ///
  /// Swapping a position with itself is treated as a cancelled gesture and
  /// does not count as a move.
  ShadeRound swap(int first, int second) {
    RangeError.checkValidIndex(first, order, 'first');
    RangeError.checkValidIndex(second, order, 'second');
    if (first == second) return this;

    final List<ShadeTile> next = List<ShadeTile>.of(order);
    final ShadeTile held = next[first];
    next[first] = next[second];
    next[second] = held;

    return ShadeRound(
      base: base,
      correctOrder: correctOrder,
      order: next,
      moveCount: moveCount + 1,
    );
  }
}

/// Builds clear, evenly spaced shade-ordering rounds.
class ShadeLadder {
  const ShadeLadder._();

  static const int defaultShadeCount = 4;

  /// Neutral black and white do not have a hue to keep constant, so this
  /// activity draws from the chromatic colours Boo already teaches.
  static List<ColorEntry> get eligibleBases => List<ColorEntry>.unmodifiable(
    ColorLibrary.core.where((ColorEntry entry) => entry.hue >= 0),
  );

  static ShadeRound buildRound({
    Random? random,
    ColorEntry? base,
    int shadeCount = defaultShadeCount,
  }) {
    if (shadeCount < 3 || shadeCount > 6) {
      throw RangeError.range(shadeCount, 3, 6, 'shadeCount');
    }

    final Random source = random ?? Random();
    final List<ColorEntry> bases = eligibleBases;
    final ColorEntry chosen = base ?? bases[source.nextInt(bases.length)];
    if (chosen.hue < 0) {
      throw ArgumentError.value(
        chosen.name,
        'base',
        'Light-to-dark rounds need a colour with a hue.',
      );
    }

    final List<ShadeTile> answer = shadesFor(chosen, count: shadeCount);
    final List<ShadeTile> shuffled = List<ShadeTile>.of(answer)
      ..shuffle(source);

    // A generated round should always invite an action. Random.shuffle can
    // occasionally return the original sequence, so rotate it in that case.
    if (listEquals(shuffled, answer)) {
      final ShadeTile first = shuffled.removeAt(0);
      shuffled.add(first);
    }

    return ShadeRound(base: chosen, correctOrder: answer, order: shuffled);
  }

  /// Makes shades with a constant hue and saturation and evenly stepped
  /// lightness. The fixed endpoints stay well away from pure white and black,
  /// so every bubble still reads as the base colour.
  static List<ShadeTile> shadesFor(
    ColorEntry base, {
    int count = defaultShadeCount,
  }) {
    if (count < 3 || count > 6) {
      throw RangeError.range(count, 3, 6, 'count');
    }
    if (base.hue < 0) {
      throw ArgumentError.value(
        base.name,
        'base',
        'A shade ladder needs a chromatic base colour.',
      );
    }

    final HSLColor source = HSLColor.fromColor(base.color);
    final double saturation = max(source.saturation, 0.58);
    const List<int> brightToDarkNotes = <int>[
      21,
      19,
      16,
      14,
      12,
      9,
      7,
      4,
      2,
      0,
    ];

    return List<ShadeTile>.unmodifiable(
      List<ShadeTile>.generate(count, (int index) {
        final double progress = index / (count - 1);
        final double lightness = 0.80 - (progress * 0.48);
        final int noteIndex = (progress * (brightToDarkNotes.length - 1))
            .round();
        return ShadeTile(
          rank: index,
          color: source
              .withSaturation(saturation)
              .withLightness(lightness)
              .toColor(),
          lightness: lightness,
          semitone: brightToDarkNotes[noteIndex],
        );
      }),
    );
  }
}
