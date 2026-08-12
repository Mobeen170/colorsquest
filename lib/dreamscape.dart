import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'activities/boo_changes_colour.dart';
import 'activities/colour_mixing_lab.dart';
import 'activities/light_to_dark.dart';
import 'activities/odd_one_out.dart';
import 'activities/pop_the_colour.dart';
import 'app_theme.dart';
import 'audio/audio_service.dart';
import 'boo/boo.dart';
import 'colors/color_library.dart';
import 'colors/color_mixes.dart';
import 'colors/color_picker_logic.dart';
import 'colors/shade_ladder.dart';
import 'settings/parent_panel.dart';
import 'world/bubble_field.dart';
import 'world/paper_background.dart';
import 'world/splash_marks.dart';
import 'world/wonder_chrome.dart';

/// The things Boo can offer to play.
enum Activity {
  popTheColour,
  oddOneOut,
  booChangesColour,
  mixingLab,
  lightToDark,
}

/// The whole app.
///
/// There is no home screen, no menu and no results. A child opens Coloriboo
/// and is already playing, and it never ends. Boo decides what comes next and
/// the world simply carries on.
class Dreamscape extends StatefulWidget {
  const Dreamscape({super.key});

  @override
  State<Dreamscape> createState() => _DreamscapeState();
}

class _DreamscapeState extends State<Dreamscape> {
  final Random _random = Random();
  final ColorPicker _picker = ColorPicker();
  final DifficultyTracker _difficulty = DifficultyTracker();

  /// Every splash the child has made this sitting. The only thing that
  /// accumulates anywhere, and it is not a score.
  final List<SplashMark> _splashes = <SplashMark>[];

  /// Unique colour lights awoken during this sitting. This is an honest
  /// session trail, not a collection that pretends to be saved.
  final List<ColorEntry> _discoveries = <ColorEntry>[];

  Activity _activity = Activity.popTheColour;

  late ColorRound _round;
  ({ColorEntry common, ColorEntry odd, int total})? _oddRound;
  ColorMix? _mix;
  late ShadeRound _shadeRound;

  int _missCount = 0;
  int _correctSinceCelebration = 0;

  BooMood _mood = BooMood.idle;
  double _booLean = 0;

  /// Blocks taps while a round is being resolved.
  bool _resolving = false;
  bool _feedbackBusy = false;

  /// Invalidates speech/feedback that belongs to an activity already left.
  int _activityGeneration = 0;

  ColorEntry? _celebration;
  bool _bigCelebration = false;
  int _celebrationSerial = 0;

  Timer? _idleChatterTimer;
  Timer? _repeatPromptTimer;

  /// The pause between finishing one thing and starting the next.
  ///
  /// Held as a timer rather than an awaited delay so it can be cancelled when
  /// the screen goes away, which keeps the app from ever trying to rebuild
  /// something that no longer exists.
  Timer? _advanceTimer;

