// Tests for the colour rules behind every round.
//
// This is the part the old app got wrong, so it is tested before any of the
// screens exist.

import 'dart:math';

import 'package:colorsquest/colors/color_library.dart';
import 'package:colorsquest/colors/color_mixes.dart';
import 'package:colorsquest/colors/color_picker_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('colour library', () {
    test('has ten core colours and a good spread of extras', () {
      expect(ColorLibrary.core.length, 10);
      expect(ColorLibrary.extended.length, greaterThanOrEqualTo(40));
      expect(ColorLibrary.all.length, greaterThanOrEqualTo(50));
    });

    test('every colour has a name, a tier and a pentatonic note', () {
      // Notes come from a major pentatonic scale so any run of taps sounds
      // pleasant in any order.
      const Set<int> pentatonic = <int>{0, 2, 4, 7, 9, 12, 14, 16, 19, 21};

      for (final ColorEntry entry in ColorLibrary.all) {
        expect(entry.name.trim(), isNotEmpty);
        expect(
          pentatonic.contains(entry.semitone),
          isTrue,
          reason: '${entry.name} has a note outside the pentatonic scale',
        );
      }
    });

    test('no two colours share a name', () {
      final Set<String> names = ColorLibrary.all
          .map((ColorEntry c) => c.name)
          .toSet();
      expect(names.length, ColorLibrary.all.length);
    });

    test('the ten core colours all sound different from each other', () {
      // The note is one of the three ways a colour identifies itself, so the
      // taught colours must not collide.
      final Set<int> notes = ColorLibrary.core
          .map((ColorEntry c) => c.semitone)
          .toSet();
      expect(notes.length, ColorLibrary.core.length);
    });

    test('lookup by name is case insensitive and handles misses', () {
      expect(ColorLibrary.byName('red')?.name, 'Red');
      expect(ColorLibrary.byName('SKY BLUE')?.name, 'Sky Blue');
      expect(ColorLibrary.byName('not a colour'), isNull);
    });
  });

  group('perceptual distance', () {
    test('a colour is identical to itself', () {
      expect(colorDistance(0xFFE4322B, 0xFFE4322B), 0);
    });

    test('black and white are the furthest apart', () {
      final double blackWhite = colorDistance(0xFF000000, 0xFFFFFFFF);
      expect(blackWhite, greaterThan(700));
    });

    test('two blues are closer than blue and yellow', () {
      final ColorEntry blue = ColorLibrary.byName('Blue')!;
      final ColorEntry navy = ColorLibrary.byName('Navy')!;
      final ColorEntry yellow = ColorLibrary.byName('Yellow')!;

      expect(
        distanceBetween(blue, navy),
        lessThan(distanceBetween(blue, yellow)),
      );
    });

    test('order does not matter', () {
      expect(
        colorDistance(0xFF2F7FE4, 0xFFFFCE2B),
        closeTo(colorDistance(0xFFFFCE2B, 0xFF2F7FE4), 0.0001),
      );
    });
  });

  group('building rounds', () {
    test('the target is always one of the taught colours', () {
      final ColorPicker picker = ColorPicker(random: Random(1));

      for (final DifficultyStep step in difficultyLadder) {
        for (int i = 0; i < 50; i++) {
          expect(picker.buildRound(step).target.isCore, isTrue);
        }
      }
    });

    test('the options always contain the target exactly once', () {
      final ColorPicker picker = ColorPicker(random: Random(2));

      for (final DifficultyStep step in difficultyLadder) {
        for (int i = 0; i < 50; i++) {
          final ColorRound round = picker.buildRound(step);
          final int matches = round.options
              .where((ColorEntry c) => c.name == round.target.name)
              .length;
          expect(matches, 1);
        }
      }
    });

    test('the right number of bubbles appear', () {
      final ColorPicker picker = ColorPicker(random: Random(3));

      for (final DifficultyStep step in difficultyLadder) {
        for (int i = 0; i < 30; i++) {
          expect(picker.buildRound(step).options.length, step.optionCount);
        }
      }
    });

    test('the same colour is never asked for twice in a row', () {
      final ColorPicker picker = ColorPicker(random: Random(4));
      String? previous;

      for (int i = 0; i < 300; i++) {
        final ColorRound round = picker.buildRound(difficultyLadder[2]);
        expect(round.target.name, isNot(previous));
        previous = round.target.name;
      }
    });

    test('bubbles on screen are always far enough apart to tell apart', () {
      // The whole point of the distance rule: a child must never be shown two
      // colours they cannot distinguish.
      final ColorPicker picker = ColorPicker(random: Random(5));

      for (int level = 0; level < difficultyLadder.length; level++) {
        final DifficultyStep step = difficultyLadder[level];

        for (int i = 0; i < 200; i++) {
          final ColorRound round = picker.buildRound(step);

          for (int a = 0; a < round.options.length; a++) {
            for (int b = a + 1; b < round.options.length; b++) {
              expect(
                distanceBetween(round.options[a], round.options[b]),
                greaterThan(60),
                reason:
                    'level ${level + 1} put ${round.options[a].name} next to '
                    '${round.options[b].name}',
              );
            }
          }
        }
      }
    });

    test('easy levels only use the taught colours', () {
      final ColorPicker picker = ColorPicker(random: Random(6));

      for (int level = 0; level < 4; level++) {
        for (int i = 0; i < 50; i++) {
          final ColorRound round = picker.buildRound(difficultyLadder[level]);
          for (final ColorEntry option in round.options) {
            expect(option.isCore, isTrue);
          }
        }
      }
    });

    test('odd one out gives one different bubble among matching ones', () {
      final ColorPicker picker = ColorPicker(random: Random(7));

      for (final DifficultyStep step in difficultyLadder) {
        for (int i = 0; i < 50; i++) {
          final round = picker.buildOddOneOutRound(step);

          expect(round.common.name, isNot(round.odd.name));
          expect(round.total, greaterThanOrEqualTo(3));
          expect(round.total, lessThanOrEqualTo(6));
          expect(distanceBetween(round.common, round.odd), greaterThan(60));
        }
      }
    });
  });

  group('difficulty', () {
    test('starts in the middle of the easy range', () {
      expect(DifficultyTracker().level, 2);
    });

    test('rises after three correct in a row', () {
      final DifficultyTracker tracker = DifficultyTracker(startLevel: 1);

      tracker.recordCorrect();
      tracker.recordCorrect();
      expect(tracker.level, 1);

      tracker.recordCorrect();
      expect(tracker.level, 2);
    });

    test('drops back immediately on a miss', () {
      final DifficultyTracker tracker = DifficultyTracker(startLevel: 4);
      tracker.recordMiss();
      expect(tracker.level, 3);
    });

    test('a miss also resets progress towards the next level', () {
      final DifficultyTracker tracker = DifficultyTracker(startLevel: 2);

      tracker.recordCorrect();
      tracker.recordCorrect();
      tracker.recordMiss(); // back to level 1, streak cleared
      tracker.recordCorrect();
      tracker.recordCorrect();

      expect(tracker.level, 1);
    });

    test('never goes below one or above five', () {
      final DifficultyTracker low = DifficultyTracker(startLevel: 1);
      for (int i = 0; i < 10; i++) {
        low.recordMiss();
      }
      expect(low.level, 1);

      final DifficultyTracker high = DifficultyTracker(startLevel: 5);
      for (int i = 0; i < 30; i++) {
        high.recordCorrect();
      }
      expect(high.level, 5);
    });
  });

  group('colour mixing', () {
    test('every offered mix has a result that exists in the library', () {
      for (final ColorMix mix in ColorMixes.all) {
        expect(
          ColorLibrary.byName(mix.firstName),
          isNotNull,
          reason: '${mix.firstName} is not in the library',
        );
        expect(
          ColorLibrary.byName(mix.secondName),
          isNotNull,
          reason: '${mix.secondName} is not in the library',
        );
        expect(
          ColorLibrary.byName(mix.resultName),
          isNotNull,
          reason: '${mix.resultName} is not in the library',
        );
      }
    });

    test('the three classic mixes are right', () {
      expect(ColorMixes.resultFor('Red', 'Yellow')?.name, 'Orange');
      expect(ColorMixes.resultFor('Yellow', 'Blue')?.name, 'Green');
      expect(ColorMixes.resultFor('Blue', 'Red')?.name, 'Purple');
    });

    test('order does not matter', () {
      expect(
        ColorMixes.resultFor('Blue', 'Yellow')?.name,
        ColorMixes.resultFor('Yellow', 'Blue')?.name,
      );
    });

    test('a pair that is not offered returns nothing', () {
      expect(ColorMixes.resultFor('Pink', 'Brown'), isNull);
    });

    test('every random mix can be resolved', () {
      final Random random = Random(8);
      for (int i = 0; i < 100; i++) {
        final ColorMix mix = ColorMixes.randomMix(random);
        expect(ColorMixes.resultFor(mix.firstName, mix.secondName), isNotNull);
      }
    });
  });
}
