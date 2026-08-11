import 'package:flutter/material.dart';

/// How a color is used in the game.
enum ColorTier {
  /// Boo teaches and tests these. Ten colors a young child should learn.
  core,

  /// Boo names these when they turn up, but never asks a child to find one.
  ///
  /// They exist so the world feels endlessly varied without ever asking a
  /// four year old to tell teal from turquoise.
  extended,
}

/// One color Boo knows about.
@immutable
class ColorEntry {
  const ColorEntry({
    required this.name,
    required this.color,
    required this.tier,
    required this.hue,
    required this.semitone,
  });

  /// Spoken and written name, e.g. "Red".
  final String name;

  final Color color;

  final ColorTier tier;

  /// Position on the color wheel, 0-360. Neutrals use -1.
  final double hue;

  /// Which note this color plays, in semitones above the base note.
  ///
  /// Every value comes from a major pentatonic scale, so any run of taps
  /// sounds pleasant no matter what order a child pops them in.
  ///
  /// Pitch rises with lightness: black is the lowest note, white the highest.
  /// This is the third way a color identifies itself, alongside its spoken
  /// name and its written word, so a color-blind child can still tell two
  /// bubbles apart.
  final int semitone;

  bool get isCore => tier == ColorTier.core;
}

/// Every color in Coloriboo.
///
/// This file is deliberately just data. The rules for choosing which colors
/// appear on screen live in `color_picker_logic.dart`.
class ColorLibrary {
  const ColorLibrary._();

  /// The ten colors Boo actually teaches.
  static const List<ColorEntry> core = <ColorEntry>[
    ColorEntry(
      name: 'Black',
      color: Color(0xFF2B2B33),
      tier: ColorTier.core,
      hue: -1,
      semitone: 0,
    ),
    ColorEntry(
      name: 'Brown',
      color: Color(0xFF8B5E3C),
      tier: ColorTier.core,
      hue: 25,
      semitone: 2,
    ),
    ColorEntry(
      name: 'Red',
      color: Color(0xFFE4322B),
      tier: ColorTier.core,
      hue: 2,
      semitone: 4,
    ),
    ColorEntry(
      name: 'Orange',
      color: Color(0xFFF5822B),
      tier: ColorTier.core,
      hue: 28,
      semitone: 7,
    ),
    ColorEntry(
      name: 'Yellow',
      color: Color(0xFFFFCE2B),
      tier: ColorTier.core,
      hue: 47,
      semitone: 9,
    ),
    ColorEntry(
      name: 'Green',
      color: Color(0xFF3FBF56),
      tier: ColorTier.core,
      hue: 131,
      semitone: 12,
    ),
    ColorEntry(
      name: 'Blue',
      color: Color(0xFF2F7FE4),
      tier: ColorTier.core,
      hue: 213,
      semitone: 14,
    ),
    ColorEntry(
      name: 'Purple',
      color: Color(0xFF8B4FD1),
      tier: ColorTier.core,
      hue: 272,
      semitone: 16,
    ),
    ColorEntry(
      name: 'Pink',
      color: Color(0xFFFF6FB5),
      tier: ColorTier.core,
      hue: 330,
      semitone: 19,
    ),
    ColorEntry(
      name: 'White',
      color: Color(0xFFFFFFFF),
      tier: ColorTier.core,
      hue: -1,
      semitone: 21,
    ),
  ];

