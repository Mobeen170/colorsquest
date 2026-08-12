import 'dart:math';

import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/colors/shade_ladder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shade generation', () {
    test('only chromatic taught colours are eligible', () {
      expect(ShadeLadder.eligibleBases, isNotEmpty);
      for (final ColorEntry base in ShadeLadder.eligibleBases) {
        expect(base.isCore, isTrue);
        expect(base.hue, greaterThanOrEqualTo(0));
      }

      final Iterable<String> names = ShadeLadder.eligibleBases.map(
        (ColorEntry color) => color.name,
      );
      expect(names, isNot(contains('Black')));
      expect(names, isNot(contains('White')));
    });

    test('shades are evenly ordered and keep the base hue', () {
      final ColorEntry blue = ColorLibrary.byName('Blue')!;
      final List<ShadeTile> shades = ShadeLadder.shadesFor(blue);
      final double baseHue = HSLColor.fromColor(blue.color).hue;

      expect(shades, hasLength(4));
      for (int index = 0; index < shades.length; index++) {
        expect(shades[index].rank, index);
        expect(
          HSLColor.fromColor(shades[index].color).hue,
          closeTo(baseHue, 0.6),
        );
        if (index > 0) {
          expect(
            shades[index - 1].lightness,
            greaterThan(shades[index].lightness),
          );
          expect(
            shades[index - 1].lightness - shades[index].lightness,
            closeTo(0.16, 0.0001),
          );
          expect(
            shades[index - 1].color.computeLuminance(),
            greaterThan(shades[index].color.computeLuminance()),
          );
          expect(
            shades[index - 1].semitone,
            greaterThan(shades[index].semitone),
          );
        }
      }
    });

    test('generated puzzles are shuffled but preserve every shade', () {
      for (int seed = 0; seed < 100; seed++) {
        final ShadeRound round = ShadeLadder.buildRound(random: Random(seed));

        expect(round.isComplete, isFalse);
        expect(
          round.order.map((ShadeTile tile) => tile.rank).toSet(),
          round.correctOrder.map((ShadeTile tile) => tile.rank).toSet(),
        );
      }
    });

    test('supports three to six shades and rejects unsafe sizes', () {
      final ColorEntry red = ColorLibrary.byName('Red')!;

      for (int count = 3; count <= 6; count++) {
        expect(
          ShadeLadder.buildRound(
            random: Random(count),
            base: red,
            shadeCount: count,
          ).order,
          hasLength(count),
        );
      }

      expect(
        () => ShadeLadder.buildRound(base: red, shadeCount: 2),
        throwsRangeError,
      );
      expect(
        () => ShadeLadder.buildRound(base: red, shadeCount: 7),
        throwsRangeError,
      );
      expect(
        () => ShadeLadder.buildRound(base: ColorLibrary.byName('White')!),
        throwsArgumentError,
      );
    });
  });

  group('shade round', () {
    test('swaps immutably and counts real moves', () {
      final ColorEntry green = ColorLibrary.byName('Green')!;
      final List<ShadeTile> answer = ShadeLadder.shadesFor(green);
      final ShadeRound round = ShadeRound(
        base: green,
        correctOrder: answer,
        order: answer.reversed.toList(),
      );

      final ShadeRound afterOne = round.swap(0, 3);
      final ShadeRound solved = afterOne.swap(1, 2);

      expect(round.moveCount, 0);
      expect(round.order.first.rank, 3);
      expect(afterOne.moveCount, 1);
      expect(afterOne.order.first.rank, 0);
      expect(solved.moveCount, 2);
      expect(solved.isComplete, isTrue);
      expect(solved.correctPositionCount, answer.length);
    });

    test('selecting the same place is a cancelled move', () {
      final ShadeRound round = ShadeLadder.buildRound(random: Random(40));

      expect(identical(round.swap(1, 1), round), isTrue);
      expect(round.moveCount, 0);
    });

    test('finds the source of the next helpful shade', () {
      final ColorEntry purple = ColorLibrary.byName('Purple')!;
      final List<ShadeTile> answer = ShadeLadder.shadesFor(purple);
      final ShadeRound round = ShadeRound(
        base: purple,
        correctOrder: answer,
        order: <ShadeTile>[answer[2], answer[1], answer[0], answer[3]],
      );

      expect(round.firstIncorrectIndex, 0);
      expect(round.currentIndexForTarget(0), 2);
      expect(round.correctPositionCount, 2);
    });

    test('orders are read-only and invalid puzzles are rejected', () {
      final ColorEntry pink = ColorLibrary.byName('Pink')!;
      final List<ShadeTile> answer = ShadeLadder.shadesFor(pink);
      final ShadeRound round = ShadeRound(
        base: pink,
        correctOrder: answer,
        order: answer.reversed.toList(),
      );

      expect(() => round.order.add(answer.first), throwsUnsupportedError);
      expect(() => round.swap(-1, 1), throwsRangeError);
      expect(() => round.swap(0, answer.length), throwsRangeError);
      expect(
        () => ShadeRound(
          base: pink,
          correctOrder: answer,
          order: <ShadeTile>[answer.first, answer.first, answer[2], answer[3]],
        ),
        throwsArgumentError,
      );
    });
  });
}
