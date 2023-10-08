import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  return true;
}

class Empire {
  String id;
  String name;
  String creatorID;
  String creatorName;
  Map<String, String> joinedMembers;
  Map<String, String> cities;
  String coatOfArmsColor;

  Empire({
    required this.id,
    required this.name,
    required this.creatorID,
    required this.creatorName,
    required this.joinedMembers,
    required this.cities,
    required this.coatOfArmsColor,
  });

  factory Empire.fromJson(Map<String, dynamic> json) {
    return Empire(
      id: json['id'],
      name: json['name'],
      creatorID: json['creatorID'],
      creatorName: json['creatorName'],
      joinedMembers: Map<String, String>.from(json['joinedMembers']),
      cities: Map<String, String>.from(json['cities']),
      coatOfArmsColor: json['coatOfArmsColor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creatorID': creatorID,
      'creatorName': creatorName,
      'joinedMembers': joinedMembers,
      'cities': cities,
      'coatOfArmsColor': coatOfArmsColor,
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
