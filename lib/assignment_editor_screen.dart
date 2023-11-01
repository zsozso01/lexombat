import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'globals.dart';
import 'package:toggle_switch/toggle_switch.dart';

class AssignmentEditorScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentEditorScreen({super.key, required this.assignment});

  @override
  AssignmentEditorScreenState createState() => AssignmentEditorScreenState();
}

class AssignmentEditorScreenState extends State<AssignmentEditorScreen> {
  bool _isEdited = false;
  final TextEditingController _nameController = TextEditingController();
  late Assignment tempAssignment;
  @override
  void initState() {
    undoChanges();
    super.initState();
  }

  void undoChanges() {
    _isEdited = false;
    _nameController.text = widget.assignment.name;
    tempAssignment = Assignment.fromJson(widget.assignment.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translations["editAssignment"]),
        actions: <Widget>[
          if (_isEdited) ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                loadedAssignments[widget.assignment.id] = tempAssignment;
                FirebaseFirestore.instance
                    .collection("assignments")
                    .doc(widget.assignment.id)
                    .update(tempAssignment.toJson());
                setState(() {
                  _isEdited = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                undoChanges();
                setState(() {});
              },
            )
          ] // Hide the save button if not edited
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(translations["assignmentName"]),
            TextField(
              controller: _nameController,
              onChanged: (text) {
                setState(() {
                  _isEdited = true;
                  tempAssignment.name = text;
                });
              },
            ),
            // ... Add more fields for editing other assignment properties here

            const SizedBox(height: 20),
            Text(translations["task"] + ":"),
            Expanded(
              child: ListView.builder(
                itemCount: tempAssignment.tasks.length,
                itemBuilder: (context, index) {
                  Task task = tempAssignment.tasks[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Text(
                        "${index + 1}.",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      title: Text(
                        task.question,
                      ),
                      subtitle: Text(task.isTrueOrFalse
                          ? translations[task.goodAnswers.first]
                          : generateAnswerString(
                              task.goodAnswers, task.wrongAnswers)),
                      onLongPress: () =>
                          showDeleteTaskConfirmationDialog(context, index),
                      onTap: () async {
                        await showEditTaskDialog(context, task, (Task task) {
                          // Handle the added task here
                          // You can add the task to your list of tasks or perform any other action.
                          // For example:
                          tempAssignment.tasks[index] = task;
                          // Or update your database with the new task.
                        });
                        setState(() {
                          _isEdited = true;
                        });
                      },
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            color: getColorBasedOnDifficulty(
                                task.calculateTaskDifficulty().toDouble()),
                            size: 40,
                          ),
                          Text(
                            task.calculateTaskDifficulty().toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      // ... Add more task details to display
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await showAddTaskDialog(context, (Task task) {
                  // Handle the added task here
                  // You can add the task to your list of tasks or perform any other action.
                  // For example:
                  tempAssignment.tasks.add(task);
                  // Or update your database with the new task.
                });
                setState(() {
                  _isEdited = true;
                });
              },
              child: Text(translations["addTask"]),
            )
          ],
        ),
      ),
    );
  }

  String generateAnswerString(
      List<String> goodAnswers, List<String> wrongAnswers) {
    String result = '${translations["goodAnswers"]}:\n';
    result += goodAnswers.map((answer) => '- $answer\n').join();
    result += '${translations["wrongAnswers"]}:\n';
    result += wrongAnswers.map((answer) => '- $answer\n').join();
    return result;
  }

  Future<void> showAddTaskDialog(
      BuildContext context, Function(Task) onTaskAdded) async {
    TextEditingController questionController = TextEditingController();
    List<String> goodAnswers = [""];
    List<String> wrongAnswers = [""];
    double difficultyMultiplier = 1.0;
    bool isTrueOrFalse = false;
    bool isTrue = true;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(translations["addTask"]),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: questionController,
                    decoration:
                        InputDecoration(labelText: translations["question"]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(translations["isTrueOrFalse"]),
                        Switch(
                          value: isTrueOrFalse,
                          onChanged: (value) {
                            setState(() {
                              isTrueOrFalse = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 3,
                  ),
                  if (isTrueOrFalse)
                    ToggleSwitch(
                      initialLabelIndex: isTrue ? 0 : 1,
                      totalSwitches: 2,
                      labels: [translations["true"], translations["false"]],
                      onToggle: (index) {
                        setState(
                          () {
                            isTrue = index == 0;
                          },
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('${translations["goodAnswers"]}:'),
                          Column(
                            children: goodAnswers
                                .asMap()
                                .entries
                                .map((entry) => ListTile(
                                      title: TextField(
                                        onChanged: (text) {
                                          setState(() {
                                            goodAnswers[entry.key] = text;
                                          });
                                        },
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            goodAnswers.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    ))
                                .toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  goodAnswers.add('');
                                });
                              },
                              child: Text(translations["addGoodAnswer"]),
                            ),
                          ),
                          Text('${translations["wrongAnswers"]}:'),
                          Column(
                            children: wrongAnswers
                                .asMap()
                                .entries
                                .map((entry) => ListTile(
                                      title: TextField(
                                        onChanged: (text) {
                                          setState(() {
                                            wrongAnswers[entry.key] = text;
                                          });
                                        },
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            wrongAnswers.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    ))
                                .toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  wrongAnswers.add('');
                                });
                              },
                              child: Text(translations["addWrongAnswer"]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(
                    thickness: 3,
                  ),
                  Text(translations["difficultyMultiplier"] + ":"),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Slider(
                      value: difficultyMultiplier,
                      onChanged: (value) {
                        setState(() {
                          difficultyMultiplier = value;
                        });
                      },
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      label: difficultyMultiplier.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(translations["cancel"]),
              ),
              ElevatedButton(
                onPressed: () {
                  String question = questionController.text.trim();
                  if (question.isNotEmpty &&
                      (isTrueOrFalse || goodAnswers.isNotEmpty)) {
                    Task newTask = Task(
                      question: question,
                      isTrueOrFalse: isTrueOrFalse,
                      goodAnswers: isTrueOrFalse
                          ? [isTrue ? "true" : "false"]
                          : goodAnswers
                              .where((answer) => answer.isNotEmpty)
                              .toList(),
                      wrongAnswers: isTrueOrFalse
                          ? [!isTrue ? "true" : "false"]
                          : wrongAnswers
                              .where((answer) => answer.isNotEmpty)
                              .toList(),
                      difficultyMultiplier: difficultyMultiplier,
                    );
                    onTaskAdded(newTask);
                    Navigator.of(context).pop();
                  } else {
                    // Show error message if question is empty or there are no good answers for multiple-choice questions.
                    // You can customize this part according to your needs.
                    // For example, you can show a SnackBar or another AlertDialog with the error message.
                    Fluttertoast.showToast(msg: translations["taskEditError"]);
                  }
                },
                child: Text(translations["addTask"]),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> showEditTaskDialog(
      BuildContext context, Task task, Function(Task) onTaskEdited) async {
    TextEditingController questionController =
        TextEditingController(text: task.question);
    List<String> goodAnswers = List.from(task.goodAnswers);
    List<String> wrongAnswers = List.from(task.wrongAnswers);
    double difficultyMultiplier = task.difficultyMultiplier;
    bool isTrueOrFalse = task.isTrueOrFalse;
    bool isTrue = task.isTrueOrFalse ? task.goodAnswers.first == "true" : false;
    List<TextEditingController> goodAnswerControllers = goodAnswers
        .map((answer) => TextEditingController(text: answer))
        .toList();
    List<TextEditingController> wrongAnswerControllers = wrongAnswers
        .map((answer) => TextEditingController(text: answer))
        .toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(translations["editTask"]),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: questionController,
                    decoration:
                        InputDecoration(labelText: translations["question"]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(translations["isTrueOrFalse"]),
                        Switch(
                          value: isTrueOrFalse,
                          onChanged: (value) {
                            setState(() {
                              isTrueOrFalse = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 3,
                  ),
                  if (isTrueOrFalse)
                    ToggleSwitch(
                      initialLabelIndex: isTrue ? 0 : 1,
                      totalSwitches: 2,
                      labels: [translations["true"], translations["false"]],
                      onToggle: (index) {
                        setState(() {
                          isTrue = index == 0;
                        });
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(translations["goodAnswers"] + ":"),
                          Column(
                            children: goodAnswers
                                .asMap()
                                .entries
                                .map((entry) => ListTile(
                                      title: TextField(
                                        controller: entry.key <
                                                goodAnswerControllers.length
                                            ? goodAnswerControllers[entry.key]
                                            : null,
                                        onChanged: (text) {
                                          setState(() {
                                            goodAnswers[entry.key] = text;
                                          });
                                        },
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            goodAnswers.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    ))
                                .toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  goodAnswers.add('');
                                });
                              },
                              child: Text(translations["addGoodAnswer"]),
                            ),
                          ),
                          Text(translations["wrongAnswers"] + ":"),
                          Column(
                            children: wrongAnswers
                                .asMap()
                                .entries
                                .map((entry) => ListTile(
                                      title: TextField(
                                        controller: entry.key <
                                                wrongAnswerControllers.length
                                            ? wrongAnswerControllers[entry.key]
                                            : null,
                                        onChanged: (text) {
                                          setState(() {
                                            wrongAnswers[entry.key] = text;
                                          });
                                        },
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            wrongAnswers.removeAt(entry.key);
                                          });
                                        },
                                      ),
                                    ))
                                .toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  wrongAnswers.add('');
                                });
                              },
                              child: Text(translations["addWrongAnswer"]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(
                    thickness: 3,
                  ),
                  Text(translations["difficultyMultiplier"] + ":"),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Slider(
                      value: difficultyMultiplier,
                      onChanged: (value) {
                        setState(() {
                          difficultyMultiplier = value;
                        });
                      },
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      label: difficultyMultiplier.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(translations["cancel"]),
              ),
              ElevatedButton(
                onPressed: () {
                  String question = questionController.text.trim();
                  if (question.isNotEmpty &&
                      (isTrueOrFalse || goodAnswers.isNotEmpty)) {
                    Task editedTask = Task(
                      question: question,
                      isTrueOrFalse: isTrueOrFalse,
                      goodAnswers: isTrueOrFalse
                          ? [isTrue ? "true" : "false"]
                          : goodAnswers
                              .where((answer) => answer.isNotEmpty)
                              .toList(),
                      wrongAnswers: isTrueOrFalse
                          ? [!isTrue ? "true" : "false"]
                          : wrongAnswers
                              .where((answer) => answer.isNotEmpty)
                              .toList(),
                      difficultyMultiplier: difficultyMultiplier,
                    );
                    onTaskEdited(editedTask);
                    Navigator.of(context).pop();
                  } else {
                    Fluttertoast.showToast(msg: translations["taskEditError"]);
                  }
                },
                child: Text(translations["saveChanges"]),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> showDeleteTaskConfirmationDialog(
      BuildContext context, int index) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translations["deleteTask"]),
          content: Text(translations["deleteTaskConfirmation"]),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(translations["cancel"]),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tempAssignment.tasks.removeAt(index);
                  _isEdited = true;
                });
                Navigator.of(context).pop();
              },
              child: Text(translations["delete"]),
            ),
          ],
        );
      },
    );
  }
}
