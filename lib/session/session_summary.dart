import 'package:flutter/foundation.dart';

import '../colors/color_library.dart';

/// Honest, in-memory memories from one visit to Boo's garden.
///
/// Nothing here is a score or a target. The app-flow owner creates a fresh
/// instance for Play Again and may record only the events it can verify.
@immutable
class SessionSummary {
  const SessionSummary({
    this.activitiesCompleted = 0,
    this.successfulInteractions = 0,
    this.shadesDiscovered = 0,
    this.colorsExplored = const <ColorEntry>[],
  }) : assert(activitiesCompleted >= 0),
       assert(successfulInteractions >= 0),
       assert(shadesDiscovered >= 0);

  static const SessionSummary empty = SessionSummary();

  /// Completed activity rounds, rather than unique activity types.
  final int activitiesCompleted;

  /// Successful child-led interactions recorded by the play session.
  final int successfulInteractions;

  /// Shade steps truthfully encountered in Light to Dark.
  final int shadesDiscovered;

  /// Colors encountered this session. Duplicate entries are allowed at the
  /// recording boundary and are de-duplicated for the end-screen memory.
  final List<ColorEntry> colorsExplored;

  List<ColorEntry> get uniqueColorsExplored {
    final Set<String> seen = <String>{};
    return List<ColorEntry>.unmodifiable(
      colorsExplored.where((ColorEntry entry) => seen.add(entry.name)),
    );
  }

  int get uniqueColorCount => uniqueColorsExplored.length;

  /// End-screen wording for [uniqueColorCount].
  int get colorsExploredCount => uniqueColorCount;

  /// End-screen wording for [activitiesCompleted].
  int get activitiesPlayed => activitiesCompleted;

  int get extendedColorCount => uniqueColorsExplored
      .where((ColorEntry entry) => entry.tier == ColorTier.extended)
      .length;

  SessionSummary copyWith({
    int? activitiesCompleted,
    int? successfulInteractions,
    int? shadesDiscovered,
    List<ColorEntry>? colorsExplored,
  }) {
    return SessionSummary(
      activitiesCompleted: activitiesCompleted ?? this.activitiesCompleted,
      successfulInteractions:
          successfulInteractions ?? this.successfulInteractions,
      shadesDiscovered: shadesDiscovered ?? this.shadesDiscovered,
      colorsExplored: colorsExplored ?? this.colorsExplored,
    );
  }
}
