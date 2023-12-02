import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restart_app/restart_app.dart';

String selectedLanguage = "en";
late Map<String, dynamic> translations;

Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
  /*String jsonString =
      await rootBundle.loadString('assets/translations/$languageCode');*/
  String jsonString = await rootBundle.loadString('assets/translations/en.json');
  return json.decode(jsonString);
}

Future<void> changeLanguage(String languageCode) async {
  selectedLanguage = languageCode;
  translations = await loadTranslations('$languageCode.json');
}

Profile? userProfile;
bool adminMode = false;

class Profile {
  String username;
  String uid;
  String email;
  bool isAdmin;
  int premiumCredits;
  Profile({required this.email, required this.isAdmin, required this.uid, required this.username, required this.premiumCredits});
}

Future<bool> login({required String email, required String password}) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    Fluttertoast.showToast(msg: e.toString());
    return false;
  }
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('Email', email);
  prefs.setString('Password', password);
  String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  FirebaseFirestore.instance.collection("userInfo").doc(uid).snapshots().listen((snapshot) {
    userProfile = Profile(
        premiumCredits: snapshot["premiumCredits"] ?? 0,
        email: email,
        isAdmin: snapshot["isAdmin"] ?? false,
        uid: uid,
        username: snapshot["name"] ?? "Ismeretlen név");
    adminMode = userProfile!.isAdmin;
  });
  while (userProfile == null) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  return true;
}

Map<String, Empire> createdEmpires = {};
Map<String, Empire> joinedEmpires = {};

List<IconData> coatOfArmsIcons = [
  // School Icons
  Icons.school,
  Icons.book,
  Icons.school_outlined,
  Icons.library_books,
  Icons.local_library,
  Icons.assignment,
  Icons.edit,
  Icons.note,
  Icons.lightbulb,
  Icons.computer,
  Icons.language,
  Icons.translate,
  Icons.desktop_mac,
  Icons.timeline,
  Icons.brush,
  Icons.sports_soccer,
  Icons.music_note,
  Icons.calculate, // Mathematics
  Icons.history, // History
  Icons.science, // Science
  Icons.menu_book, // Literature / Language Arts
  Icons.directions_run, // Physical Education / Sports
  Icons.music_note, // Music
  Icons.brush, // Art
  Icons.code, // Computer Science / Programming
  Icons.eco, // Biology
  Icons.scatter_plot, // Chemistry
  Icons.science, // Physics
  Icons.public, // Geography
  Icons.language, // Foreign Language
  Icons.attach_money, // Economics
  Icons.psychology, // Psychology

  // Combat Icons
  Icons.shield,
  Icons.dangerous,
  Icons.explore,
  Icons.strikethrough_s,

  // Empire Icons
  Icons.castle,
  Icons.account_balance,
  Icons.flag,
  Icons.gavel,
  Icons.king_bed,
  Icons.landscape,
  Icons.store,
  Icons.domain,
  Icons.apartment,
  Icons.airline_seat_individual_suite,
];

List<Color> coatOfArmsColors = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
  Colors.grey,
  Colors.amber,
  Colors.black,
  Colors.blueGrey,
  Colors.cyan,
  Colors.deepOrange,
  Colors.deepPurple,
  Colors.greenAccent,
  Colors.lightBlue,
  Colors.lightGreen,
  Colors.lime,
  Colors.orangeAccent,
  Colors.purpleAccent,
  Colors.redAccent,
  Colors.teal,
  Colors.yellowAccent,
  Colors.deepOrangeAccent,
  Colors.deepPurpleAccent,
  Colors.blueAccent,
  Colors.lightBlueAccent,
  Colors.lightGreenAccent,
  Colors.cyanAccent,
  Colors.amberAccent,
  Colors.pinkAccent,
  Colors.indigoAccent,
  Colors.limeAccent,
  Colors.tealAccent,
];

class Empire {
  String? id;
  String name;
  String creatorID;
  String creatorName;
  List<String> joinedMembers;
  String coatOfArms;

  Empire({required this.name, required this.creatorID, required this.creatorName, required this.joinedMembers, required this.coatOfArms, this.id});

