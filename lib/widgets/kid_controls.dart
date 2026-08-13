import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../audio/audio_service.dart';
import '../settings/settings.dart';

/// A large, obvious child-facing navigation control.
///
/// Portrait/tablet keeps the controls roomy. A short landscape phone gets
/// a slightly shorter version so the learning stage always has enough room.
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
    final Size screen = MediaQuery.sizeOf(context);

    final bool compactLandscape =
        screen.width > screen.height && screen.height < 520;

    // Even the short-landscape layout keeps a platform-standard 48px target.
    // Visuals can compress, but the area a young child must hit cannot.
    final double height = compactLandscape ? kMinInteractiveDimension : 56;
    final double iconSize = compactLandscape ? 18 : 23;
    final double labelSize = compactLandscape ? 9.5 : 11;

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
          curve: Curves.easeOutBack,
          scale: _pressed ? 0.92 : 1,
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            padding: EdgeInsets.symmetric(
              horizontal: 5,
              vertical: compactLandscape ? 1 : 6,
            ),
            decoration: BoxDecoration(
              color: widget.dark
                  ? widget.accent.withValues(alpha: 0.22)
                  : AppColors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(compactLandscape ? 15 : 20),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.62),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.18),
                  blurRadius: compactLandscape ? 7 : 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(widget.icon, size: iconSize, color: widget.accent),
                if (!compactLandscape) const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: widget.dark
                          ? AppColors.starlight
                          : AppColors.moonInk,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.35,
                      height: 1,
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

/// One obvious child-facing sound control.
///
/// Master mute never overwrites the parent's individual Music / SFX / Voice
/// choices. It simply temporarily sits above them.
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
