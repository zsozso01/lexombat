// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lexombat/globals.dart';
import 'package:restart_app/restart_app.dart';
import 'package:lexombat/signup.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final GlobalKey<FormState> _signInFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
              const SizedBox(
                height: 50,
              ),
              Form(
                key: _signInFormKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: translations["emailLabel"],
                        ),
                        controller: _emailController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return translations["emailValidationMessage"];
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        onFieldSubmitted: (value) => signInProcess(),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return translations["passwordValidationMessage"];
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: translations["passwordLabel"],
                          // Hungarian Translation
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Based on passwordVisible state choose the icon
                              passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // Update the state i.e. toogle the state of passwordVisible variable
                              setState(() {
                                passwordVisible = !passwordVisible;
                              });
                            },
                          ),
                        ),
                        controller: _passwordController,
                        obscureText: !passwordVisible,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => showPasswordResetRequestDialog(context),
                    child: Text(translations["passwordResetRequestPrompt"]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: Text(translations["registrationPrompt"]),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  await signInProcess();
                },
                child: Text(translations["loginPrompt"]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> signInProcess() async {
    // Sign in with email and password
    try {
      if (!(_signInFormKey.currentState?.validate() ?? true)) {
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // ignore: prefer_const_literals_to_create_immutables
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                      "${translations["loginPrompt"]}..."), // Hungarian Translation
                ],
              ),
            ),
          );
        },
      );
      if (await login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim())) {
        Restart.restartApp();
      } else {
        throw "Hiba";
      }
    } catch (e) {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: e.toString(), // Hungarian Translation
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }
}

void showPasswordResetRequestDialog(BuildContext context) {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(translations["passwordResetRequestPrompt"]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(translations["passwordResetInstructions"]),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: translations["emailLabel"],
                ),
                controller: emailController,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Send password reset email
                try {
                  await auth.sendPasswordResetEmail(
                      email: emailController.text);
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                      msg: translations["passwordResetRequestSuccess"]
                          .replaceAll("{{email}}", emailController.text));
                } catch (e) {
                  // Handle error
                }
              },
              child: Text(translations["submitPasswordResetRequest"]),
            ),
          ],
        ),
      );
    },
  );
}