  /// Colors Boo names as discoveries but never quizzes.
  static const List<ColorEntry> extended = <ColorEntry>[
    // Blues and greens
    ColorEntry(
      name: 'Sky Blue',
      color: Color(0xFF7FC7F5),
      tier: ColorTier.extended,
      hue: 202,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Navy',
      color: Color(0xFF1B2A5E),
      tier: ColorTier.extended,
      hue: 226,
      semitone: 2,
    ),
    ColorEntry(
      name: 'Cyan',
      color: Color(0xFF22C8E8),
      tier: ColorTier.extended,
      hue: 189,
      semitone: 16,
    ),
    ColorEntry(
      name: 'Teal',
      color: Color(0xFF12897F),
      tier: ColorTier.extended,
      hue: 175,
      semitone: 12,
    ),
    ColorEntry(
      name: 'Turquoise',
      color: Color(0xFF33C6C0),
      tier: ColorTier.extended,
      hue: 177,
      semitone: 14,
    ),
    ColorEntry(
      name: 'Aqua',
      color: Color(0xFF6FE0DE),
      tier: ColorTier.extended,
      hue: 179,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Mint',
      color: Color(0xFF8CE3B8),
      tier: ColorTier.extended,
      hue: 152,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Emerald',
      color: Color(0xFF189E63),
      tier: ColorTier.extended,
      hue: 154,
      semitone: 12,
    ),
    ColorEntry(
      name: 'Forest',
      color: Color(0xFF1E5E32),
      tier: ColorTier.extended,
      hue: 143,
      semitone: 4,
    ),
    ColorEntry(
      name: 'Sage',
      color: Color(0xFFA2B58C),
      tier: ColorTier.extended,
      hue: 90,
      semitone: 16,
    ),
    ColorEntry(
      name: 'Lime',
      color: Color(0xFF9CD62B),
      tier: ColorTier.extended,
      hue: 76,
      semitone: 14,
    ),
    ColorEntry(
      name: 'Olive',
      color: Color(0xFF71802F),
      tier: ColorTier.extended,
      hue: 70,
      semitone: 7,
    ),

    // Purples and pinks
    ColorEntry(
      name: 'Indigo',
      color: Color(0xFF4B3FA8),
      tier: ColorTier.extended,
      hue: 247,
      semitone: 7,
    ),
    ColorEntry(
      name: 'Violet',
      color: Color(0xFF7B3FD4),
      tier: ColorTier.extended,
      hue: 264,
      semitone: 14,
    ),
    ColorEntry(
      name: 'Lavender',
      color: Color(0xFFB9A7EE),
      tier: ColorTier.extended,
      hue: 256,
      semitone: 21,
    ),
    ColorEntry(
      name: 'Lilac',
      color: Color(0xFFC9A6E0),
      tier: ColorTier.extended,
      hue: 279,
      semitone: 21,
    ),
    ColorEntry(
      name: 'Magenta',
      color: Color(0xFFD6379B),
      tier: ColorTier.extended,
      hue: 322,
      semitone: 16,
    ),
    ColorEntry(
      name: 'Plum',
      color: Color(0xFF7A3560),
      tier: ColorTier.extended,
      hue: 320,
      semitone: 4,
    ),
    ColorEntry(
      name: 'Rose',
      color: Color(0xFFE86A87),
      tier: ColorTier.extended,
      hue: 347,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Blush',
      color: Color(0xFFF5B7C0),
      tier: ColorTier.extended,
      hue: 353,
      semitone: 21,
    ),

    // Reds and warms
    ColorEntry(
      name: 'Crimson',
      color: Color(0xFFB01432),
      tier: ColorTier.extended,
      hue: 348,
      semitone: 2,
    ),
    ColorEntry(
      name: 'Scarlet',
      color: Color(0xFFE23A1E),
      tier: ColorTier.extended,
      hue: 9,
      semitone: 7,
    ),
    ColorEntry(
      name: 'Maroon',
      color: Color(0xFF6E1E28),
      tier: ColorTier.extended,
      hue: 349,
      semitone: 0,
    ),
    ColorEntry(
      name: 'Burgundy',
      color: Color(0xFF6B1230),
      tier: ColorTier.extended,
      hue: 337,
      semitone: 0,
    ),
    ColorEntry(
      name: 'Coral',
      color: Color(0xFFFF7F63),
      tier: ColorTier.extended,
      hue: 11,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Salmon',
      color: Color(0xFFFA8C7C),
      tier: ColorTier.extended,
      hue: 8,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Peach',
      color: Color(0xFFFFBE9E),
      tier: ColorTier.extended,
      hue: 20,
      semitone: 21,
    ),
    ColorEntry(
      name: 'Apricot',
      color: Color(0xFFF7A860),
      tier: ColorTier.extended,
      hue: 27,
      semitone: 19,
    ),

    // Golds and yellows
    ColorEntry(
      name: 'Gold',
      color: Color(0xFFE0AE22),
      tier: ColorTier.extended,
      hue: 44,
      semitone: 14,
    ),
    ColorEntry(
      name: 'Amber',
      color: Color(0xFFF5A81C),
      tier: ColorTier.extended,
      hue: 39,
      semitone: 16,
    ),
    ColorEntry(
      name: 'Mustard',
      color: Color(0xFFC9A227),
      tier: ColorTier.extended,
      hue: 46,
      semitone: 12,
    ),

    // Browns and earths
    ColorEntry(
      name: 'Chocolate',
      color: Color(0xFF5C3A21),
      tier: ColorTier.extended,
      hue: 27,
      semitone: 0,
    ),
    ColorEntry(
      name: 'Copper',
      color: Color(0xFFB4642E),
      tier: ColorTier.extended,
      hue: 26,
      semitone: 7,
    ),
    ColorEntry(
      name: 'Bronze',
      color: Color(0xFF96662E),
      tier: ColorTier.extended,
      hue: 33,
      semitone: 4,
    ),
    ColorEntry(
      name: 'Tan',
      color: Color(0xFFC9A16B),
      tier: ColorTier.extended,
      hue: 33,
      semitone: 16,
    ),
    ColorEntry(
      name: 'Beige',
      color: Color(0xFFE3D3B8),
      tier: ColorTier.extended,
      hue: 39,
      semitone: 21,
    ),
    ColorEntry(
      name: 'Cream',
      color: Color(0xFFF7EFD8),
      tier: ColorTier.extended,
      hue: 45,
      semitone: 21,
    ),
    ColorEntry(
      name: 'Ivory',
      color: Color(0xFFFBF6E4),
      tier: ColorTier.extended,
      hue: 48,
      semitone: 21,
    ),

    // Neutrals
    ColorEntry(
      name: 'Silver',
      color: Color(0xFFC2C7CC),
      tier: ColorTier.extended,
      hue: -1,
      semitone: 19,
    ),
    ColorEntry(
      name: 'Grey',
      color: Color(0xFF8A9099),
      tier: ColorTier.extended,
      hue: -1,
      semitone: 14,
    ),
    ColorEntry(
      name: 'Slate',
      color: Color(0xFF5A6B7C),
      tier: ColorTier.extended,
      hue: 209,
      semitone: 7,
    ),
    ColorEntry(
      name: 'Charcoal',
      color: Color(0xFF43484F),
      tier: ColorTier.extended,
      hue: -1,
      semitone: 2,
    ),
  ];

  /// Every color Boo knows, core first.
  static List<ColorEntry> get all => <ColorEntry>[...core, ...extended];

  /// Looks a color up by name. Returns null when there is no such color.
  static ColorEntry? byName(String name) {
    for (final ColorEntry entry in all) {
      if (entry.name.toLowerCase() == name.toLowerCase()) return entry;
    }
    return null;
  }
}
