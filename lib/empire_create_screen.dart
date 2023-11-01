import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'globals.dart'; // Import the translations map

class EmpireCreateScreen extends StatefulWidget {
  const EmpireCreateScreen({super.key});

  @override
  EmpireCreateScreenState createState() => EmpireCreateScreenState();
}

class EmpireCreateScreenState extends State<EmpireCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  String generatedID = generateUniqueEmpireId();
  int selectedIcon = 0;
  int selectedIconColor = 0;
  int selectedBackgroundColor = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translations["createEmpire"]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _nameController,
                  decoration:
                      InputDecoration(labelText: translations["empireName"]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(generatedID),
                  subtitle: Text(translations["identifier"]),
                  trailing: IconButton(
                    onPressed: () => setState(() {
                      generatedID = generateUniqueEmpireId();
                    }),
                    icon: Icon(Icons.refresh),
                  ),
                ),
              ),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: coatOfArmsIcons.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = index;
                          });
                        },
                        child: Icon(
                          coatOfArmsIcons[index],
                          size: 50,
                          color: selectedIcon == index
                              ? Colors.blue // Color when selected
                              : Colors.grey, // Color when not selected
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: coatOfArmsColors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIconColor = index;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          color: coatOfArmsColors[index],
                          child: selectedIconColor == index
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: coatOfArmsColors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBackgroundColor = index;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          color: coatOfArmsColors[index],
                          child: selectedBackgroundColor == index
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              generateCoatOfArms(
                  selectedBackgroundColor, selectedIcon, selectedIconColor, 1),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) {
                    Fluttertoast.showToast(
                        msg: translations["nameRequiredError"]);
                    return;
                  }
                  // Create the Empire object using the input values
                  Empire newEmpire = Empire(
                    name: _nameController.text,
                    creatorID: userProfile!.uid,
                    creatorName: userProfile!.username,
                    joinedMembers: [], // Initialize as an empty map
                    coatOfArms:
                        "$selectedIcon $selectedBackgroundColor $selectedIconColor", // Parse the int or default to 0
                  );
                  while ((await FirebaseFirestore.instance
                          .collection("empires")
                          .doc(generatedID)
                          .get())
                      .exists) {
                    setState(() {
                      generatedID = generateUniqueEmpireId();
                    });
                  }
                  await FirebaseFirestore.instance
                      .collection("empires")
                      .doc(generatedID)
                      .set(newEmpire.toJson());

                  Fluttertoast.showToast(msg: translations["empireCreated"]);
                  Navigator.pop(context);
                },
                child: Text(translations["createEmpire"]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _nameController.dispose();
    super.dispose();
  }
}
