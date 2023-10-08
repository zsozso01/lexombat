// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'globals.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  void showMessage(String text, Color background) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  // create an instance of the FirebaseAuth service
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _submitForm() async {
    _emailController.text = _emailController.text.trim();
    _emailController.text = _emailController.text.toLowerCase();
    _passwordController.text = _passwordController.text.trim();
    _confirmPasswordController.text = _confirmPasswordController.text.trim();
    _nameController.text = _nameController.text.trim();

    if (!_signUpFormKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // ignore: prefer_const_literals_to_create_immutables
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Regisztráció..."), // Hungarian Translation
              ],
            ),
          ),
        );
      },
    );
    // form is valid, process the data
    try {
      // create a new user with the email and password
      final result = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await result.user?.sendEmailVerification();
      await firestore.collection("userInfo").doc(result.user?.uid).set({
        "email": _emailController.text.trim(),
        "name": _nameController.text.trim(),
        "isAdmin": false,
        "premiumCredits": 0
      });
      // update the user's profile with the additional data
      await result.user?.updateDisplayName(_nameController.text.trim());
      showMessage(
          "Sikeres regisztráció!", Colors.black); // Hungarian Translation
      Navigator.pop(context);
      Navigator.pop(context);
      // ignore: empty_catches
    } catch (e) {
      Navigator.pop(context);
      showMessage(e.toString(), Colors.red);
    }
  }

  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translations["registrationPrompt"] ?? "Regisztráció"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _signUpFormKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translations["nameValidationMessage"];
                      } else if (!value.contains(" ")) {
                        return translations["validNameValidationMessage"];
                      }
                      return null;
                    },
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: translations["nameLabel"] ?? "Név",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (!RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+")
                          .hasMatch(value ?? "")) {
                        return translations["invalidEmailMessage"];
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: translations["emailLabel"] ?? "Levél",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !passwordVisible,
                    validator: (value) {
                      if ((value?.length ?? 0) < 8 ||
                          !RegExp(r"(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*\W)")
                              .hasMatch(value ?? "")) {
                        return translations["passwordStrengthMessage"];
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText:
                          translations["passwordLabel"] ?? "Titkos jelszó",
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !passwordVisible,
                    validator: (value) {
                      return value != _passwordController.text
                          ? translations["confirmPasswordLabel"] ??
                              "Jelszó megerősítése"
                          : null;
                    },
                    decoration: InputDecoration(
                      labelText: translations["confirmPasswordLabel"] ??
                          "Jelszó megerősítése",
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(
                      translations["registrationPrompt"] ?? "Regisztráció"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
