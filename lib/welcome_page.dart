import 'package:flutter/material.dart';
import 'main.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
                    "Welcome to QuickCurrency",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Welcome to QuickCurrency! This currency converter strives to offer users a quick and easy way to convert currencies. We currently offer conversions in USD, CAD, MXN, EUR, GBP, JPY, and AUD. Each conversion you make will be stored in order for you to view and track your conversions across many visits. We also offer graphs to visually display the exchange rates over time. If you would like to get started, click the button below!",
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16), 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }
}