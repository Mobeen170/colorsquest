import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'audio/audio_service.dart';
import 'dreamscape.dart';
import 'settings/settings.dart';

void main() {
  runApp(const ColorGameApp());
}

/// Coloriboo.
///
/// Pop. Play. Learn Colours.
class ColorGameApp extends StatefulWidget {
  const ColorGameApp({super.key});

  @override
  State<ColorGameApp> createState() => _ColorGameAppState();
}

class _ColorGameAppState extends State<ColorGameApp> {
  final Settings _settings = Settings();

  @override
  void initState() {
    super.initState();

    // Sound is a bonus, never a requirement. If the engine will not start or
    // the audio files have not been added yet, this quietly does nothing and
    // the app plays on in silence.
    AudioService.instance.start(_settings);
  }

  @override
  void dispose() {
    AudioService.instance.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: _settings,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coloriboo',
        theme: AppTheme.light(),

        // There is no home screen and no start button. The app opens straight
        // into the world with Boo already there.
        home: const Dreamscape(),
      ),
    );
  }
}
