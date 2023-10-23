import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restart_app/restart_app.dart';

String selectedLanguage = "en";
late Map<String, dynamic> translations;

Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
  String jsonString =
      await rootBundle.loadString('assets/translations/$languageCode');
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
  Profile(
      {required this.email,
      required this.isAdmin,
      required this.uid,
      required this.username,
      required this.premiumCredits});
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
  FirebaseFirestore.instance
      .collection("userInfo")
      .doc(uid)
      .snapshots()
      .listen((snapshot) {
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
  String name;
  String creatorID;
  String creatorName;
  List<String> joinedMembers;
  String coatOfArms;

  Empire({
    required this.name,
    required this.creatorID,
    required this.creatorName,
    required this.joinedMembers,
    required this.coatOfArms,
  });

  factory Empire.fromJson(Map<String, dynamic> json) {
    return Empire(
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
    return Empire.fromJson(jsonMap);
  }
}

String generateUniqueEmpireId() {
  return "${userProfile!.uid.substring(0, 2)}${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}${userProfile!.uid.substring(userProfile!.uid.length - 2)}"; // Replace this with the actual unique ID
}

Widget generateCoatOfArms(int selectedBackgroundColor, int selectedIcon,
    int selectedIconColor, double scale) {
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
      title: const Text(
        'Kijelentkezés',
      ),
      content: Text(
        'Biztosan ki szeretne jelentkezni?',
        style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text(
            'Mégse',
            style: TextStyle(color: Colors.grey),
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
          child: const Text(
            'Kijelentkezés',
            style: TextStyle(color: Colors.white),
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
