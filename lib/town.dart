import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
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

final List<Building> defaultBuildings = [
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
    costToProduce: {"Food": 5, "Iron": 3, "Gold": 30},
    costToUpgrade: {"Wood": 20, "Stone": 10, "Gold": 200, "Iron": 5, "Food": 15},
    resourceMultiplierPerLevel: 1.13,
    upgradeCostMultiplierPerLevel: 1.12,
  ),
];

class TownPageState extends State<TownPage> {
  @override
  void initState() {
    storedResources = {for (var resource in resources) resource: 0};
    currentBuildings = {for (var building in defaultBuildings) building.name: Building.fromJson(building.toJson())};
    loadTown();
    super.initState();
  }

  Future<void> saveTown() async {
    await saveBuildings();
    await saveResources(widget.currentEmpire.id!);
  }

  Future<void> saveBuildings() async {
    var query = FirebaseFirestore.instance.collection("towns").doc("${widget.currentEmpire.id} ${userProfile!.uid}");
    if ((await query.get()).exists) {
      await query.update({for (var building in currentBuildings.values) building.name: building.level});
    } else {
      query.set({for (var building in currentBuildings.values) building.name: building.level});
    }
  }

  Future<void> loadTown() async {
    var loadedResources =
        (await FirebaseFirestore.instance.collection("resources").doc("${widget.currentEmpire.id} ${userProfile!.uid}").get()).data();
    if (loadedResources != null && loadedResources.isNotEmpty) {
      storedResources = {for (var resource in loadedResources.entries) resource.key: resource.value};
    }
    var loadedBuildings = (await FirebaseFirestore.instance.collection("towns").doc("${widget.currentEmpire.id} ${userProfile!.uid}").get()).data();
    if (loadedBuildings != null && loadedBuildings.isNotEmpty) {
      for (var building in loadedBuildings.entries) {
        currentBuildings[building.key]!.level = building.value;
      }
    }
    if (mounted) {
      setState(() {});
    }
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
                      size: min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) / (resources.length * 1.6),
                      textSize: 100 / (resources.length * 1.6),
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
              currentBuildings.length,
              (index) => buildingTile(
                building: currentBuildings.values.toList()[index],
                size: min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) / 2.2,
              ),
            ),
          ),
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
              border: Border.all(width: 3), borderRadius: const BorderRadius.all(Radius.circular(10)), color: const Color.fromARGB(167, 73, 73, 73)),
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(building.image),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
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
                        if ((building.name == "Castle" || building.level < currentBuildings["Castle"]!.level) &&
                            building.costToUpgrade.keys.every((resource) {
                              return (storedResources[resource] ?? 0) >=
                                  (building.costToUpgrade[resource]! * pow(building.upgradeCostMultiplierPerLevel, building.level - 1)).toInt();
                            }))
                          IconButton(
                            iconSize: size / 4,
                            icon: const Icon(
                              Icons.arrow_upward_sharp,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              for (var resource in building.costToUpgrade.keys) {
                                storedResources.update(
                                  resource,
                                  (value) =>
                                      value -
                                      ((building.costToUpgrade[resource]! * pow(building.upgradeCostMultiplierPerLevel, building.level - 1)).toInt()),
                                  ifAbsent: () => 0,
                                );
                              }
                              setState(() {
                                currentBuildings[building.name]!.level += 1;
                              });
                              saveTown();
                            },
                          ),
                        if (building.resourcesProduced.isNotEmpty &&
                            building.costToProduce.keys.every((resource) {
                              return (storedResources[resource] ?? 0) >=
                                  (building.costToProduce[resource]! * pow(building.resourceMultiplierPerLevel, building.level - 1)).toInt();
                            }))
                          IconButton(
                            iconSize: size / 4,
                            icon: Stack(
                              alignment: const Alignment(0, 0.4),
                              children: [
                                Icon(
                                  Icons.work,
                                  color: (building.resourcesProduced.keys.every((resource) {
                                    return (storedResources[resource] ?? 0) <
                                        (maxStorableResources[resource]! * pow(storageResourceScale, currentBuildings["Warehouse"]!.level)).toInt();
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
                                for (var resource in building.costToProduce.keys) {
                                  storedResources.update(
                                    resource,
                                    (value) =>
                                        value -
                                        ((building.costToProduce[resource]! * pow(building.resourceMultiplierPerLevel, building.level - 1)).toInt()),
                                    ifAbsent: () => 0,
                                  );
                                }
                              });
                              List<Task> loadedTasks = loadedAssignments.values
                                  .where((assignment) => assignment.assignedEmpires.contains(widget.currentEmpire.id) && assignment.isActive)
                                  .expand((assignment) => assignment.tasks) // Assuming assignment.tasks is the list of Task objects
                                  .toList();
                              if (loadedTasks.isEmpty) {
                                showLoadingDialog(context, translations["taskFind"]);
                                await loadAssignments(widget.currentEmpire, false);
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                              }
                              loadedTasks = loadedAssignments.values
                                  .where((assignment) => assignment.assignedEmpires.contains(widget.currentEmpire.id) && assignment.isActive)
                                  .expand((assignment) => assignment.tasks) // Assuming assignment.tasks is the list of Task objects
                                  .toList();
                              loadedTasks.shuffle();
                              if (loadedTasks.isEmpty) {
                                Fluttertoast.showToast(msg: translations["taskNotFound"]);
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
                                    },
                                  ),
                                ),
                              );
                              setState(() {
                                for (var resource in building.resourcesProduced.keys) {
                                  int amountToAdd = clampDouble(
                                          (storedResources[resource] ?? 0) +
                                              ((building.resourcesProduced[resource]! *
                                                      pow(building.resourceMultiplierPerLevel, building.level - 1) *
                                                      success)
                                                  .floor()
                                                  .toDouble()),
                                          0,
                                          (maxStorableResources[resource]! * pow(storageResourceScale, currentBuildings["Warehouse"]!.level))
                                              .floor()
                                              .toDouble())
                                      .toInt();
                                  storedResources.update(
                                    resource,
                                    (value) => amountToAdd,
                                    ifAbsent: () => 0,
                                  );
                                }
                              });
                              saveTown();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                "${translations["level"]}: ${building.level}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: size / 10, color: Colors.white),
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
          title: Text("${translations[building.name]} - LvL ${building.level}"),
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
                          : Row(children: getResourceTiles(building.costToProduce, building.resourceMultiplierPerLevel, building.level)),
                      const Icon(Icons.arrow_forward),
                      Row(children: getResourceTiles(building.resourcesProduced, building.resourceMultiplierPerLevel, building.level)),
                    ],
                  ),
                const Divider(
                  thickness: 3,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const Icon(Icons.arrow_circle_up),
                  ...getResourceTiles(building.costToUpgrade, building.upgradeCostMultiplierPerLevel, building.level)
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
              child: Text(translations["close"]),
            ),
          ],
        );
      },
    );
  }
}
