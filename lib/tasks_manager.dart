import 'dart:math';

import 'package:flutter/material.dart';
import 'globals.dart';

class QuizPage extends StatefulWidget {
  final List<Task> tasks;
  final Function(double) onQuizCompleted;

  const QuizPage(
      {super.key, required this.tasks, required this.onQuizCompleted});

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int questionsToAsk = 0;

  @override
  void initState() {
    questionsToAsk = Random().nextInt(widget.tasks.length - 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
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
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  children: generateAnswers(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> generateAnswers() {
    List<Widget> answers = [
      ...widget.tasks[currentQuestionIndex].goodAnswers.map((option) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              checkAnswer(true);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                option,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        );
      }),
      ...widget.tasks[currentQuestionIndex].wrongAnswers.map((option) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              checkAnswer(false);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                option,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        );
      }),
    ];
    answers.shuffle();
    return answers;
  }

  void checkAnswer(bool isCorrect) {
    if (isCorrect) {
      correctAnswers++;
    }

    if (currentQuestionIndex < questionsToAsk - 1) {
      // Move to the next question
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Quiz completed, calculate percentage and notify the calling code
      double percentage = (correctAnswers / questionsToAsk);
      widget.onQuizCompleted(percentage);
      Navigator.pop(context);
    }
  }
}
