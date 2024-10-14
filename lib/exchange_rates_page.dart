import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExchangeRatesPage extends StatefulWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String selectedCurrency;
  
  ExchangeRatesPage({super.key, required this.selectedCurrency});

  @override
  _ExchangeRatesPageState createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends State<ExchangeRatesPage> {
  final Map<String, double> currentRates = {};
  final List<String> currencies = ['USD','GBP', 'JPY', 'AUD', 'CAD', 'MXN', 'EUR'];
  final Map<String, String> currencySymbols = {
    'USD': '\$',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'MXN': 'MX\$',
    'EUR': '€',
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUser();
    fetchCurrentRates();
  }

  void _getUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Logged in as: ${user.email}');
    } else {
      print('Not logged in');
    }
  }

  Future<void> fetchCurrentRates() async {
    final String url =
        'https://api.freecurrencyapi.com/v1/latest?apikey=$apiKey&base_currency=${widget.selectedCurrency}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['data'];

        setState(() {
          for (var currency in currencies) {
              currentRates[currency] = rates[currency];
          }
        });
      } else {
        print(
            'Failed to fetch current rates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 147, 143, 143),
              appBar: AppBar(
          toolbarHeight: 100,
        backgroundColor: Color.fromARGB(255, 100, 100, 100),
        centerTitle: true,
        shape:
            Border.all(color: const Color.fromARGB(255, 58, 58, 58), width: 5),
        title: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 100, 100, 100),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "QuickCurrency",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                "Quick and Easy Exchange Rates",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2 / 1,
                ),
                itemCount: currencies.length - 1,
                itemBuilder: (context, index) {
                  final currency = currencies.where((c) => c != widget.selectedCurrency).toList()[index];
                  final currentRate = (currentRates[currency] ?? 0.0);
                  final symbol = currencySymbols[currency] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF344D77),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '1 ${widget.selectedCurrency} = ${currentRate.toStringAsFixed(2)} $currency',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      ),
    );
  }
}