// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:lexombat/empire_create_screen.dart';
import 'globals.dart';

class Empire {
  final String id;
  final String name;

  Empire({required this.id, required this.name});
}

class EmpireManagerScreen extends StatefulWidget {
  const EmpireManagerScreen({super.key});

  @override
  EmpireManagerScreenState createState() => EmpireManagerScreenState();
}

class EmpireManagerScreenState extends State<EmpireManagerScreen> {
  List<Empire> _joinedEmpires = [];

  void _joinEmpire() {
    //TODO: Join empire ... (same code as provided in the previous response)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empire Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => EmpireCreateScreen())),
              child: const Text('Create Empire'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _joinEmpire,
              child: const Text('Join Empire'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _joinedEmpires.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(_joinedEmpires[index].name),
                    subtitle: Text('ID: ${_joinedEmpires[index].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
