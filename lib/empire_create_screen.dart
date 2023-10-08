import 'package:flutter/material.dart';
import 'globals.dart'; // Import the Empire class

class EmpireCreateScreen extends StatefulWidget {
  @override
  EmpireCreateScreenState createState() => EmpireCreateScreenState();
}

class EmpireCreateScreenState extends State<EmpireCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  String generatedID = generateUniqueEmpireId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Empire'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Empire Name'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(generatedID),
                subtitle: const Text("Azonosító"),
                trailing: IconButton(
                    onPressed: () => setState(() {
                          generatedID = generateUniqueEmpireId();
                        }),
                    icon: const Icon(Icons.refresh)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Create the Empire object using the input values
                Empire newEmpire = Empire(
                  id: generatedID, // Generate a unique ID for the empire
                  name: _nameController.text,
                  creatorID: userProfile!.uid,
                  creatorName: userProfile!.username,
                  joinedMembers: {}, // Initialize as an empty map
                  cities: {}, // Initialize as an empty map
                  coatOfArmsColor: "", // Parse the int or default to 0
                );

                // You can save the newEmpire object or use it as needed
                // For example, you might want to send it to an API or store it locally.
                print('New Empire Created: ${newEmpire.toJsonString()}');
              },
              child: const Text('Create Empire'),
            ),
          ],
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
