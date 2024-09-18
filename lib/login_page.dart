import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CurrencyConverterHomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Container(
              width: 600,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF344D77),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                 children: [
                  const Text(
                    "Login to QuickCurrency",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white), // White label text
                      filled: true,
                      fillColor: Colors.white24, // Light background for input field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white), // White text for the input
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white), // White label text
                      filled: true,
                      fillColor: Colors.white24, // Light background for input field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white), // White text for the input
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(0xFF344D77), backgroundColor: Colors.white, // Text color inside the button
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register here.",
                      style: TextStyle(color: Colors.white), // White text for the link
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Add space below the box
          ],
        ),
      ),
    );
  }
}