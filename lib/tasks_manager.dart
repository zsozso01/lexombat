import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'globals.dart';

class QuizPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(double) onQuizCompleted;

  const QuizPage({super.key, required this.tasks, required this.onQuizCompleted});

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int questionsToAsk = 0;
  Color flashColor = Colors.transparent;
  List<Color> correctnessColors = [];

  @override
  void initState() {
    questionsToAsk = clampDouble(Random().nextInt(widget.tasks.length - 1).toDouble(), 1, widget.tasks.length.toDouble()).toInt();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.width / 10,
              child: Row(
                children: List.generate(
                  questionsToAsk,
                  (index) {
                    Color sectionColor;
                    if (index < currentQuestionIndex) {
                      // Question has been answered
                      sectionColor = correctnessColors[index];
                    } else if (index == currentQuestionIndex) {
                      // Current question, not yet answered
                      sectionColor = Colors.blue; // You can set a color for the current question
                    } else {
                      // Future questions
                      sectionColor = Colors.grey; // You can set a color for future questions
                    }

                    return Expanded(
                      child: Container(
                        height: double.infinity,
                        color: sectionColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            Text("${currentQuestionIndex + 1}/$questionsToAsk")
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showConfirmationDialog(context);
          },
        ),
      ),
      body: AnimatedContainer(
        color: flashColor.withOpacity(currentQuestionIndex == correctnessColors.length - 1 ? 0.5 : 0),
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.tasks[currentQuestionIndex].question,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    children: generateAnswers(currentQuestionIndex == correctnessColors.length - 1),
                  ),
                ),
                if (currentQuestionIndex == correctnessColors.length - 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          flashColor = Colors.transparent;
                          if (currentQuestionIndex < questionsToAsk - 1) {
                            currentQuestionIndex++;
                          } else {
                            double percentage = (correctAnswers / questionsToAsk);
                            widget.onQuizCompleted(percentage);
                            Navigator.pop(context);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(currentQuestionIndex == questionsToAsk ? translations["finishQuiz"] : "${translations["nextQuestion"]} >",
                            style: const TextStyle(color: Colors.white, fontSize: 30)),
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

  int lastShuffledIndex = -1;
  String? selectedAnswer;

  List<Widget> generateAnswers(bool revealAnswers) {
    List<Widget> answers = [
      ...widget.tasks[currentQuestionIndex].goodAnswers.map((option) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: revealAnswers
                ? () {}
                : () {
                    checkAnswer(true);
                    selectedAnswer = option;
                  },
            style: revealAnswers
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(selectedAnswer == option ? 1 : 0.7),
                    shape: RoundedRectangleBorder(
                      side: option == selectedAnswer ? const BorderSide(color: Colors.white, width: 2.0) : BorderSide.none,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                ["true", "false"].contains(option) ? translations[option] : option,
                style: TextStyle(fontSize: 22 + (selectedAnswer == option ? 20 : 0)),
              ),
            ),
          ),
        );
      }),
      ...widget.tasks[currentQuestionIndex].wrongAnswers.map((option) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: revealAnswers
                ? () {}
                : () {
                    checkAnswer(false);
                    selectedAnswer = option;
                  },
            style: revealAnswers
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(selectedAnswer == option ? 1 : 0.4),
                    shape: RoundedRectangleBorder(
                      side: option == selectedAnswer ? const BorderSide(color: Colors.white, width: 2.0) : BorderSide.none,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                ["true", "false"].contains(option) ? translations[option] : option,
                style: TextStyle(fontSize: 22 + (selectedAnswer == option ? 20 : 0)),
              ),
            ),
          ),
        );
      }),
    ];
    if (lastShuffledIndex != currentQuestionIndex) {
      answers.shuffle();
      lastShuffledIndex = currentQuestionIndex;
    }
    return answers;
  }

  void checkAnswer(bool isCorrect) {
    if (isCorrect) {
      setState(() {
        flashColor = Colors.green;
        correctAnswers++;
      });
    } else {
      setState(() {
        flashColor = Colors.red;
      });
    }
    correctnessColors.add(flashColor);
  }

  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translations["confirmation"]),
        content: Text(translations["quitQuiz"]),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(translations["no"]),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              // Handle leaving the quiz, for example, pop the route.
              Navigator.pop(context);
            },
            child: Text(translations["yes"]),
          ),
        ],
      ),
    );
  }
}