  Future<void> _say(String text) async {
    await AudioService.instance
        .speak(text)
        .timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  @override
  void initState() {
    super.initState();

    _round = _picker.buildRound(_difficulty.step);
    _shadeRound = ShadeLadder.buildRound(random: _random);

    // Boo greets the child as soon as the app opens. There is nothing to
    // press first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mood = BooMood.curious);
      _speakPrompt(greeting: true);
      _scheduleIdleChatter();
    });
  }

  @override
  void dispose() {
    _idleChatterTimer?.cancel();
    _repeatPromptTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  // ---- Choosing what to play -------------------------------------------

  /// Picks something to do next, avoiding whatever was just played.
  Activity _chooseNextActivity() {
    final List<Activity> options = Activity.values
        .where((Activity a) => a != _activity)
        .toList();
    return options[_random.nextInt(options.length)];
  }

  void _startActivity(Activity activity, {bool speakGreeting = false}) {
    _repeatPromptTimer?.cancel();
    _advanceTimer?.cancel();
    AudioService.instance.stopSpeaking();
    _activityGeneration++;

    setState(() {
      _activity = activity;
      _missCount = 0;
      _resolving = false;
      _feedbackBusy = false;
      _mood = activity == Activity.mixingLab
          ? BooMood.mixing
          : activity == Activity.lightToDark
          ? BooMood.thinking
          : BooMood.curious;
      _booLean = 0;
      _celebration = null;

      switch (activity) {
        case Activity.popTheColour:
        case Activity.booChangesColour:
          _round = _picker.buildRound(_difficulty.step);

        case Activity.oddOneOut:
          _oddRound = _picker.buildOddOneOutRound(_difficulty.step);

        case Activity.mixingLab:
          _mix = ColorMixes.randomMix(_random);

        case Activity.lightToDark:
          _shadeRound = ShadeLadder.buildRound(random: _random);
      }
    });

    _speakPrompt(greeting: speakGreeting);
    _scheduleIdleChatter();
  }

  // ---- Boo talking ------------------------------------------------------

  String _promptText() {
    switch (_activity) {
      case Activity.popTheColour:
        return 'Can you find ${_round.target.name}?';
      case Activity.oddOneOut:
        return 'Which one is different?';
      case Activity.booChangesColour:
        return 'What colour is my magic?';
      case Activity.mixingLab:
        final ColorMix mix = _mix!;
        return 'Push ${mix.firstName} into ${mix.secondName}!';
      case Activity.lightToDark:
        return 'Put the ${_shadeRound.base.name} shades from light to dark!';
    }
  }

  Future<void> _speakPrompt({bool greeting = false}) async {
    final int generation = _activityGeneration;
    if (!mounted) return;
    setState(() => _mood = BooMood.speaking);

    if (greeting) {
      await _say('Hello! I am Boo. Let us find colours!');
    }
    await _say(_promptText());

    if (!mounted || generation != _activityGeneration) return;
    setState(() => _mood = BooMood.waiting);

    // If the child hesitates, Boo quietly offers the word again rather than
    // hurrying them.
    _repeatPromptTimer?.cancel();
    _repeatPromptTimer = Timer(const Duration(seconds: 9), () {
      if (mounted &&
          generation == _activityGeneration &&
          !_resolving &&
          !_feedbackBusy) {
        _speakPrompt();
      }
    });
  }

  void _scheduleIdleChatter() {
    _idleChatterTimer?.cancel();
    _idleChatterTimer = Timer(Duration(seconds: 45 + _random.nextInt(40)), () {
      if (!mounted || _resolving) return;

      const List<String> lines = <String>[
        'I love bubbles!',
        'Colours are everywhere!',
        'You are doing so well.',
        'What a lovely day for popping.',
      ];

      AudioService.instance.speak(lines[_random.nextInt(lines.length)]);
      _scheduleIdleChatter();
    });
  }

  /// Tapping Boo makes him talk. A child who is stuck can always hear the
  /// word again just by touching him.
  void _onBooTapped() {
    if (_resolving || _feedbackBusy) return;
    _speakPrompt();
  }

  // ---- Answering --------------------------------------------------------

  void _addSplash(Color color, Offset position) {
    setState(() {
      _splashes.add(
        SplashMark(
          position: position,
          color: color,
          radius: 0.10 + (_random.nextDouble() * 0.06),
          seed: _random.nextInt(100000),
          bornAt: DateTime.now(),
        ),
      );

      // Keep the paper from filling up completely over a very long sitting.
      while (_splashes.length > 40) {
        _splashes.removeAt(0);
      }
    });
  }

  Future<void> _onAnswer(AnswerOutcome outcome) async {
    if (_resolving || _feedbackBusy) return;

    if (outcome.correct) {
      await _handleCorrect(outcome);
    } else {
      await _handleMiss(outcome);
    }
  }

  Future<void> _handleCorrect(AnswerOutcome outcome) async {
    final int generation = _activityGeneration;
    setState(() => _resolving = true);
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    _difficulty.recordCorrect();
    _correctSinceCelebration++;

    _addSplash(outcome.tapped.color, outcome.position);
    _rememberDiscovery(outcome.tapped);

    AudioService.instance.playPop();

    final bool bigMoment = _correctSinceCelebration >= 5;

    setState(() {
      _mood = bigMoment ? BooMood.zoom : BooMood.cheer;
      _booLean = 0;
      _celebration = outcome.tapped;
      _bigCelebration = bigMoment;
      _celebrationSerial++;
    });

    if (bigMoment) {
      _correctSinceCelebration = 0;
      AudioService.instance.playCelebration();
    } else {
      AudioService.instance.playCorrect();
    }

    await _say(_praiseFor(outcome.tapped));

    if (!mounted || generation != _activityGeneration) return;

    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && generation == _activityGeneration) {
        _startActivity(_chooseNextActivity());
      }
    });
  }

  String _praiseFor(ColorEntry entry) {
    const List<String> praise = <String>[
      'Yes! That is',
      'Well done! That is',
      'Lovely! That is',
      'You found',
    ];
    return '${praise[_random.nextInt(praise.length)]} ${entry.name}!';
  }

  Future<void> _handleMiss(AnswerOutcome outcome) async {
    final int generation = _activityGeneration;
    setState(() => _feedbackBusy = true);
    _difficulty.recordMiss();

    setState(() {
      _missCount++;
      _mood = BooMood.gentle;
    });

    AudioService.instance.playTryAgain();

    // Naming whatever the child touched turns every single tap into a lesson,
    // even the ones that were not the answer.
    await _say('That is ${outcome.tapped.name}.');
    if (!mounted || generation != _activityGeneration) return;

    if (_missCount == 1) {
      await _say(_promptText());
    } else if (_missCount == 2) {
      // Boo leans towards the answer and it starts to glow.
      setState(() {
        _booLean = _missCount.isEven ? -0.55 : 0.55;
        _mood = BooMood.pointing;
      });
      await _say('Try this one!');
    } else {
      await _say('Here it is!');
    }

    if (!mounted || generation != _activityGeneration) return;
    setState(() {
      _mood = BooMood.waiting;
      _feedbackBusy = false;
    });
  }

  Future<void> _onMixed(ColorEntry result, Offset position) async {
    if (_resolving) return;
    final int generation = _activityGeneration;
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    _addSplash(result.color, position);
    _rememberDiscovery(result);

    setState(() {
      _resolving = true;
      _mood = BooMood.cheer;
      _celebration = result;
      _bigCelebration = false;
      _celebrationSerial++;
    });
    AudioService.instance.playSparkle();

    await _say('Look! They made ${result.name}!');
    if (!mounted || generation != _activityGeneration) return;

    // A moment to admire the new colour before moving on.
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && generation == _activityGeneration) {
        _startActivity(_chooseNextActivity());
      }
    });
  }

  Future<void> _onShadeSorted(ColorEntry base, Offset position) async {
    if (_resolving) return;
    final int generation = _activityGeneration;
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();
    _addSplash(base.color, position);
    _rememberDiscovery(base);

    setState(() {
      _resolving = true;
      _mood = BooMood.cheer;
      _celebration = base;
      _bigCelebration = false;
      _celebrationSerial++;
    });
    AudioService.instance.playSparkle();
    await _say('Lovely! ${base.name}, from light to dark!');
    if (!mounted || generation != _activityGeneration) return;

    _advanceTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted && generation == _activityGeneration) {
        _startActivity(_chooseNextActivity());
      }
    });
  }

  void _rememberDiscovery(ColorEntry entry) {
    if (_discoveries.any((ColorEntry old) => old.name == entry.name)) return;
    setState(() => _discoveries.add(entry));
  }

  // ---- Building the world ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const PaperBackground(),
          const BubbleField(),
          SplashMarksLayer(marks: List<SplashMark>.unmodifiable(_splashes)),
          SafeArea(child: _content()),
          if (_celebration != null)
            WonderCelebration(
              key: ValueKey<int>(_celebrationSerial),
              color: _celebration!.color,
              label: _celebration!.name,
              big: _bigCelebration,
            ),
          const Positioned(
            top: 0,
            right: 0,
            child: SafeArea(child: ParentDot()),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        final bool expanded = AppSizing.isExpanded(size);
        final bool compactLandscape = AppSizing.isCompactLandscape(size);
        final double shortest = min(size.width, size.height);
        final double booSize = compactLandscape
            ? shortest * 0.29
            : (shortest * AppSizing.booFraction(size.width)).clamp(96, 210);
        final bool reduced = MediaQuery.disableAnimationsOf(context);

        return Center(
          child: ConstrainedBox(
            // Keeps the play area a comfortable width on a tablet instead of
            // stretching bubbles right across a large screen.
            constraints: const BoxConstraints(
              maxWidth: AppSizing.maxPlayBandWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? AppSpacing.xl : AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: <Widget>[
                  WonderTopBar(
                    place: _placeFor(_activity),
                    discoveryCount: _discoveries.length,
                    onCompassTap: _openCompass,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: WonderStage(
                      child: IgnorePointer(
                        ignoring: _resolving || _feedbackBusy,
                        child: AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 360),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.025, 0.02),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                          child: KeyedSubtree(
                            key: ValueKey<String>(
                              '$_activity-${_round.target.name}-'
                              '${_mix?.resultName}-${_oddRound?.odd.name}-'
                              '${_shadeRound.base.name}',
                            ),
                            child: _activityWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Boo travels around the companion dock instead of staying
                  // parked in one corner. The teaching activity brings him
                  // into the stage itself.
                  if (_activity != Activity.booChangesColour)
                    BooCompanionDock(
                      size: booSize,
                      mood: _mood,
                      alignment: _booAlignment(),
                      leanTowards: _booLean,
                      onTap: _onBooTapped,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _activityWidget() {
    switch (_activity) {
      case Activity.popTheColour:
        return PopTheColour(
          round: _round,
          missCount: _missCount,
          onAnswer: _onAnswer,
          onBooTapped: _onBooTapped,
        );

      case Activity.oddOneOut:
        final ({ColorEntry common, ColorEntry odd, int total}) odd =
            _oddRound ?? _picker.buildOddOneOutRound(_difficulty.step);
        return OddOneOut(
          common: odd.common,
          odd: odd.odd,
          total: odd.total,
          missCount: _missCount,
          onAnswer: _onAnswer,
          onBooTapped: _onBooTapped,
        );

      case Activity.booChangesColour:
        return BooChangesColour(
          round: _round,
          missCount: _missCount,
          onAnswer: _onAnswer,
          onBooTapped: _onBooTapped,
        );

      case Activity.mixingLab:
        return ColourMixingLab(
          mix: _mix ?? ColorMixes.randomMix(_random),
          onMixed: _onMixed,
          onBooTapped: _onBooTapped,
        );

      case Activity.lightToDark:
        return LightToDark(
          round: _shadeRound,
          onComplete: _onShadeSorted,
          onBooTapped: _onBooTapped,
        );
    }
  }

  static const List<PlayPlace> _places = <PlayPlace>[
    PlayPlace(
      title: 'Pop the Colour',
      shortTitle: 'Bubble Garden',
      invitation: 'Listen, look and pop the colour Boo names.',
      icon: Icons.bubble_chart_rounded,
      accent: AppColors.booBlue,
    ),
    PlayPlace(
      title: 'Odd One Out',
      shortTitle: 'Prism Constellation',
      invitation: 'Find the light that is different.',
      icon: Icons.scatter_plot_rounded,
      accent: AppColors.sunnyPop,
    ),
    PlayPlace(
      title: 'Boo’s Magic',
      shortTitle: 'Boo’s Prism Glow',
      invitation: 'Name the exact colour glowing around Boo.',
      icon: Icons.auto_awesome_rounded,
      accent: AppColors.bubblePink,
    ),
    PlayPlace(
      title: 'Mixing Lab',
      shortTitle: 'Moonbeam Mixing Lab',
      invitation: 'Bring two colour bubbles together.',
      icon: Icons.science_rounded,
      accent: AppColors.bubbleMint,
    ),
    PlayPlace(
      title: 'Light to Dark',
      shortTitle: 'Colour Sunset',
      invitation: 'Put one colour’s lights from brightest to darkest.',
      icon: Icons.brightness_6_rounded,
      accent: AppColors.bubblePurple,
    ),
  ];

  PlayPlace _placeFor(Activity activity) => _places[activity.index];

  Alignment _booAlignment() {
    switch (_activity) {
      case Activity.popTheColour:
        return Alignment.bottomLeft;
      case Activity.oddOneOut:
        return Alignment.bottomRight;
      case Activity.booChangesColour:
        return Alignment.bottomCenter;
      case Activity.mixingLab:
        return Alignment.bottomCenter;
      case Activity.lightToDark:
        return Alignment.bottomRight;
    }
  }

  void _openCompass() {
    if (_resolving || _feedbackBusy) return;
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();
    AudioService.instance.stopSpeaking();
    setState(() => _mood = BooMood.curious);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return PlayCompassSheet(
          places: _places,
          currentIndex: _activity.index,
          discoveries: List<ColorEntry>.unmodifiable(_discoveries),
          onSelected: (int index) {
            Navigator.of(sheetContext).pop();
            _startActivity(Activity.values[index]);
          },
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      _scheduleIdleChatter();
      if (_mood == BooMood.curious) setState(() => _mood = BooMood.waiting);
    });
  }
}