  factory Empire.fromJson(Map<String, dynamic> json, String? id) {
    return Empire(
      id: id,
      name: json['name'],
      creatorID: json['creatorID'],
      creatorName: json['creatorName'],
      joinedMembers: List<String>.from(json['joinedMembers']),
      coatOfArms: json['coatOfArmsColor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'creatorID': creatorID,
      'creatorName': creatorName,
      'joinedMembers': joinedMembers,
      'coatOfArmsColor': coatOfArms,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static Empire fromJsonString(String jsonString) {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return Empire.fromJson(jsonMap, null);
  }
}

String generateUniqueEmpireId() {
  return "${userProfile!.uid.substring(0, 2)}${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}${userProfile!.uid.substring(userProfile!.uid.length - 2)}"; // Replace this with the actual unique ID
}

Widget generateCoatOfArms(int selectedBackgroundColor, int selectedIcon, int selectedIconColor, double scale) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Icon(
        Icons.shield,
        color: coatOfArmsColors[selectedBackgroundColor],
        size: 100 * scale,
      ),
      Icon(
        coatOfArmsIcons[selectedIcon],
        size: 50 * scale,
        color: coatOfArmsColors[selectedIconColor],
      )
    ],
  );
}

void showLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        translations["logout"],
      ),
      content: Text(
        translations["logoutPrompt"],
        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            translations["cancel"],
            style: const TextStyle(color: Colors.grey),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Dismiss the dialog
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(88, 36),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
          child: Text(
            translations["logout"],
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            // Perform logout operation here
            Navigator.pop(context);
            Navigator.of(context).pop(); // Dismiss the dialog
            await FirebaseAuth.instance.signOut();
            final prefs = await SharedPreferences.getInstance();
            prefs.clear();
            Restart.restartApp();
          },
        ),
      ],
    ),
  );
}

class Task {
  String question;
  bool isTrueOrFalse;
  List<String> goodAnswers;
  List<String> wrongAnswers;
  double difficultyMultiplier = 1;

  Task({
    required this.question,
    required this.isTrueOrFalse,
    required this.goodAnswers,
    required this.wrongAnswers,
    required this.difficultyMultiplier,
  });

  // Factory constructor to create Task object from JSON data
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      question: json['question'] ?? '',
      isTrueOrFalse: json['isTrueOrFalse'] ?? false,
      goodAnswers: List<String>.from(json['goodAnswers'] ?? []),
      wrongAnswers: List<String>.from(json['wrongAnswers'] ?? []),
      difficultyMultiplier: double.parse((json['difficultyMultiplier'] ?? 1).toString()),
    );
  }

  // Convert Task object to JSON data
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'isTrueOrFalse': isTrueOrFalse,
      'goodAnswers': goodAnswers,
      'wrongAnswers': wrongAnswers,
      'difficultyMultiplier': difficultyMultiplier
    };
  }

  int calculateTaskDifficulty() {
    if (isTrueOrFalse) {
      return 1;
    }
    return min(((goodAnswers.length + wrongAnswers.length) / 2 * difficultyMultiplier).toInt(), 5);
  }
}

class Assignment {
  String id;
  String name;
  List<Task> tasks;
  String ownerId;
  String creatorName;
  bool isActive;
  List<String> assignedEmpires;
  DateTime lastUpdated;

  Assignment(
      {required this.id,
      required this.name,
      required this.tasks,
      required this.ownerId,
      required this.creatorName,
      required this.isActive,
      required this.assignedEmpires,
      required this.lastUpdated});

  factory Assignment.fromJson(Map<String, dynamic> json) {
    var tasksJson = json['tasks'] as List<dynamic>;
    List<Task> tasks = tasksJson.map((taskJson) => Task.fromJson(taskJson)).toList();

    return Assignment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      tasks: tasks,
      ownerId: json['ownerId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      isActive: json['isActive'] ?? false,
      assignedEmpires: List<String>.from(json['assignedEmpires'] ?? []),
      lastUpdated: DateTime.parse(json["lastUpdated"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> tasksJson = tasks.map((task) => task.toJson()).toList();

    return {
      'id': id,
      'name': name,
      'tasks': tasksJson,
      'ownerId': ownerId,
      'creatorName': creatorName,
      'isActive': isActive,
      'assignedEmpires': assignedEmpires,
      'lastUpdated': lastUpdated.toString()
    };
  }

  double getDifficulties() {
    double tempStorage = 0;
    for (var task in tasks) {
      tempStorage += task.calculateTaskDifficulty();
    }
    return (tempStorage / (tasks.isNotEmpty ? tasks.length : 1) * 100).round() / 100;
  }
}

Color getColorBasedOnDifficulty(double difficultyLevel) {
  // Logic to determine color based on difficulty level (0-5)
  // You can implement your own logic here, for example:
  double fraction = difficultyLevel / 5.0; // Fraction from 0 to 1
  return Color.lerp(Colors.green, Colors.red, fraction)!;
}

Map<String, Assignment> loadedAssignments = {};

String formatNumber(int number, int accuracy) {
  double formattedNumber = number.toDouble();
  String suffix = '';

  if (number >= 1000000000000) {
    formattedNumber = number / 1000000000000;
    suffix = 'T';
  } else if (number >= 1000000000) {
    formattedNumber = number / 1000000000;
    suffix = 'B';
  } else if (number >= 1000000) {
    formattedNumber = number / 1000000;
    suffix = 'M';
  } else if (number >= 9999) {
    formattedNumber = number / 1000;
    suffix = 'K';
  }
  return formattedNumber.toStringAsFixed(formattedNumber > 9999 ? accuracy - (formattedNumber.toInt().toString().length % accuracy) : 0) + suffix;
}

Future<dynamic> loadAssignments(Empire selectedEmpire, bool updateMode) async {
  var tempQuery = FirebaseFirestore.instance.collection("assignments").where("assignedEmpires", arrayContains: selectedEmpire.id);
  if (selectedEmpire.creatorID != userProfile!.uid) {
    tempQuery = tempQuery.where("isActive", isEqualTo: true);
  }
  if (!updateMode) {
    var docs = await tempQuery.get();
    for (var doc in docs.docs) {
      loadedAssignments[doc.id] = Assignment.fromJson(doc.data());
    }
    return null;
  } else {
    var stream = tempQuery.snapshots().listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.removed) {
          loadedAssignments.remove(docChange.doc.id);
        } else {
          loadedAssignments[docChange.doc.id] = Assignment.fromJson(docChange.doc.data()!);
        }
      }
    });
    return stream;
  }
}

