// ignore_for_file: prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lexombat/empire_create_screen.dart';
import 'package:lexombat/framepage.dart';
import 'globals.dart';

class EmpireManagerScreen extends StatefulWidget {
  const EmpireManagerScreen({super.key});

  @override
  EmpireManagerScreenState createState() => EmpireManagerScreenState();
}

class EmpireManagerScreenState extends State<EmpireManagerScreen> {
  void _joinEmpire() {
    //TODO: Join empire ... (same code as provided in the previous response)
  }

  @override
  void initState() {
    super.initState();
    getEmpires();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(translations["empireManager"]),
          actions: [
            IconButton(
                onPressed: () => showLogout(context),
                icon: const Icon(Icons.login))
          ],
        ),
        body: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          iconSize: 50,
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    const EmpireCreateScreen()));
                            getEmpires();
                          },
                          icon: const Icon(
                            Icons.add_circle,
                          )),
                      IconButton(
                          iconSize: 50,
                          onPressed: () {
                            TextEditingController _textController =
                                TextEditingController();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(translations["joinEmpire"]),
                                  content: TextField(
                                    controller: _textController,
                                    decoration: InputDecoration(
                                        labelText:
                                            translations["empireIdentifier"]),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(translations["cancel"]),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        String identifier =
                                            _textController.text.trim();
                                        if (identifier.isEmpty) {
                                          return;
                                        }
                                        var snapshot = await FirebaseFirestore
                                            .instance
                                            .collection("empires")
                                            .doc(identifier)
                                            .get();
                                        bool alreadyJoinedEmpire = [
                                          ...joinedEmpires.keys,
                                          ...createdEmpires.keys
                                        ].contains(identifier);
                                        if (!alreadyJoinedEmpire &&
                                            snapshot.exists) {
                                          await FirebaseFirestore.instance
                                              .collection("empires")
                                              .doc(identifier)
                                              .update({
                                            "joinedMembers":
                                                FieldValue.arrayUnion(
                                                    [userProfile!.uid])
                                          });
                                          Fluttertoast.showToast(
                                              msg: translations[
                                                  "successfulJoin"]);
                                          getEmpires();
                                        } else if (alreadyJoinedEmpire) {
                                          Fluttertoast.showToast(
                                              msg: translations[
                                                  "alreadyMember"]);
                                        } else {
                                          Fluttertoast.showToast(
                                              msg:
                                                  "${translations["notFound"]} $identifier");
                                        }
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(translations["join"]),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.add_home,
                          )),
                      IconButton(
                          iconSize: 50,
                          onPressed: () => getEmpires(),
                          icon: const Icon(
                            Icons.refresh,
                          )),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          createdEmpires.values.length + joinedEmpires.length,
                      itemBuilder: (BuildContext context, int index) {
                        List<String> coatOfArmsString = [
                          ...createdEmpires.values,
                          ...joinedEmpires.values
                        ].toList()[index].coatOfArms.split(" ");
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                              onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => FramePage(
                                                selectedEmpire: [
                                              ...createdEmpires.values,
                                              ...joinedEmpires.values
                                            ][index])),
                                  ),
                              tileColor: index >= createdEmpires.values.length
                                  ? const Color.fromARGB(29, 158, 158, 158)
                                  : const Color.fromARGB(24, 76, 175, 79),
                              shape: Border.all(),
                              title: Text(index >= createdEmpires.values.length
                                  ? "${joinedEmpires.values.toList()[0].name} - ${translations["membersCount"]}: ${joinedEmpires.values.toList()[0].joinedMembers.length}"
                                  : "${createdEmpires.values.toList()[index].name} - ${translations["membersCount"]}: ${createdEmpires.values.toList()[index].joinedMembers.length}"),
                              subtitle: Text(index >=
                                      createdEmpires.values.length
                                  ? "${translations["identifier"]}: ${joinedEmpires.keys.toList()[0]}"
                                  : "${translations["identifier"]}: ${createdEmpires.keys.toList()[index]}"),
                              trailing: generateCoatOfArms(
                                  int.parse(coatOfArmsString[1]),
                                  int.parse(coatOfArmsString[0]),
                                  int.parse(coatOfArmsString[2]),
                                  0.4)),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  bool isLoading = false;
  Future<void> getEmpires() async {
    setState(() {
      isLoading = true;
    });
    var snapshots = await FirebaseFirestore.instance
        .collection("empires")
        .where("creatorID", isEqualTo: userProfile!.uid)
        .get();
    for (var doc in snapshots.docs) {
      createdEmpires[doc.id] = Empire.fromJson(doc.data(), doc.id);
    }
    snapshots = await FirebaseFirestore.instance
        .collection("empires")
        .where("joinedMembers", arrayContains: userProfile!.uid)
        .get();
    for (var doc in snapshots.docs) {
      joinedEmpires[doc.id] = Empire.fromJson(doc.data(), doc.id);
    }
    setState(() {
      isLoading = false;
    });
  }
}
