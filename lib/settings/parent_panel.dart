import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'settings.dart';

/// The only control on any play screen.
///
/// Deliberately small, quiet and low contrast so a child never aims for it,
/// and it needs a long press rather than a tap so it cannot be opened by
/// accident. Everything else on screen belongs to the child.
class ParentDot extends StatelessWidget {
  const ParentDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Grown-up settings. Press and hold to open.',
      button: true,
      onLongPress: () => showParentSettings(context),
      child: GestureDetector(
        onLongPress: () => showParentSettings(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // A generous invisible margin, so a parent can find it easily
          // without the dot itself being large enough to attract a child.
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softInk.withValues(alpha: 0.14),
            ),
            child: Center(
              child: Icon(
                Icons.more_horiz,
                size: 16,
                color: AppColors.softInk.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the same quiet grown-up controls from the start screen and world.
void showParentSettings(BuildContext context) {
  final Settings settings = SettingsScope.of(context);

  showDialog<void>(
    context: context,
    barrierColor: AppColors.darkInk.withValues(alpha: 0.32),
    builder: (BuildContext dialogContext) {
      return SettingsScope(settings: settings, child: const _ParentPanel());
    },
  );
}

/// Four switches and nothing else.
class _ParentPanel extends StatelessWidget {
  const _ParentPanel();

  @override
  Widget build(BuildContext context) {
    final Settings settings = SettingsScope.of(context);

    return Dialog(
      backgroundColor: AppColors.paperCream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'For grown-ups',
                  style: AppTheme.settingLabel.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'These reset when the app is closed.',
                  style: AppTheme.microLabel,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                _Toggle(
                  label: 'Music',
                  value: settings.music,
                  onChanged: (bool v) => settings.music = v,
                ),
                _Toggle(
                  label: 'Sound effects',
                  value: settings.soundEffects,
                  onChanged: (bool v) => settings.soundEffects = v,
                ),
                _Toggle(
                  label: "Boo's voice",
                  value: settings.voice,
                  onChanged: (bool v) => settings.voice = v,
                ),
                _Toggle(
                  label: 'Show written words',
                  value: settings.words,
                  onChanged: (bool v) => settings.words = v,
                ),

                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Done', style: AppTheme.settingLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: AppSpacing.minTouchTarget,
        title: Text(label, style: AppTheme.settingLabel),
        value: value,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.booBlue,
        onChanged: onChanged,
      ),
    );
  }
}
