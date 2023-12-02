// ignore_for_file: use_build_context_synchronously

import 'dart:async';

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
    _loadAssignments();
    super.initState();
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? assigmentSnapshot;

  Future<void> _loadAssignments() async {
    assigmentSnapshot = await loadAssignments(widget.selectedEmpire, true);
    while (loadedAssignments.values
        .where((element) => element.assignedEmpires.contains(widget.selectedEmpire.id) && element.isActive)
        .toList()
        .isEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (assigmentSnapshot != null) {
      assigmentSnapshot!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert values of the map to a list
    List<Assignment> assignmentsList =
        loadedAssignments.values.where((element) => element.assignedEmpires.contains(widget.selectedEmpire.id)).toList();

    // Sort the list by lastUpdated (latest first)
    assignmentsList.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    // Sort the list by isActive (true values first)
    assignmentsList.sort((a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0));
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.selectedEmpire.creatorID == userProfile!.uid)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 60,
                      icon: const Icon(
                        Icons.add_circle_rounded,
                      ),
                      onPressed: () async {
                        await showNewAssignmentDialog(context, widget.selectedEmpire);
                        setState(() {});
                      },
                    ),
                    IconButton(
                      iconSize: 60,
                      icon: const Icon(
                        Icons.download_for_offline_rounded,
                      ),
                      onPressed: () async {
                        await showAssignmentsImportPopup(context, userProfile!.uid, widget.selectedEmpire);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              if (assignmentsList.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    translations["noAssignmentsMessage"],
                    textAlign: TextAlign.center,
                  ),
                ),
              if (assignmentsList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: assignmentsList.where((element) => widget.selectedEmpire.creatorID == userProfile!.uid || element.isActive).length,
                    itemBuilder: (context, index) {
                      Assignment currentAssignment =
                          assignmentsList.where((element) => widget.selectedEmpire.creatorID == userProfile!.uid || element.isActive).toList()[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedOpacity(
                          opacity: currentAssignment.isActive ? 1.0 : 0.5,
                          duration: const Duration(milliseconds: 300), // Set the duration of the opacity animation
                          child: ListTile(
                            title: Text(currentAssignment.name),
                            subtitle: Text("${currentAssignment.tasks.length} ${translations["task"]}"),
                            trailing: widget.selectedEmpire.creatorID != userProfile!.uid
                                ? null
                                : Switch(
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
                              color: getColorBasedOnDifficulty(currentAssignment.getDifficulties()),
                            ),
                            onTap: widget.selectedEmpire.creatorID != userProfile!.uid
                                ? null
                                : () async {
                                    await _showAssignmentDetailsDialog(context, currentAssignment);
                                    setState(() {});
                                  },
                          ),
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

  Future<void> showRemoveAssignmentConfirmationDialog(BuildContext context, String id) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translations["deleteAssignmentTitle"]),
          content: Text(translations["deleteAssignmentConfirmation"]),
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
                  loadedAssignments[id]?.assignedEmpires.remove(widget.selectedEmpire.id);
                  if (loadedAssignments[id]!.assignedEmpires.isEmpty) {
                    FirebaseFirestore.instance.collection("assignments").doc(id).delete();
                    loadedAssignments.remove(id);
                  } else {
                    FirebaseFirestore.instance.collection("assignments").doc(id).update(loadedAssignments[id]!.toJson());
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(translations["confirmDelete"]),
            ),
          ],
        );
      },
    );
  }

  Future<void> showNewAssignmentDialog(BuildContext context, Empire selectedEmpire) async {
    TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(translations["createAssignmentTitle"]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: translations["assignmentName"]),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(translations["cancel"]),
            ),
            ElevatedButton(
              onPressed: () async {
                String assignmentName = nameController.text;
                // Validate and handle the assignment name (you can add more validation logic)
                if (assignmentName.isEmpty) {
                  Fluttertoast.showToast(msg: translations["assignmentNameEmptyError"]);
                  return;
                }
                String tempID = "${userProfile!.uid} - ${nameController.text.trim()}";
                if ((await FirebaseFirestore.instance.collection("assignments").doc(tempID).get()).exists) {
                  Fluttertoast.showToast(msg: translations["assignmentNameExistsError"]);
                  return;
                }
                loadedAssignments[tempID] = Assignment(
                    id: tempID,
                    name: nameController.text.trim(),
                    tasks: [],
                    ownerId: userProfile!.uid,
                    creatorName: userProfile!.username,
                    isActive: false,
                    assignedEmpires: selectedEmpire.id != null ? [selectedEmpire.id!] : [],
                    lastUpdated: DateTime.now());
                await FirebaseFirestore.instance.collection("assignments").doc(tempID).set(loadedAssignments[tempID]!.toJson());
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(translations["create"]),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAssignmentDetailsDialog(BuildContext context, Assignment assignment) async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(assignment.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    tileColor: getColorBasedOnDifficulty(assignment.getDifficulties()),
                    subtitle: Text(
                      translations["difficultyLevel"],
                      style: const TextStyle(color: Colors.white),
                    ),
                    title: Text("${assignment.getDifficulties()}", style: const TextStyle(color: Colors.white)),
                  ),
                  ListTile(
                    subtitle: Text(translations["creator"]),
                    title: Text(assignment.creatorName),
                  ),
                  ListTile(
                    subtitle: Text(translations["numberOfQuestions"]),
                    title: Text('${assignment.tasks.length}'),
                  ),
                  ListTile(
                    subtitle: Text(translations["isVisibleToStudents"]),
                    title: Text(assignment.isActive ? translations["yes"] : translations["no"]),
                  ),
                  ListTile(
                    subtitle: Text(translations["lastUpdate"]),
                    title: Text("${DateFormat.yMMMMd().format(assignment.lastUpdated)} ${DateFormat.Hms().format(assignment.lastUpdated)}"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(translations["close"]),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AssignmentEditorScreen(assignment: assignment)),
                  );
                  Navigator.pop(context);
                },
                child: Text(translations["edit"]),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await showRemoveAssignmentConfirmationDialog(context, assignment.id);
                  // You can show a confirmation dialog before deleting
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(assignment.assignedEmpires.length == 1 ? translations["delete"] : translations["remove"]),
              ),
            ],
          );
        });
  }

  Future<void> showAssignmentsImportPopup(BuildContext context, String userProfileId, Empire selectedEmpire) async {
    QuerySnapshot<Map<String, dynamic>> assignmentsSnapshot =
        await FirebaseFirestore.instance.collection('assignments').where('ownerId', isEqualTo: userProfileId).get();

    List<DocumentSnapshot<Map<String, dynamic>>> assignments =
        assignmentsSnapshot.docs.where((element) => !element.data()["assignedEmpires"].contains(selectedEmpire.id)).toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedAssignment;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(translations["importAssignmentTitle"]),
            content: assignments.isEmpty
                ? Text(translations["noAssignmentsAvailable"])
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: assignments.length,
                      itemBuilder: (BuildContext context, int index) {
                        Assignment assignment = Assignment.fromJson(assignments[index].data()!);

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(assignment.name),
                            shape: selectedAssignment == index ? Border.all() : null,
                            subtitle: Text(
                                '${translations["difficulty"]}: ${assignment.getDifficulties()}\n${translations["task"]}: ${assignment.tasks.length}'),
                            onTap: () {
                              selectedAssignment = index;
                              setState(
                                () {},
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(translations["cancel"]),
                ),
              ),
              if (selectedAssignment != null) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      Assignment tempAssignment = Assignment.fromJson(assignments[selectedAssignment!].data()!);
                      tempAssignment.assignedEmpires = [selectedEmpire.id!];
                      String tempId = "${tempAssignment.id} ${DateTime.now().millisecondsSinceEpoch}";
                      tempAssignment.id = tempId;
                      await FirebaseFirestore.instance.collection("assignments").doc(tempId).set(tempAssignment.toJson());
                      Navigator.of(context).pop();
                      // Logic for copying task to empire
                    },
                    child: Text(translations["duplicateAndImportTask"]),
                  ),
                ),
                /*Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("assignments")
                          .doc(assignments[selectedAssignment!].id)
                          .update({
                        "assignedEmpires":
                            FieldValue.arrayUnion([selectedEmpire.id])
                      });
                      Navigator.of(context).pop();
                      // Logic for assigning task to empire
                    },
                    child: Text(translations["assignTask"]),
                  ),
                ),*/
              ]
            ],
          );
        });
      },
    );
  }
}
