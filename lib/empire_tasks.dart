import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart';

// ignore: must_be_immutable
class AssignmentPage extends StatefulWidget {
  AssignmentPage(this.selectedEmpire, {super.key});
  Empire selectedEmpire;

  @override
  AssignmentPageState createState() => AssignmentPageState();
}

class AssignmentPageState extends State<AssignmentPage> {
  @override
  Widget build(BuildContext context) {
    loadedAssignments.sort(
      (a, b) => b.lastUpdated.compareTo(a.lastUpdated),
    );
    loadedAssignments.sort(
      (a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0),
    );
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.selectedEmpire.creatorID == userProfile!.uid)
                ElevatedButton(
                  onPressed: () async {
                    await showNewAssignmentDialog(
                        context, widget.selectedEmpire);
                    setState(() {});
                  },
                  child: const Text('Feladatsor hozzáadása'),
                ),
              if (loadedAssignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Nincs feladat a birodalomhoz rendelve",
                    textAlign: TextAlign.center,
                  ),
                ),
              if (loadedAssignments.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: loadedAssignments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(loadedAssignments[index].name),
                        subtitle: Text(
                            "${loadedAssignments[index].tasks.length} feladat"),
                        trailing: Switch(
                          value: loadedAssignments[index].isActive,
                          onChanged: (value) {
                            setState(() {
                              loadedAssignments[index].isActive = value;
                              loadedAssignments[index].lastUpdated =
                                  DateTime.now();
                            });
                          },
                        ),
                        leading: Icon(
                          Icons.circle,
                          color: getColorBasedOnDifficulty(
                              loadedAssignments[index].getDifficulties()),
                        ),
                        onTap: () => _showAssignmentDetailsDialog(
                            context, loadedAssignments[index]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showNewAssignmentDialog(
    BuildContext context, Empire selectedEmpire) async {
  TextEditingController nameController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create New Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Assignment Name'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String assignmentName = nameController.text;
              // Validate and handle the assignment name (you can add more validation logic)
              if (assignmentName.isNotEmpty) {
                loadedAssignments.add(
                  Assignment(
                      name: nameController.text.trim(),
                      tasks: [],
                      ownerId: userProfile!.uid,
                      creatorName: userProfile!.username,
                      isActive: false,
                      assignedEmpires:
                          selectedEmpire.id != null ? [selectedEmpire.id!] : [],
                      lastUpdated: DateTime.now()),
                );
                Navigator.of(context).pop(); // Close the dialog
              } else {
                // Show error message if the assignment name is empty
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Error'),
                      content: const Text('Assignment name cannot be empty.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Close the error dialog
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
}

void _showAssignmentDetailsDialog(BuildContext context, Assignment assignment) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(assignment.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              tileColor:
                  getColorBasedOnDifficulty(assignment.getDifficulties()),
              subtitle: const Text(
                'Difficulty Level',
                style: TextStyle(color: Colors.white),
              ),
              title: Text("${assignment.getDifficulties()}",
                  style: const TextStyle(color: Colors.white)),
            ),
            ListTile(
              subtitle: const Text('Creator'),
              title: Text(assignment.creatorName),
            ),
            ListTile(
              subtitle: const Text('# of Questions'),
              title: Text('${assignment.tasks.length}'),
            ),
            ListTile(
              subtitle: const Text('Is Visible To Students'),
              title: Text(assignment.isActive ? "Yes" : "No"),
            ),
            ListTile(
              subtitle: const Text('Last Update'),
              title: Text(
                  "${DateFormat.yMMMMd().format(assignment.lastUpdated)} ${DateFormat.Hms().format(assignment.lastUpdated)}"),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              // TODO: Implement edit functionality
              // You can navigate to an edit screen or perform editing logic here
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Edit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: Implement delete functionality
              // You can show a confirmation dialog before deleting
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
