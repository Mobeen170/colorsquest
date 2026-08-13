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
import 'boo/boo_asset_catalog.dart';
import 'colors/color_library.dart';
import 'colors/color_mixes.dart';
import 'colors/color_picker_logic.dart';
import 'colors/shade_ladder.dart';
import 'session/session_summary.dart';
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

/// Coloriboo's endless play world.
///
/// Boo always chooses another activity after a completed round. The world
/// only hands control back to the app shell when the child deliberately uses
/// the optional “Finish for now” path.
class Dreamscape extends StatefulWidget {
  const Dreamscape({super.key, required this.onFinish, this.onHome});

  /// Called only after the child deliberately confirms “Finish for now”.
  final ValueChanged<SessionSummary> onFinish;

  /// Child-friendly direct return to the start screen.
  final VoidCallback? onHome;

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

  /// Honest, in-memory memories for the optional end screen.
  final Map<String, ColorEntry> _exploredByName = <String, ColorEntry>{};
  int _activitiesCompleted = 0;
  int _successfulInteractions = 0;
  int _shadesDiscovered = 0;
  bool _finishing = false;
  final bool _leaving = false;

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

  /// Invalidates an older prompt flow when Hear Again, feedback, or a modal
  /// takes ownership of Boo's voice within the same activity.
  int _promptGeneration = 0;

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

  /// Releases touch input independently from optional device speech.
  Timer? _feedbackUnlockTimer;

  Future<void> _say(String text) async {
    await AudioService.instance.speak(text);
  }

