import 'package:flutter/widgets.dart';

/// Coloriboo's simple in-memory settings.
///
/// Parent choices remain individual, while [masterMuted] is the obvious
/// child-facing quick mute that temporarily sits above them.
class Settings extends ChangeNotifier {
  bool _music = true;
  bool _soundEffects = true;
  bool _voice = true;
  bool _words = true;
  bool _masterMuted = false;

  bool get music => _music;
  bool get soundEffects => _soundEffects;
  bool get voice => _voice;
  bool get words => _words;

  /// Quick child-facing mute. It does NOT destroy the parent's individual
  /// Music / SFX / Voice choices.
  bool get masterMuted => _masterMuted;

  bool get effectiveMusic => _music && !_masterMuted;
  bool get effectiveSoundEffects => _soundEffects && !_masterMuted;
  bool get effectiveVoice => _voice && !_masterMuted;

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

  set masterMuted(bool value) {
    if (_masterMuted == value) return;
    _masterMuted = value;
    notifyListeners();
  }

  void toggleMasterMute() {
    masterMuted = !_masterMuted;
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
