import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lexombat/globals.dart';
import 'package:lexombat/tasks_manager.dart';

// ignore: must_be_immutable
class TownPage extends StatefulWidget {
  TownPage({super.key, required this.currentEmpire});
  Empire currentEmpire;

  @override
  TownPageState createState() => TownPageState();
}

List<Building> defaultBuildings = [
  Building(
    name: "Castle",
    level: 1,
    image: "assets/town-buildings/Castle.png",
    resourcesProduced: {},
    costToProduce: {},
    costToUpgrade: {
      "Wood": 45,
      "Stone": 25,
      "Gold": 450,
      "Iron": 15,
    },
    resourceMultiplierPerLevel: 0,
    upgradeCostMultiplierPerLevel: 1.17,
  ),
  Building(
    name: "Lumberjack",
    level: 1,
    image: "assets/town-buildings/Lumberjack's Hut.png",
    resourcesProduced: {"Wood": 8},
    costToProduce: {"Food": 1},
    costToUpgrade: {
      "Wood": 5,
      "Stone": 2,
      "Gold": 50,
    },
    resourceMultiplierPerLevel: 1.13,
    upgradeCostMultiplierPerLevel: 1.11,
  ),
  Building(
    name: "Quarry",
    level: 1,
    image: "assets/town-buildings/The Quarry.png",
    resourcesProduced: {"Stone": 5},
    costToProduce: {"Food": 1},
    costToUpgrade: {"Wood": 2, "Stone": 5, "Gold": 50},
    resourceMultiplierPerLevel: 1.13,
    upgradeCostMultiplierPerLevel: 1.11,
  ),
  Building(
    name: "Market",
    level: 1,
    image: "assets/town-buildings/The Market.png",
    resourcesProduced: {"Gold": 100},
    costToProduce: {"Wood": 10, "Stone": 5, "Iron": 2},
    costToUpgrade: {"Wood": 30, "Stone": 15, "Gold": 250, "Food": 10},
    resourceMultiplierPerLevel: 1.14,
    upgradeCostMultiplierPerLevel: 1.15,
  ),
  Building(
    name: "Hunter's Lodge",
    level: 1,
    image: "assets/town-buildings/Hunter's Lodge.png",
    resourcesProduced: {"Food": 4},
    costToProduce: {},
    costToUpgrade: {"Wood": 10, "Stone": 5, "Iron": 5},
    resourceMultiplierPerLevel: 1.15,
    upgradeCostMultiplierPerLevel: 1.12,
  ),
  Building(
    name: "Blacksmith",
    level: 1,
    image: "assets/town-buildings/Blacksmith.png",
    resourcesProduced: {"Iron": 3},
    costToProduce: {"Stone": 5, "Wood": 3},
    costToUpgrade: {"Stone": 15, "Wood": 5, "Iron": 5, "Gold": 50},
    resourceMultiplierPerLevel: 1.135,
    upgradeCostMultiplierPerLevel: 1.13,
  ),
  Building(
    name: "Warehouse",
    level: 1,
    image: "assets/town-buildings/Warehouse.png",
    resourcesProduced: {},
    costToProduce: {},
    costToUpgrade: {"Wood": 40, "Stone": 20, "Gold": 400, "Iron": 10},
    resourceMultiplierPerLevel: 0,
    upgradeCostMultiplierPerLevel: 1.16,
  ),
  Building(
    name: "Military Camp",
    level: 1,
    image: "assets/town-buildings/Military Camp.png",
    resourcesProduced: {"Soldier": 3},
    costToProduce: {"Food": 5},
    costToUpgrade: {
      "Wood": 20,
      "Stone": 10,
      "Gold": 200,
      "Iron": 5,
      "Food": 15
    },
    resourceMultiplierPerLevel: 1.13,
    upgradeCostMultiplierPerLevel: 1.12,
  ),
];

class Building {
  String name;
  int level;
  String image;
  Map<String, int> costToProduce;
  Map<String, int> resourcesProduced;
  double resourceMultiplierPerLevel;
  Map<String, int> costToUpgrade;
  double upgradeCostMultiplierPerLevel;

  Building(
      {required this.name,
      required this.level,
      required this.image,
      required this.resourcesProduced,
      required this.costToProduce,
      required this.costToUpgrade,
      required this.resourceMultiplierPerLevel,
      required this.upgradeCostMultiplierPerLevel});
}

