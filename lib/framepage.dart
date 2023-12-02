import 'package:flutter/material.dart';
import 'package:lexombat/conquer_page.dart';
import 'package:lexombat/empire_tasks.dart';
import 'package:lexombat/town.dart';
import 'globals.dart';

// ignore: must_be_immutable
class FramePage extends StatefulWidget {
  FramePage({super.key, required this.selectedEmpire});
  Empire selectedEmpire;
  @override
  FramePageState createState() => FramePageState();
}

class FramePageState extends State<FramePage> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // Add your different content widgets here for different tabs
      MapGridPage(
        currentEmpire: widget.selectedEmpire,
      ),
      TownPage(
        currentEmpire: widget.selectedEmpire,
      ),
      AssignmentPage(widget.selectedEmpire),
    ];
    List<String> coatOfArmsString = widget.selectedEmpire.coatOfArms.split(" ");
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.selectedEmpire.name),
          actions: [
            generateCoatOfArms(int.parse(coatOfArmsString[1]), int.parse(coatOfArmsString[0]), int.parse(coatOfArmsString[2]), 0.4),
            /*IconButton(
                onPressed: () => showLogout(context),
                icon: const Icon(Icons.login)),*/
          ],
        ),
        body: TabBarView(children: pages),
        bottomNavigationBar: TabBar(
          indicatorColor: const Color.fromARGB(255, 120, 85, 72),
          labelColor: const Color.fromARGB(255, 120, 85, 72),
          tabs: [
            Tab(
              text: translations["conquer"],
              icon: const Icon(Icons.flag),
            ),
            Tab(
              text: translations["town"],
              icon: const Icon(Icons.location_city),
            ),
            Tab(
              text: translations["quests"],
              icon: const Icon(Icons.question_answer),
            ),
          ],
        ),
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
