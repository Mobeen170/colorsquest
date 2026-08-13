import 'dart:math';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../boo/boo.dart';
import '../boo/boo_asset_catalog.dart';
import '../colors/color_library.dart';

/// The child-facing name and symbol for a place in Boo's play compass.
@immutable
class PlayPlace {
  const PlayPlace({
    required this.title,
    required this.shortTitle,
    required this.invitation,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String shortTitle;
  final String invitation;
  final IconData icon;
  final Color accent;
}

/// Compact chrome that keeps play immediate while making the world legible.
class WonderTopBar extends StatelessWidget {
  const WonderTopBar({
    super.key,
    required this.place,
    required this.discoveryCount,
    required this.onCompassTap,
  });

  final PlayPlace place;
  final int discoveryCount;
  final VoidCallback onCompassTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 360;

        return Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 4 : 14, 6, 88, 3),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 8 : 12,
                    vertical: narrow ? 5 : 7,
                  ),
                  child: Text(
                    narrow ? 'BOO' : 'COLORIBOO',
                    style: const TextStyle(
                      color: AppColors.starlight,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: narrow ? 5 : AppSpacing.sm),
              Expanded(
                child: Text(
                  place.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.starlight,
                    fontSize: narrow ? 13 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: narrow ? 4 : AppSpacing.sm),
              Semantics(
                label:
                    'Open Boo’s play compass. $discoveryCount colour discoveries this time.',
                button: true,
                child: _PressableGlow(
                  hitKey: const Key('play-compass-button'),
                  onTap: onCompassTap,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 54,
                      minHeight: 50,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.explore_rounded,
                          color: AppColors.starlight,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$discoveryCount',
                          style: const TextStyle(
                            color: AppColors.starlight,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A translucent prompt capsule shared by the recognition activities.
class ActivityPromptCard extends StatelessWidget {
  const ActivityPromptCard({
    super.key,
    required this.eyebrow,
    required this.semanticLabel,
    required this.onTap,
    this.hero,
    this.showHero = true,
    this.width = 390,
    this.icon = Icons.volume_up_rounded,
  });

  final String eyebrow;
  final String? hero;
  final bool showHero;
  final double width;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: _PressableGlow(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.bubblePurple.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.booBlue.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: AppColors.moonInk),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      eyebrow,
                      style: AppTheme.booLine,
                      textAlign: TextAlign.center,
                    ),
                    if (hero != null && showHero)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hero!.toUpperCase(),
                          maxLines: 1,
                          style: AppTheme.heroWord(width),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral glass around every activity. Tested colors never sit on twilight.
class WonderStage extends StatelessWidget {
  const WonderStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.glassLine, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.bubbleSky.withValues(alpha: 0.20),
            blurRadius: 34,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.twilight.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(painter: _StageConstellationPainter()),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boo's anchored companion dock. It can travel left, middle or right without
/// ever covering an answer target.
class BooCompanionDock extends StatelessWidget {
  const BooCompanionDock({
    super.key,
    required this.size,
    required this.mood,
    this.visualState = BooVisualState.idle,
    this.color,
    this.tint,
    required this.alignment,
    required this.leanTowards,
    required this.onTap,
  });

  final double size;
  final BooMood mood;
  final BooVisualState visualState;
  final ColorEntry? color;
  final Color? tint;
  final Alignment alignment;
  final double leanTowards;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: size * 1.02,
      child: AnimatedAlign(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        alignment: alignment,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              bottom: 2,
              child: Container(
                width: size * 0.86,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: AppColors.booBlue.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.booBlue.withValues(alpha: 0.22),
                      blurRadius: 22,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Boo(
              size: size,
              mood: mood,
              visualState: visualState,
              color: color,
              tint: tint,
              leanTowards: leanTowards,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// A non-blocking moment of delight. Big milestones add the orbiting lights;
/// ordinary discoveries stay calm and quick.
class WonderCelebration extends StatefulWidget {
  const WonderCelebration({
    super.key,
    required this.color,
    required this.label,
    required this.big,
  });

  final Color color;
  final String label;
  final bool big;

  @override
  State<WonderCelebration> createState() => _WonderCelebrationState();
}

class _WonderCelebrationState extends State<WonderCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final String _praise;
  late final int _seed;
  bool _reduceMotion = false;

  static const List<String> _praises = <String>[
    'YES!',
    'YOU GOT IT!',
    'AMAZING!',
    'BRILLIANT!',
    'WOOHOO!',
    'COLOUR STAR!',
    'POP-TASTIC!',
    'GREAT JOB!',
  ];

  @override
  void initState() {
    super.initState();

    final Random random = Random();

    _praise = widget.big
        ? 'WOW! SUPER STAR!'
        : _praises[random.nextInt(_praises.length)];

    _seed = random.nextInt(1 << 30);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.big ? 1700 : 1450),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating && _controller.value < 1) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '$_praise ${widget.label}. '
          '${widget.big ? 'The sky is glowing!' : 'You found the color!'}',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final double t = _reduceMotion ? 0.75 : _controller.value;

              final double reveal = _reduceMotion
                  ? 1
                  : Curves.easeOutBack.transform(min(1.0, t * 2.2));

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CustomPaint(
                    painter: _CelebrationConfettiPainter(
                      progress: t,
                      seed: _seed,
                      lessonColor: widget.color,
                      big: widget.big,
                      reduced: _reduceMotion,
                    ),
                  ),
                  Center(
                    child: Transform.scale(
                      scale: reveal,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 335),
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.big ? 30 : 24,
                          vertical: widget.big ? 22 : 17,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              AppColors.white.withValues(alpha: 0.98),
                              widget.color.withValues(alpha: 0.14),
                              AppColors.white.withValues(alpha: 0.98),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.70),
                            width: widget.big ? 4 : 3,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.42),
                              blurRadius: widget.big ? 46 : 34,
                              spreadRadius: widget.big ? 9 : 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _praise,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.moonInk,
                                fontSize: widget.big ? 28 : 24,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.label.toUpperCase(),
                                maxLines: 1,
                                style: TextStyle(
                                  color: AppColors.darkInk,
                                  fontSize: widget.big ? 38 : 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.big
                                  ? 'THE SKY IS GLOWING!'
                                  : 'YOU FOUND THE COLOUR!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.softInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CelebrationConfettiPainter extends CustomPainter {
  const _CelebrationConfettiPainter({
    required this.progress,
    required this.seed,
    required this.lessonColor,
    required this.big,
    required this.reduced,
  });

  final double progress;
  final int seed;
  final Color lessonColor;
  final bool big;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Random random = Random(seed);
    final Offset centre = size.center(Offset.zero);

    final int count = big ? 48 : 30;

    final List<Color> colors = <Color>[
      lessonColor,
      AppColors.booBlue,
      AppColors.bubblePink,
      AppColors.bubblePurple,
      AppColors.bubbleMint,
      AppColors.sunnyPop,
      AppColors.white,
    ];

    final double p = reduced ? 0.72 : Curves.easeOut.transform(progress);

    for (int i = 0; i < count; i++) {
      final double angle = random.nextDouble() * pi * 2;

      final double distance =
          (big ? 130 : 90) + random.nextDouble() * (big ? 220 : 155);

      final Offset position =
          centre +
          Offset(
            cos(angle) * distance * p,
            sin(angle) * distance * p + (progress * progress * 50),
          );

      final Color color = colors[random.nextInt(colors.length)];

      final double particleSize = 5 + random.nextDouble() * (big ? 11 : 8);

      final Paint paint = Paint()..color = color.withValues(alpha: 0.90);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + progress * pi * 2);

      if (i.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particleSize * 0.55,
              height: particleSize * 1.25,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particleSize * 0.42, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Optional chooser and honest session discovery trail. Opening Coloriboo
/// never depends on this sheet; it is there for a child who wants agency.
class PlayCompassSheet extends StatelessWidget {
  const PlayCompassSheet({
    super.key,
    required this.places,
    required this.currentIndex,
    required this.discoveries,
    required this.onSelected,
    required this.onFinishRequested,
  });

  final List<PlayPlace> places;
  final int currentIndex;
  final List<ColorEntry> discoveries;
  final ValueChanged<int> onSelected;
  final VoidCallback onFinishRequested;

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: height * 0.82),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        decoration: const BoxDecoration(
          color: AppColors.twilight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Boo(
                    size: 74,
                    mood: BooMood.pointing,
                    visualState: BooVisualState.pointing,
                  ),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'CHOOSE A GAME!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.starlight,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a big card to play!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.starlight.withValues(alpha: 0.70),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int columns = constraints.maxWidth >= 620 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: columns == 3 ? 1.38 : 1.24,
                    ),
                    itemCount: places.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PlayPlace place = places[index];
                      final bool current = index == currentIndex;
                      return Semantics(
                        button: true,
                        selected: current,
                        label: '${place.title}. ${place.invitation}',
                        child: _PressableGlow(
                          onTap: () => onSelected(index),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: current
                                  ? place.accent.withValues(alpha: 0.24)
                                  : AppColors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: current
                                    ? place.accent
                                    : AppColors.white.withValues(alpha: 0.14),
                                width: current ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(place.icon, color: place.accent, size: 29),
                                const SizedBox(height: 6),
                                Text(
                                  place.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.starlight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.blur_on_rounded,
                    color: AppColors.bubbleMint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      discoveries.isEmpty
                          ? 'Your Wonder Sky is waiting'
                          : '${discoveries.length} lights awake this time',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.starlight,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 62,
                child: discoveries.isEmpty
                    ? Center(
                        child: Text(
                          'Every colour you discover will glow here.',
                          style: TextStyle(
                            color: AppColors.starlight.withValues(alpha: 0.65),
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: discoveries.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final ColorEntry entry = discoveries[index];
                          return Semantics(
                            label: '${entry.name} discovered',
                            child: Container(
                              width: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: entry.color,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 3,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: entry.color.withValues(alpha: 0.65),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 18),
              Semantics(
                button: true,
                label: 'Finish for now',
                child: _PressableGlow(
                  onTap: onFinishRequested,
                  child: Container(
                    key: const Key('finish-for-now-button'),
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.bubblePurple.withValues(alpha: 0.50),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.nightlight_round,
                          color: AppColors.bubblePurple,
                        ),
                        SizedBox(width: 9),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ALL DONE',
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.starlight,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressableGlow extends StatefulWidget {
  const _PressableGlow({this.hitKey, required this.onTap, required this.child});

  final Key? hitKey;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableGlow> createState() => _PressableGlowState();
}

class _PressableGlowState extends State<_PressableGlow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      key: widget.hitKey,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Barely-there orbit lines keep large tablet stages composed without putting
/// colored decoration behind the shades a child is comparing.
class _StageConstellationPainter extends CustomPainter {
  const _StageConstellationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.paperShadow.withValues(alpha: 0.20);
    final Paint mote = Paint()
      ..color = AppColors.softInk.withValues(alpha: 0.08);

    final Rect wideOrbit = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.58),
      width: size.width * 0.78,
      height: size.height * 0.34,
    );
    final Rect tallOrbit = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.58),
      width: size.width * 0.42,
      height: size.height * 0.58,
    );
    canvas.drawArc(wideOrbit, pi * 0.10, pi * 0.58, false, line);
    canvas.drawArc(wideOrbit, pi * 1.10, pi * 0.58, false, line);
    canvas.drawArc(tallOrbit, pi * 0.55, pi * 0.42, false, line);

    const List<Offset> points = <Offset>[
      Offset(0.12, 0.30),
      Offset(0.88, 0.36),
      Offset(0.18, 0.78),
      Offset(0.80, 0.82),
      Offset(0.50, 0.90),
    ];
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
        Offset(points[i].dx * size.width, points[i].dy * size.height),
        i.isEven ? 3.2 : 2.2,
        mote,
      );
    }
  }

  @override
  bool shouldRepaint(_StageConstellationPainter oldDelegate) => false;
}
