import 'dart:math';

import 'color_library.dart';

/// A pair of colors that make something worth learning.
class ColorMix {
  const ColorMix({
    required this.firstName,
    required this.secondName,
    required this.resultName,
  });

  final String firstName;
  final String secondName;
  final String resultName;
}

/// What happens when two bubbles merge.
///
/// These results are written down on purpose rather than calculated. Averaging
/// two colors mathematically gives muddy browns for most pairs, which would
/// teach a child the wrong thing: mixing blue and yellow has to give a clean
/// green, the way paint does.
///
/// The mixing lab only ever offers pairs listed here, so every merge a child
/// performs produces a result Boo can name and be pleased about.
class ColorMixes {
  const ColorMixes._();

  static const List<ColorMix> all = <ColorMix>[
    // The classic three every child should meet first.
    ColorMix(firstName: 'Red', secondName: 'Yellow', resultName: 'Orange'),
    ColorMix(firstName: 'Yellow', secondName: 'Blue', resultName: 'Green'),
    ColorMix(firstName: 'Blue', secondName: 'Red', resultName: 'Purple'),

    // Making a color lighter.
    ColorMix(firstName: 'Red', secondName: 'White', resultName: 'Pink'),
    ColorMix(firstName: 'Blue', secondName: 'White', resultName: 'Sky Blue'),
    ColorMix(firstName: 'Green', secondName: 'White', resultName: 'Mint'),
    ColorMix(firstName: 'Purple', secondName: 'White', resultName: 'Lavender'),
    ColorMix(firstName: 'Pink', secondName: 'White', resultName: 'Blush'),
    ColorMix(firstName: 'Yellow', secondName: 'White', resultName: 'Cream'),
    ColorMix(firstName: 'Brown', secondName: 'White', resultName: 'Tan'),

    // Making a color darker.
    ColorMix(firstName: 'Black', secondName: 'White', resultName: 'Grey'),
    ColorMix(firstName: 'Red', secondName: 'Black', resultName: 'Maroon'),
    ColorMix(firstName: 'Blue', secondName: 'Black', resultName: 'Navy'),

    // In-between colors.
    ColorMix(firstName: 'Yellow', secondName: 'Green', resultName: 'Lime'),
    ColorMix(firstName: 'Green', secondName: 'Blue', resultName: 'Teal'),
    ColorMix(firstName: 'Orange', secondName: 'Yellow', resultName: 'Amber'),
    ColorMix(firstName: 'Orange', secondName: 'Red', resultName: 'Scarlet'),
    ColorMix(firstName: 'Purple', secondName: 'Pink', resultName: 'Magenta'),
    ColorMix(firstName: 'Red', secondName: 'Green', resultName: 'Brown'),
    ColorMix(firstName: 'Orange', secondName: 'Brown', resultName: 'Copper'),
  ];

  /// Finds the result of merging two colors, whichever order they are given
  /// in. Returns null when the pair is not one the lab offers.
  static ColorEntry? resultFor(String a, String b) {
    for (final ColorMix mix in all) {
      final bool forwards = mix.firstName == a && mix.secondName == b;
      final bool backwards = mix.firstName == b && mix.secondName == a;
      if (forwards || backwards) return ColorLibrary.byName(mix.resultName);
    }
    return null;
  }

  /// Picks a mix for the child to try.
  static ColorMix randomMix(Random random) => all[random.nextInt(all.length)];
}
