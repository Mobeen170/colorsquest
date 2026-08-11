import 'dart:async';
import 'package:flutter/material.dart';
import 'result_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // All game colors
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  // Color names
  final List<String> colorNames = [
    'RED',
    'BLUE',
    'GREEN',
    'YELLOW',
    'ORANGE',
    'PURPLE',
    'PINK',
  ];

  // 10 questions
  final List<int> questions = [
    0, // Red
    1, // Blue
    2, // Green
    3, // Yellow
    4, // Orange
    5, // Purple
    6, // Pink
    0, // Red
    4, // Orange
    5, // Purple
  ];

  int questionNumber = 0;
  int score = 0;

  String message = '';

  bool answerSelected = false;

  // Options for current question
  List<int> currentOptions = [];

  @override
  void initState() {
    super.initState();

    createOptions();
  }

  // Create 4 options
  void createOptions() {
    int correctAnswer = questions[questionNumber];

    List<int> options = [];

    // Correct answer must always be included
    options.add(correctAnswer);

    // Add other colors
    for (int i = 0; i < colors.length; i++) {
      if (i != correctAnswer && options.length < 4) {
        options.add(i);
      }
    }

    // Shuffle options
    options.shuffle();

    currentOptions = options;
  }

  // Check answer
  void checkAnswer(int selectedColor) {
    if (answerSelected) {
      return;
    }

    answerSelected = true;

    int correctAnswer = questions[questionNumber];

    if (selectedColor == correctAnswer) {
      setState(() {
        score++;
        message = '✓ CORRECT!';
      });
    } else {
      setState(() {
        message = '✕ WRONG!';
      });
    }

    // Automatically go to next question
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;

      // If questions are still remaining
      if (questionNumber < questions.length - 1) {
        setState(() {
          questionNumber++;
          message = '';
          answerSelected = false;

          createOptions();
        });
      } else {
        // Open Result Page after question 10
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResultPage(score: score, totalQuestions: questions.length),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int correctAnswer = questions[questionNumber];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),

      appBar: AppBar(
        title: const Text('Coloriboo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Question number and score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${questionNumber + 1} / 10',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Question
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        colorNames[correctAnswer],
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: colors[correctAnswer],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Correct / Wrong message
                  SizedBox(
                    height: 35,
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: message == '✓ CORRECT!'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Four answer boxes
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,

                      childAspectRatio: constraints.maxWidth < 500 ? 1.5 : 2.2,

                      physics: const NeverScrollableScrollPhysics(),

                      children: [
                        colorBox(currentOptions[0]),
                        colorBox(currentOptions[1]),
                        colorBox(currentOptions[2]),
                        colorBox(currentOptions[3]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Full color clickable box
  Widget colorBox(int colorIndex) {
    return GestureDetector(
      onTap: () {
        checkAnswer(colorIndex);
      },

      child: Container(
        decoration: BoxDecoration(
          color: colors[colorIndex],
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
