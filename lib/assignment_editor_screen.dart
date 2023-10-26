import 'package:flutter/material.dart';
import 'globals.dart';

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
    // TODO: implement initState
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
        title: const Text('Edit Assignment'),
        actions: <Widget>[
          if (_isEdited) ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                // TODO: Implement save functionality
                loadedAssignments[widget.assignment.id] = tempAssignment;
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
            const Text('Assignment Name:'),
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
            const Text('Tasks:'),
            Expanded(
              child: ListView.builder(
                itemCount: tempAssignment.tasks.length,
                itemBuilder: (context, index) {
                  Task task = tempAssignment.tasks[index];
                  return ListTile(
                    leading: Text("${index + 1}."),
                    title: Text(task.question),
                    // ... Add more task details to display
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                tempAssignment.tasks.add(Task(
                    question: "?",
                    isTrueOrFalse: false,
                    goodAnswers: [],
                    wrongAnswers: [],
                    difficultyMultiplier:
                        1)); // Add a new task to the assignment's tasks list
                setState(() {
                  _isEdited = true;
                });
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
