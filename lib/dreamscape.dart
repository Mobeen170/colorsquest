import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'activities/boo_changes_colour.dart';
import 'activities/colour_mixing_lab.dart';
import 'activities/odd_one_out.dart';
import 'activities/pop_the_colour.dart';
import 'app_theme.dart';
import 'audio/audio_service.dart';
import 'boo/boo.dart';
import 'colors/color_library.dart';
import 'colors/color_mixes.dart';
import 'colors/color_picker_logic.dart';
import 'settings/parent_panel.dart';
import 'world/bubble_field.dart';
import 'world/paper_background.dart';
import 'world/splash_marks.dart';

/// The things Boo can offer to play.
enum Activity { popTheColour, oddOneOut, booChangesColour, mixingLab }

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

  Activity _activity = Activity.popTheColour;

  late ColorRound _round;
  ({ColorEntry common, ColorEntry odd, int total})? _oddRound;
  ColorMix? _mix;

  int _missCount = 0;
  int _correctSinceCelebration = 0;

  BooMood _mood = BooMood.idle;
  Color _booColor = AppColors.booBlue;
  double _booLean = 0;

  /// Blocks taps while a round is being resolved.
  bool _resolving = false;

  Timer? _idleChatterTimer;
  Timer? _repeatPromptTimer;

  /// The pause between finishing one thing and starting the next.
  ///
  /// Held as a timer rather than an awaited delay so it can be cancelled when
  /// the screen goes away, which keeps the app from ever trying to rebuild
  /// something that no longer exists.
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();

    _round = _picker.buildRound(_difficulty.step);

    // Boo greets the child as soon as the app opens. There is nothing to
    // press first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startActivity(Activity.popTheColour, speakGreeting: true);
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

    setState(() {
      _activity = activity;
      _missCount = 0;
      _resolving = false;
      _mood = BooMood.curious;
      _booLean = 0;

      switch (activity) {
        case Activity.popTheColour:
        case Activity.booChangesColour:
          _round = _picker.buildRound(_difficulty.step);
          _booColor = activity == Activity.booChangesColour
              ? _round.target.color
              : AppColors.booBlue;

        case Activity.oddOneOut:
          _oddRound = _picker.buildOddOneOutRound(_difficulty.step);
          _booColor = AppColors.booBlue;

        case Activity.mixingLab:
          _mix = ColorMixes.randomMix(_random);
          _booColor = AppColors.booBlue;
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
        return 'What colour am I?';
      case Activity.mixingLab:
        final ColorMix mix = _mix!;
        return 'Push ${mix.firstName} into ${mix.secondName}!';
    }
  }

  Future<void> _speakPrompt({bool greeting = false}) async {
    setState(() => _mood = BooMood.speaking);

    if (greeting) {
      await AudioService.instance.speak(
        'Hello! I am Boo. Let us find colours!',
      );
    }
    await AudioService.instance.speak(_promptText());

    if (!mounted) return;
    setState(() => _mood = BooMood.idle);

    // If the child hesitates, Boo quietly offers the word again rather than
    // hurrying them.
    _repeatPromptTimer?.cancel();
    _repeatPromptTimer = Timer(const Duration(seconds: 9), () {
      if (mounted && !_resolving) _speakPrompt();
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
    if (_activity == Activity.booChangesColour) {
      AudioService.instance.speak('What colour am I?');
    } else {
      AudioService.instance.speak(_promptText());
    }
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
    if (_resolving) return;

    if (outcome.correct) {
      await _handleCorrect(outcome);
    } else {
      await _handleMiss(outcome);
    }
  }

  Future<void> _handleCorrect(AnswerOutcome outcome) async {
    _resolving = true;
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    _difficulty.recordCorrect();
    _correctSinceCelebration++;

    _addSplash(outcome.tapped.color, outcome.position);

    AudioService.instance.playPop();
    AudioService.instance.playColorNote(
      outcome.tapped.semitone,
      withThird: true,
    );

    final bool bigMoment =
        _correctSinceCelebration >= 5 || _difficulty.level == 5;

    setState(() {
      _mood = bigMoment ? BooMood.zoom : BooMood.cheer;
      _booLean = 0;
    });

    if (bigMoment) {
      _correctSinceCelebration = 0;
      AudioService.instance.playCelebration();
    } else {
      AudioService.instance.playCorrect();
    }

    await AudioService.instance.speak(_praiseFor(outcome.tapped));

    if (!mounted) return;

    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _startActivity(_chooseNextActivity());
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
    _difficulty.recordMiss();

    setState(() {
      _missCount++;
      _mood = BooMood.gentle;
    });

    AudioService.instance.playTryAgain();

    // Naming whatever the child touched turns every single tap into a lesson,
    // even the ones that were not the answer.
    await AudioService.instance.speak('That is ${outcome.tapped.name}.');
    if (!mounted) return;

    if (_missCount == 1) {
      await AudioService.instance.speak(_promptText());
    } else if (_missCount == 2) {
      // Boo leans towards the answer and it starts to glow.
      setState(() => _booLean = 0.6);
      await AudioService.instance.speak('Try this one!');
    } else {
      await AudioService.instance.speak('Here it is!');
    }

    if (!mounted) return;
    setState(() => _mood = BooMood.idle);
  }

  Future<void> _onMixed(ColorEntry result, Offset position) async {
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    _addSplash(result.color, position);

    setState(() => _mood = BooMood.cheer);
    AudioService.instance.playSparkle();

    await AudioService.instance.speak('Look! They made ${result.name}!');
    if (!mounted) return;

    // A moment to admire the new colour before moving on.
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) _startActivity(_chooseNextActivity());
    });
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
          SplashMarksLayer(marks: _splashes),
          SafeArea(child: _content()),
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
        final double width = constraints.maxWidth;
        final bool tablet = AppSizing.isTablet(width);
        final double shortest = min(width, constraints.maxHeight);

        final double booSize = shortest * AppSizing.booFraction(width);

        return Center(
          child: ConstrainedBox(
            // Keeps the play area a comfortable width on a tablet instead of
            // stretching bubbles right across a large screen.
            constraints: const BoxConstraints(
              maxWidth: AppSizing.maxPlayBandWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? AppSpacing.xl : AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      child: KeyedSubtree(
                        key: ValueKey<String>(
                          '$_activity-${_round.target.name}-'
                          '${_mix?.resultName}-${_oddRound?.odd.name}',
                        ),
                        child: _activityWidget(),
                      ),
                    ),
                  ),

                  // Boo rides along the bottom, out of the way of the answers.
                  if (_activity != Activity.booChangesColour)
                    SizedBox(
                      height: booSize * 1.15,
                      child: Align(
                        alignment: tablet
                            ? Alignment.bottomCenter
                            : Alignment.bottomLeft,
                        child: Boo(
                          color: _booColor,
                          size: booSize,
                          mood: _mood,
                          leanTowards: _booLean,
                          onTap: _onBooTapped,
                        ),
                      ),
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
    }
  }
}