  @override
  void initState() {
    super.initState();

    _round = _picker.buildRound(_difficulty.step);
    _shadeRound = ShadeLadder.buildRound(random: _random);

    // Boo greets the child as soon as the world-entry transition completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mood = BooMood.curious);
      _speakPrompt(greeting: true);
      _scheduleIdleChatter();
    });
  }

  @override
  void dispose() {
    _promptGeneration++;
    _idleChatterTimer?.cancel();
    _repeatPromptTimer?.cancel();
    _advanceTimer?.cancel();
    _feedbackUnlockTimer?.cancel();
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
    _feedbackUnlockTimer?.cancel();
    unawaited(AudioService.instance.stopSpeaking());
    _activityGeneration++;
    AudioService.instance.playActivityTransition();
    if (activity == Activity.booChangesColour) {
      AudioService.instance.playBooMagic();
    }

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
    final int activityGeneration = _activityGeneration;
    final int promptGeneration = ++_promptGeneration;
    if (!mounted) return;
    setState(() => _mood = BooMood.speaking);

    if (greeting) {
      await _say('Hello! I am Boo. Let us find colours!');
      if (!mounted ||
          activityGeneration != _activityGeneration ||
          promptGeneration != _promptGeneration) {
        return;
      }
    }
    await _say(_promptText());

    if (!mounted ||
        activityGeneration != _activityGeneration ||
        promptGeneration != _promptGeneration) {
      return;
    }
    setState(() => _mood = BooMood.waiting);

    // If the child hesitates, Boo quietly offers the word again rather than
    // hurrying them.
    _repeatPromptTimer?.cancel();
    _repeatPromptTimer = Timer(const Duration(seconds: 9), () {
      if (mounted &&
          activityGeneration == _activityGeneration &&
          promptGeneration == _promptGeneration &&
          !_resolving &&
          !_feedbackBusy) {
        _speakPrompt();
      }
    });
  }

  void _scheduleIdleChatter() {
    _idleChatterTimer?.cancel();
    _idleChatterTimer = Timer(Duration(seconds: 45 + _random.nextInt(40)), () {
      if (!mounted) return;
      if (_resolving ||
          _feedbackBusy ||
          _finishing ||
          _mood == BooMood.speaking) {
        // A prompt, retry, or transition owns Boo's voice right now. Keep the
        // optional chatter alive without interrupting the learning feedback.
        _scheduleIdleChatter();
        return;
      }

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
    if (_resolving || _feedbackBusy || _finishing || _leaving) return;
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

  void _onAnswer(AnswerOutcome outcome) {
    if (_resolving || _feedbackBusy) return;

    _promptGeneration++;
    _rememberExplored(outcome.tapped);

    if (outcome.correct) {
      _handleCorrect(outcome);
    } else {
      _handleMiss(outcome);
    }
  }

  void _handleCorrect(AnswerOutcome outcome) {
    final int generation = _activityGeneration;
    setState(() => _resolving = true);
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    _difficulty.recordCorrect();
    _correctSinceCelebration++;
    _activitiesCompleted++;
    _successfulInteractions++;

    _addSplash(outcome.tapped.color, outcome.position);
    _rememberDiscovery(outcome.tapped);

    switch (_activity) {
      case Activity.popTheColour:
        AudioService.instance.playPop();
      case Activity.oddOneOut:
        AudioService.instance.playSoftBubble();
      case Activity.booChangesColour:
        AudioService.instance
          ..playBooMagic()
          ..playSparkle();
      case Activity.mixingLab:
      case Activity.lightToDark:
        break;
    }

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
      AudioService.instance.playBigCelebration();
    } else {
      AudioService.instance
        ..playCorrect()
        ..playCheer();
    }

    // Visual feedback and endless progression never wait for optional TTS.
    unawaited(_say(_praiseFor(outcome.tapped)));

    _advanceTimer?.cancel();
    _advanceTimer = Timer(Duration(milliseconds: bigMoment ? 1550 : 1200), () {
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

  void _handleMiss(AnswerOutcome outcome) {
    final int generation = _activityGeneration;
    final int promptGeneration = _promptGeneration;
    _repeatPromptTimer?.cancel();
    setState(() => _feedbackBusy = true);
    _difficulty.recordMiss();

    setState(() {
      _missCount++;
      if (_missCount >= 2) {
        _booLean = _missCount.isEven ? -0.55 : 0.55;
        _mood = BooMood.pointing;
      } else {
        _booLean = 0;
        _mood = BooMood.gentle;
      }
    });

    AudioService.instance.playTryAgain();

    // A short tactile pause prevents accidental double taps. Device speech can
    // be slow or unavailable, so it must never hold the child's controls.
    _feedbackUnlockTimer?.cancel();
    _feedbackUnlockTimer = Timer(const Duration(milliseconds: 460), () {
      if (mounted && generation == _activityGeneration) {
        setState(() => _feedbackBusy = false);
      }
    });

    unawaited(
      _speakMissFeedback(
        outcome: outcome,
        missCount: _missCount,
        activityGeneration: generation,
        promptGeneration: promptGeneration,
      ),
    );
  }

  Future<void> _speakMissFeedback({
    required AnswerOutcome outcome,
    required int missCount,
    required int activityGeneration,
    required int promptGeneration,
  }) async {
    // Naming the tapped colour turns a miss into a lesson. Generation checks
    // prevent an interrupted retry from speaking over a newer answer/modal.
    await _say('That is ${outcome.tapped.name}.');
    if (!_feedbackSpeechIsCurrent(activityGeneration, promptGeneration)) {
      return;
    }

    await _say(switch (missCount) {
      1 => _promptText(),
      2 => 'Try this one!',
      _ => 'Here it is!',
    });
    if (!_feedbackSpeechIsCurrent(activityGeneration, promptGeneration)) {
      return;
    }

    setState(() => _mood = BooMood.waiting);
  }

  bool _feedbackSpeechIsCurrent(int activityGeneration, int promptGeneration) {
    return mounted &&
        !_resolving &&
        !_finishing &&
        activityGeneration == _activityGeneration &&
        promptGeneration == _promptGeneration;
  }

  void _onMixed(ColorEntry result, Offset position) {
    if (_resolving || _finishing || _leaving) return;
    _promptGeneration++;
    final int generation = _activityGeneration;
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    final ColorMix mix = _mix!;
    _rememberExplored(ColorLibrary.byName(mix.firstName));
    _rememberExplored(ColorLibrary.byName(mix.secondName));
    _rememberExplored(result);
    _activitiesCompleted++;
    _successfulInteractions++;

    _addSplash(result.color, position);
    _rememberDiscovery(result);

    setState(() {
      _resolving = true;
      _mood = BooMood.cheer;
      _celebration = result;
      _bigCelebration = false;
      _celebrationSerial++;
    });
    // The activity owns the tactile merge sound. This single flourish marks
    // completion without replaying the merge or stacking two cheers.
    AudioService.instance.playCelebration();

    unawaited(_say('Look! They made ${result.name}!'));

    // A moment to admire the new colour before moving on.
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && generation == _activityGeneration) {
        _startActivity(_chooseNextActivity());
      }
    });
  }

  void _onShadeSorted(ColorEntry base, Offset position) {
    if (_resolving || _finishing || _leaving) return;
    _promptGeneration++;
    final int generation = _activityGeneration;
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();

    _rememberExplored(base);
    _activitiesCompleted++;
    _successfulInteractions++;
    _shadesDiscovered += _shadeRound.correctOrder.length;

    _addSplash(base.color, position);
    _rememberDiscovery(base);

    setState(() {
      _resolving = true;
      _mood = BooMood.cheer;
      _celebration = base;
      _bigCelebration = false;
      _celebrationSerial++;
    });
    AudioService.instance
      ..playCorrect()
      ..playCheer();
    unawaited(_say('Lovely! ${base.name}, from light to dark!'));

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

  void _rememberExplored(ColorEntry? entry) {
    if (entry == null) return;
    _exploredByName.putIfAbsent(entry.name, () => entry);
  }

  SessionSummary _sessionSnapshot() {
    return SessionSummary(
      activitiesCompleted: _activitiesCompleted,
      successfulInteractions: _successfulInteractions,
      shadesDiscovered: _shadesDiscovered,
      colorsExplored: _exploredByName.values.toList(growable: false),
    );
  }

  // ---- Building the world ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dreamscape-screen'),
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
            ? (shortest * 0.23).clamp(82.0, 116.0)
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
                vertical: compactLandscape ? 0 : AppSpacing.xs,
              ),
              child: Column(
                children: <Widget>[
                  WonderTopBar(
                    place: _placeFor(_activity),
                    discoveryCount: _discoveries.length,
                    onCompassTap: _openCompass,
                  ),
                  SizedBox(height: compactLandscape ? 0 : 4),
                  Expanded(
                    child: WonderStage(
                      child: IgnorePointer(
                        ignoring:
                            _resolving ||
                            _feedbackBusy ||
                            _finishing ||
                            _leaving,
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
                      visualState: _booVisualState(),
                      color: _booResultColor,
                      tint: _booResultColor?.color,
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

  /// Selects an expressive pose from the event that is happening now.
  ///
  /// Question-time choices are deliberately independent of the requested
  /// color. A result color is only supplied by [_booResultColor] after the
  /// child has completed an activity, so Boo can never disclose an answer.
  BooVisualState _booVisualState() {
    if (_celebration != null || _resolving) {
      if (_bigCelebration) return BooVisualState.bigCelebration;
      if (_activity == Activity.mixingLab) return BooVisualState.magic;
      if (_activity == Activity.lightToDark) return BooVisualState.correct;
      return BooVisualState.correct;
    }

    return switch (_mood) {
      BooMood.gentle => BooVisualState.tryAgain,
      BooMood.pointing => BooVisualState.pointing,
      BooMood.thinking => BooVisualState.thinking,
      BooMood.mixing => BooVisualState.magic,
      BooMood.curious => BooVisualState.alert,
      BooMood.cheer => BooVisualState.correct,
      BooMood.zoom => BooVisualState.bigCelebration,
      BooMood.speaking => BooVisualState.idle,
      BooMood.waiting || BooMood.idle => switch (_activity) {
        Activity.oddOneOut || Activity.lightToDark => BooVisualState.thinking,
        Activity.mixingLab => BooVisualState.magic,
        Activity.popTheColour ||
        Activity.booChangesColour => BooVisualState.idle,
      },
    };
  }

  /// Result-color artwork is enabled only after success, and only for the
  /// activities where seeing the finished family reinforces the lesson.
  ColorEntry? get _booResultColor {
    if (_celebration == null || !_resolving || _bigCelebration) return null;
    return switch (_activity) {
      Activity.mixingLab || Activity.lightToDark => _celebration,
      Activity.popTheColour ||
      Activity.oddOneOut ||
      Activity.booChangesColour => null,
    };
  }

  void _openCompass() {
    if (_resolving || _feedbackBusy || _finishing) return;
    unawaited(_showCompass());
  }

  Future<void> _showCompass() async {
    _repeatPromptTimer?.cancel();
    _idleChatterTimer?.cancel();
    _promptGeneration++;
    unawaited(AudioService.instance.stopSpeaking());
    setState(() => _mood = BooMood.curious);

    final bool? finishRequested = await showModalBottomSheet<bool>(
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
          onFinishRequested: () {
            Navigator.of(sheetContext).pop(true);
          },
        );
      },
    );

    if (!mounted) return;
    if (finishRequested == true) {
      await _confirmFinish();
      return;
    }

    _scheduleIdleChatter();
    if (_mood == BooMood.curious) setState(() => _mood = BooMood.waiting);
  }

  Future<void> _confirmFinish() async {
    if (_finishing || _resolving || _feedbackBusy) return;
    _finishing = true;

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: AppColors.darkInk.withValues(alpha: 0.38),
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              key: const Key('finish-confirm-dialog'),
              backgroundColor: AppColors.paperCream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              icon: const Icon(
                Icons.nightlight_round,
                color: AppColors.bubblePurple,
                size: 38,
              ),
              title: const Text(
                'All done for now?',
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'Boo will keep your sky glowing for this goodbye.',
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton.icon(
                  key: const Key('keep-playing-button'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'KEEP PLAYING',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('confirm-finish-button'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(
                    "YES, I'M DONE",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) return;
    if (!confirmed) {
      _finishing = false;
      _scheduleIdleChatter();
      setState(() => _mood = BooMood.waiting);
      return;
    }

    _activityGeneration++;
    _idleChatterTimer?.cancel();
    _repeatPromptTimer?.cancel();
    _advanceTimer?.cancel();
    unawaited(AudioService.instance.stopSpeaking());
    AudioService.instance.playFinishSession();
    widget.onFinish(_sessionSnapshot());
  }
}