Future<void> showLoadingDialog(BuildContext context, String text) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(text),
          ],
        ),
      );
    },
  );
}

class CustomToast {
  static void show(BuildContext context, String message) {
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 3),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }
}

class Building {
  String name;
  int level;
  String image;
  Map<String, int> costToProduce;
  Map<String, int> resourcesProduced;
  double resourceMultiplierPerLevel;
  Map<String, int> costToUpgrade;
  double upgradeCostMultiplierPerLevel;

  Building({
    required this.name,
    required this.level,
    required this.image,
    required this.resourcesProduced,
    required this.costToProduce,
    required this.costToUpgrade,
    required this.resourceMultiplierPerLevel,
    required this.upgradeCostMultiplierPerLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
      'image': image,
      'costToProduce': costToProduce,
      'resourcesProduced': resourcesProduced,
      'resourceMultiplierPerLevel': resourceMultiplierPerLevel,
      'costToUpgrade': costToUpgrade,
      'upgradeCostMultiplierPerLevel': upgradeCostMultiplierPerLevel,
    };
  }

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      name: json['name'],
      level: json['level'],
      image: json['image'],
      costToProduce: Map<String, int>.from(json['costToProduce']),
      resourcesProduced: Map<String, int>.from(json['resourcesProduced']),
      resourceMultiplierPerLevel: json['resourceMultiplierPerLevel'],
      costToUpgrade: Map<String, int>.from(json['costToUpgrade']),
      upgradeCostMultiplierPerLevel: json['upgradeCostMultiplierPerLevel'],
    );
  }
}

List<Widget> getResourceTiles(Map<String, int> resources, double multiplier, int level) {
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
            Text(formatNumber((amount * pow(multiplier, level - 1)).toInt(), 4)),
          ],
        ),
      ),
    );
  });

  return resourceTiles;
}

Future<void> saveResources(String empire) async {
  var query = FirebaseFirestore.instance.collection("resources").doc("$empire ${userProfile!.uid}");
  if ((await query.get()).exists) {
    await query.update(storedResources);
  } else {
    query.set(storedResources);
  }
}

final List<String> resources = ["Wood", "Stone", "Gold", "Food", "Iron", "Soldier"];
final Map<String, int> maxStorableResources = {
  "Wood": 50,
  "Stone": 30,
  "Gold": 500,
  "Food": 30,
  "Iron": 20,
  "Soldier": 15,
};

const double storageResourceScale = 1.2;
Map<String, int> storedResources = {};
Map<String, Building> currentBuildings = {};

Widget resourceTile({required String resource, required String icon, required double size, required double textSize, required BuildContext context}) {
  double storageProgress =
      (storedResources[resource] ?? 0) / ((maxStorableResources[resource]! * pow(storageResourceScale, currentBuildings["Warehouse"]!.level)));
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
                valueColor: AlwaysStoppedAnimation<Color>((storageProgress < 0.5
                        ? Color.lerp(Colors.lightGreen, Colors.yellow, storageProgress * 2)
                        : Color.lerp(Colors.yellow, Colors.red, (storageProgress - 0.5) * 2)) ??
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

Color stringToColor(String value) {
  if (value == "") return const Color.fromARGB(118, 74, 188, 78);
  final int hash = jsonEncode(value).hashCode & 0xffffff;
  final double hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1.0, hue, 0.8, 0.8).toColor();
}
