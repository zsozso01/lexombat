// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Map<String, dynamic>> _translations;

  @override
  void initState() {
    super.initState();
    _translations =
        _loadTranslations('hu.json'); // Default language is Hungarian
  }

  Future<Map<String, dynamic>> _loadTranslations(String languageCode) async {
    String jsonString =
        await rootBundle.loadString('assets/translations/$languageCode');
    return json.decode(jsonString);
  }

  String selectedLanguage = "hu";
  void _changeLanguage(String languageCode) {
    selectedLanguage = languageCode;
    setState(() {
      _translations = _loadTranslations('$languageCode.json');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medieval Empire Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
        Locale('hu', 'HU'), // Hungarian
        // Add more supported languages as needed
      ],
      home: FutureBuilder(
        future: _translations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Loading indicator while translations are being loaded
          } else if (snapshot.hasError) {
            return const Text('Error loading translations');
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text(snapshot.data?['welcome'] ?? ''),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(snapshot.data?['play'] ?? ''),
                    Text(snapshot.data?['settings'] ?? ''),
                    DropdownButton<String>(
                      value: selectedLanguage,
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'es',
                          child: Text('Español'),
                        ),
                        DropdownMenuItem(
                          value: 'hu',
                          child: Text('Magyar'),
                        ),
                        // Add more languages here
                      ],
                      onChanged: (String? newLanguage) {
                        if (newLanguage != null) {
                          _changeLanguage(newLanguage);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
