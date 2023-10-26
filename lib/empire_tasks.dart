// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lexombat/assignment_editor_screen.dart';
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
  void initState() {
    loadAssignments();
    super.initState();
  }

  void loadAssignments() {
    FirebaseFirestore.instance
        .collection("assignments")
        .where("assignedEmpires", arrayContains: widget.selectedEmpire.id)
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.removed) {
          loadedAssignments.remove(docChange.doc.id);
        } else {
          loadedAssignments[docChange.doc.id] =
              Assignment.fromJson(docChange.doc.data()!);
        }
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Convert values of the map to a list
    List<Assignment> assignmentsList = loadedAssignments.values
        .where((element) =>
            element.assignedEmpires.contains(widget.selectedEmpire.id))
        .toList();

    // Sort the list by lastUpdated (latest first)
    assignmentsList.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    // Sort the list by isActive (true values first)
    assignmentsList
        .sort((a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0));
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
              if (assignmentsList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Nincs feladatsor a birodalomhoz rendelve",
                    textAlign: TextAlign.center,
                  ),
                ),
              if (assignmentsList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: loadedAssignments.length,
                    itemBuilder: (context, index) {
                      Assignment currentAssignment = assignmentsList[index];
                      return AnimatedOpacity(
                        opacity: currentAssignment.isActive ? 1.0 : 0.5,
                        duration: const Duration(
                            milliseconds:
                                300), // Set the duration of the opacity animation
                        child: ListTile(
                          title: Text(currentAssignment.name),
                          subtitle:
                              Text("${currentAssignment.tasks.length} feladat"),
                          trailing: Switch(
                            value: currentAssignment.isActive,
                            onChanged: (value) {
                              setState(() {
                                currentAssignment.isActive = value;
                                currentAssignment.lastUpdated = DateTime.now();
                              });
                              FirebaseFirestore.instance
                                  .collection("assignments")
                                  .doc(currentAssignment.id)
                                  .update(currentAssignment.toJson());
                            },
                          ),
                          leading: Icon(
                            Icons.circle,
                            color: getColorBasedOnDifficulty(
                                currentAssignment.getDifficulties()),
                          ),
                          onTap: () async {
                            await _showAssignmentDetailsDialog(
                                context, currentAssignment);
                            setState(() {});
                          },
                        ),
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
            onPressed: () async {
              String assignmentName = nameController.text;
              // Validate and handle the assignment name (you can add more validation logic)
              if (assignmentName.isEmpty) {
                Fluttertoast.showToast(msg: "Assignment name cannot be empty");
                return;
              }
              String tempID =
                  "${userProfile!.uid} - ${nameController.text.trim()}";
              if ((await FirebaseFirestore.instance
                      .collection("assignments")
                      .doc(tempID)
                      .get())
                  .exists) {
                Fluttertoast.showToast(
                    msg: "Assignment name cannot exist already");
                return;
              }
              loadedAssignments[tempID] = Assignment(
                  id: tempID,
                  name: nameController.text.trim(),
                  tasks: [],
                  ownerId: userProfile!.uid,
                  creatorName: userProfile!.username,
                  isActive: false,
                  assignedEmpires:
                      selectedEmpire.id != null ? [selectedEmpire.id!] : [],
                  lastUpdated: DateTime.now());
              await FirebaseFirestore.instance
                  .collection("assignments")
                  .doc(tempID)
                  .set(loadedAssignments[tempID]!.toJson());
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
}

Future<void> _showAssignmentDetailsDialog(
    BuildContext context, Assignment assignment) async {
  await showDialog(
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
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          AssignmentEditorScreen(assignment: assignment)),
                );
                Navigator.pop(context);
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
      });
}