class TownPageState extends State<TownPage> {
  final List<String> resources = [
    "Wood",
    "Stone",
    "Gold",
    "Food",
    "Iron",
    "Soldier"
  ];
  final Map<String, int> maxStorableResources = {
    "Wood": 50,
    "Stone": 30,
    "Gold": 500,
    "Food": 30,
    "Iron": 20,
    "Soldier": 15,
  };

  final double storageResourceScale = 1.2;
  Map<String, int> storedResources = {};
  Map<String, Building> currentBuildings = {};

  @override
  void initState() {
    storedResources = {for (var resource in resources) resource: 0};
    currentBuildings = {
      for (var building in defaultBuildings) building.name: building
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                resources.length,
                (index) {
                  return resourceTile(
                      resource: resources[index],
                      icon: 'assets/resource-icons/${resources[index]}.png',
                      size: min(MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.height) /
                          (resources.length * 1.4),
                      textSize: 100 / (resources.length * 1.4),
                      context: context);
                },
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: Wrap(
            children: List.generate(
              defaultBuildings.length,
              (index) => buildingTile(
                building: currentBuildings.values.toList()[index],
                size: min(MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height) /
                    2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget resourceTile(
      {required String resource,
      required String icon,
      required double size,
      required double textSize,
      required BuildContext context}) {
    double storageProgress = (storedResources[resource] ?? 0) /
        ((maxStorableResources[resource]! *
            pow(storageResourceScale, currentBuildings["Warehouse"]!.level)));
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: const Color.fromARGB(158, 228, 228, 228),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: -1,
                child: LinearProgressIndicator(
                  value: storageProgress,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      (storageProgress < 0.5
                              ? Color.lerp(Colors.lightGreen, Colors.yellow,
                                  storageProgress * 2)
                              : Color.lerp(Colors.yellow, Colors.red,
                                  (storageProgress - 0.5) * 2)) ??
                          Colors.white),
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: size, // Set a fixed width for a square tile
                    height: size, // Set a fixed height for a square tile
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        filterQuality: FilterQuality.none,
                        image: AssetImage(icon),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text(
                    formatNumber(storedResources[resource] ?? 0, 4),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: textSize,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildingTile({required Building building, required double size}) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: InkWell(
        onTap: () => _showBuildingDetailsDialog(context, building),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 3),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: const Color.fromARGB(167, 73, 73, 73)),
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(building.image),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.darken),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 2, color: Colors.white),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      building.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size / 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if ((building.name == "Castle" ||
                                building.level <
                                    currentBuildings["Castle"]!.level) &&
                            building.costToUpgrade.keys.every((resource) {
                              return (storedResources[resource] ?? 0) >=
                                  (building.costToUpgrade[resource]! *
                                          pow(
                                              building
                                                  .upgradeCostMultiplierPerLevel,
                                              building.level - 1))
                                      .toInt();
                            }))
                          IconButton(
                            iconSize: size / 4,
                            icon: const Icon(
                              Icons.arrow_upward_sharp,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              for (var resource
                                  in building.costToUpgrade.keys) {
                                storedResources.update(
                                  resource,
                                  (value) =>
                                      value -
                                      ((building.costToUpgrade[resource]! *
                                              pow(
                                                  building
                                                      .upgradeCostMultiplierPerLevel,
                                                  building.level - 1))
                                          .toInt()),
                                  ifAbsent: () => 0,
                                );
                              }
                              setState(() {
                                currentBuildings[building.name]!.level += 1;
                              });
                            },
                          ),
                        if (building.resourcesProduced.isNotEmpty &&
                            building.costToProduce.keys.every((resource) {
                              return (storedResources[resource] ?? 0) >=
                                  (building.costToProduce[resource]! *
                                          pow(
                                              building
                                                  .resourceMultiplierPerLevel,
                                              building.level - 1))
                                      .toInt();
                            }))
                          IconButton(
                            iconSize: size / 4,
                            icon: Stack(
                              alignment: const Alignment(0, 0.4),
                              children: [
                                Icon(
                                  Icons.work,
                                  color: (building.resourcesProduced.keys
                                          .every((resource) {
                                    return (storedResources[resource] ?? 0) <
                                        (maxStorableResources[resource]! *
                                                pow(
                                                    storageResourceScale,
                                                    currentBuildings[
                                                            "Warehouse"]!
                                                        .level))
                                            .toInt();
                                  }))
                                      ? Colors.white
                                      : Colors.red,
                                ),
                                Image.asset(
                                  'assets/resource-icons/${building.resourcesProduced.keys.first}.png',
                                  width: size / 7,
                                  height: size / 7,
                                )
                              ],
                            ),
                            onPressed: () async {
                              setState(() {
                                for (var resource
                                    in building.costToProduce.keys) {
                                  storedResources.update(
                                    resource,
                                    (value) =>
                                        value -
                                        ((building.costToProduce[resource]! *
                                                pow(
                                                    building
                                                        .resourceMultiplierPerLevel,
                                                    building.level - 1))
                                            .toInt()),
                                    ifAbsent: () => 0,
                                  );
                                }
                              });
                              List<Task> loadedTasks = loadedAssignments.values
                                  .where((assignment) =>
                                      assignment.assignedEmpires
                                          .contains(widget.currentEmpire.id) &&
                                      assignment.isActive)
                                  .expand((assignment) => assignment
                                      .tasks) // Assuming assignment.tasks is the list of Task objects
                                  .toList();
                              if (loadedTasks.isEmpty) {
                                showLoadingDialog(context, "Finding tasks...");
                                await loadAssignments(
                                    widget.currentEmpire, false);
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                              }
                              loadedTasks = loadedAssignments.values
                                  .where((assignment) =>
                                      assignment.assignedEmpires
                                          .contains(widget.currentEmpire.id) &&
                                      assignment.isActive)
                                  .expand((assignment) => assignment
                                      .tasks) // Assuming assignment.tasks is the list of Task objects
                                  .toList();
                              loadedTasks.shuffle();
                              if (loadedTasks.isEmpty) {
                                Fluttertoast.showToast(
                                    msg: "Couldn't find tasks");
                                return;
                              }
                              double success = 0;
                              // ignore: use_build_context_synchronously
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizPage(
                                    tasks: loadedTasks,
                                    onQuizCompleted: (percentage) {
                                      // Handle the quiz completion here
                                      // For now, print the percentage to the console
                                      success = percentage;
                                      Fluttertoast.showToast(
                                          msg:
                                              'Quiz completed. Percentage: ${percentage * 100}%');
                                    },
                                  ),
                                ),
                              );

                              setState(() {
                                for (var resource
                                    in building.resourcesProduced.keys) {
                                  storedResources.update(
                                    resource,
                                    (value) => clampDouble(
                                            value +
                                                ((building.resourcesProduced[
                                                            resource]! *
                                                        pow(
                                                            building
                                                                .resourceMultiplierPerLevel,
                                                            building.level -
                                                                1) *
                                                        success)
                                                    .floor()
                                                    .toDouble()),
                                            0,
                                            (maxStorableResources[resource]! *
                                                    pow(
                                                        storageResourceScale,
                                                        currentBuildings[
                                                                "Warehouse"]!
                                                            .level))
                                                .floor()
                                                .toDouble())
                                        .toInt(),
                                    ifAbsent: () => 0,
                                  );
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                "Level: ${building.level}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size / 10,
                    color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showBuildingDetailsDialog(BuildContext context, Building building) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${building.name} - LvL ${building.level}"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (building.resourcesProduced.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      building.costToProduce.isEmpty
                          ? const Icon(Icons.close)
                          : Row(
                              children: _getResourceTiles(
                                  building.costToProduce,
                                  building.resourceMultiplierPerLevel,
                                  building.level)),
                      const Icon(Icons.arrow_forward),
                      Row(
                          children: _getResourceTiles(
                              building.resourcesProduced,
                              building.resourceMultiplierPerLevel,
                              building.level)),
                    ],
                  ),
                const Divider(
                  thickness: 3,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.arrow_circle_up),
                      ..._getResourceTiles(
                          building.costToUpgrade,
                          building.upgradeCostMultiplierPerLevel,
                          building.level)
                    ]),
                const Divider(
                  thickness: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _getResourceTiles(
      Map<String, int> resources, double multiplier, int level) {
    List<Widget> resourceTiles = [];

    resources.forEach((resource, amount) {
      resourceTiles.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Image.asset(
                'assets/resource-icons/$resource.png',
                width: 30,
                height: 30,
              ),
              Text(formatNumber(
                  (amount * pow(multiplier, level - 1)).toInt(), 4)),
            ],
          ),
        ),
      );
    });

    return resourceTiles;
  }
}
