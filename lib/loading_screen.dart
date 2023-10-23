// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lexombat/empires_screen.dart';
import 'package:lexombat/firebase_options.dart';
import 'package:lexombat/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'globals.dart';
import 'dart:ui' as ui;

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;
  String _progressTitle = "";

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        setState(() {
          _progress = _progressController.value;
        });
      });

    // Start loading data when the widget is initialized
    _loadData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _loadData() async {
    await changeLoadProgress(
        10, "Quaestio bibliotheca regia in dictionarium...");
    // Load languages
    selectedLanguage = ui.window.locale.languageCode;
    translations = await loadTranslations('$selectedLanguage.json');
    await changeLoadProgress(50, translations["loading_firebase"]);
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await changeLoadProgress(90, "${translations["checkingProfile"]}...");
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('Email');
    if (savedEmail != null) {
      await changeLoadProgress(99, "${translations["loginPrompt"]}...");
      // Attempt to sign in with the saved email and password.
      // If sign-in is successful, navigate to the home page; otherwise, navigate to the login page.
      bool success = await login(
          email: savedEmail, password: prefs.getString('Password') ?? "");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) =>
                success ? const EmpireManagerScreen() : const SignIn()),
      );
    } else {
      // No email saved, navigate to the login page.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    }
  }

  Future<void> changeLoadProgress(double progress, String title) async {
    progress = clampDouble(progress, 0, 100) / 100;
    _progressController.animateTo(progress);
    setState(() {
      _progressTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                height: min(MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height) /
                    2,
                width: min(MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height) /
                    2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/full-logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearProgressIndicator(
                  value: _progress,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FadeTransition(
                  opacity: _progressController
                      .drive(CurveTween(curve: Curves.easeInOut)),
                  child: Shimmer.fromColors(
                    baseColor: Colors.black,
                    highlightColor: Theme.of(context).primaryColor,
                    child: Text(
                      _progressTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
