import 'package:flutter/widgets.dart';

/// The handful of things a parent can turn on and off.
///
/// These live in memory only. They reset when the app is launched again,
/// which keeps the app free of any storage, any saved state and any need for
/// an extra package.
class Settings extends ChangeNotifier {
  bool _music = true;
  bool _soundEffects = true;
  bool _voice = true;
  bool _words = true;

  /// The gentle background loop.
  bool get music => _music;

  /// Pops, chimes and snaps.
  bool get soundEffects => _soundEffects;

  /// Whether Boo speaks out loud.
  bool get voice => _voice;

  /// Whether the written colour word is shown.
  ///
  /// On for a child who is learning letters, off for one who is not reading
  /// yet. The game never requires reading either way.
  bool get words => _words;

  set music(bool value) {
    if (_music == value) return;
    _music = value;
    notifyListeners();
  }

  set soundEffects(bool value) {
    if (_soundEffects == value) return;
    _soundEffects = value;
    notifyListeners();
  }

  set voice(bool value) {
    if (_voice == value) return;
    _voice = value;
    notifyListeners();
  }

  set words(bool value) {
    if (_words == value) return;
    _words = value;
    notifyListeners();
  }
}

/// Makes the settings available to the whole app.
class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope({
    super.key,
    required Settings settings,
    required super.child,
  }) : super(notifier: settings);

  static Settings of(BuildContext context) {
    final SettingsScope? scope = context
        .dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found above this widget');
    return scope!.notifier!;
  }
}
