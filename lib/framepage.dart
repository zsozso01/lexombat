import 'package:flutter/material.dart';
import 'package:lexombat/empire_tasks.dart';
import 'globals.dart';

// ignore: must_be_immutable
class FramePage extends StatefulWidget {
  FramePage({super.key, required this.selectedEmpire});
  Empire selectedEmpire;
  @override
  FramePageState createState() => FramePageState();
}

class FramePageState extends State<FramePage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final List<Widget?> _pages = [
      // Add your different content widgets here for different tabs
      const Text("Csata"),
      const Text("Város"),
      AssignmentPage(widget.selectedEmpire),
    ];
    List<String> coatOfArmsString = widget.selectedEmpire.coatOfArms.split(" ");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedEmpire.name),
        actions: [
          generateCoatOfArms(
              int.parse(coatOfArmsString[1]),
              int.parse(coatOfArmsString[0]),
              int.parse(coatOfArmsString[2]),
              0.4),
          IconButton(
              onPressed: () => showLogout(context),
              icon: const Icon(Icons.login)),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_kabaddi),
            label: translations["fight"],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_city),
            label: translations["town"],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.question_answer),
            label: translations["quests"],
          ),
        ],
      ),
    );
  }
}

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Page One Content'),
    );
  }
}
