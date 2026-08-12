import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../settings/settings.dart';

/// Big, obvious navigation made specifically for young children.
class KidNavButton extends StatefulWidget {
  const KidNavButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.dark = true,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool dark;

  @override
  State<KidNavButton> createState() => _KidNavButtonState();
}

class _KidNavButtonState extends State<KidNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 100),
          scale: _pressed ? 0.92 : 1,
          curve: Curves.easeOutBack,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            decoration: BoxDecoration(
              color: widget.dark
                  ? widget.accent.withValues(alpha: 0.20)
                  : AppColors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.62),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.20),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 23, color: widget.accent),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: widget.dark
                          ? AppColors.starlight
                          : AppColors.moonInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One quick child-facing mute button.
///
/// Parent Music / SFX / Voice choices are preserved underneath it.
class MasterSoundButton extends StatelessWidget {
  const MasterSoundButton({
    super.key,
    this.dark = false,
    this.showLabel = true,
  });

  final bool dark;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final Settings settings = SettingsScope.of(context);
    final bool muted = settings.masterMuted;

    return SizedBox(
      width: showLabel ? 92 : 58,
      child: KidNavButton(
        key: const Key('master-sound-button'),
        label: showLabel ? (muted ? 'SOUND OFF' : 'SOUND ON') : '',
        semanticLabel: muted ? 'Turn sound on' : 'Mute all sound',
        icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        accent: muted ? AppColors.softInk : AppColors.sunnyPop,
        dark: dark,
        onTap: () {
          final bool wasMuted = settings.masterMuted;

          if (!wasMuted) {
            AudioService.instance.playButtonTap();
          }

          settings.toggleMasterMute();

          if (wasMuted) {
            AudioService.instance.playButtonTap();
          }
        },
      ),
    );
  }
}
