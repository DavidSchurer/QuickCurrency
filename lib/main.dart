import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'exchange_rates_page.dart'; // Import the new page
import 'config.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CurrencyConverterHomePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/ExchangeRates') {
          return MaterialPageRoute(
              builder: (context) => const ExchangeRatesPage());
        }
        return null;
      },
    );
  }
}

class CurrencyConverterHomePage extends StatefulWidget {
  const CurrencyConverterHomePage({super.key});

  @override
  _CurrencyConverterHomePageState createState() =>
      _CurrencyConverterHomePageState();
}

class _CurrencyConverterHomePageState extends State<CurrencyConverterHomePage> {
  final usdController = TextEditingController();
  double usdAmount = 0.0;
  final Map<String, double> exchangeRates = {};
  Map<String, double> convertedAmounts = {};

  @override
  void initState() {
    super.initState();
    usdController.addListener(_updateUsdAmount);
    fetchExchangeRates();
  }

  @override
  void dispose() {
    usdController.dispose();
    super.dispose();
  }

  Future<void> fetchExchangeRates() async {
    const String url =
        'https://api.freecurrencyapi.com/v1/latest?apikey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          setState(() {
            exchangeRates['CAD'] = data['data']['CAD'];
            exchangeRates['MXN'] = data['data']['MXN'];
            exchangeRates['EUR'] = data['data']['EUR'];
            exchangeRates['GBP'] = data['data']['GBP'];
            exchangeRates['JPY'] = data['data']['JPY'];
            exchangeRates['AUD'] = data['data']['AUD'];
          });
        } else {
          print('Error fetching exchange rates: Invalid data received');
        }
      } else {
        print(
            'Failed to fetch exchange rates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _updateUsdAmount() {
    String text = usdController.text;
    text = _sanitizeInput(text);

    if (text.isEmpty) {
      setState(() {
        usdAmount = 0.0;
        convertedAmounts.clear();
      });
      return;
    }

    usdAmount = double.tryParse(text) ?? 0.0;
    String formattedText = '\$${_formatNumber(usdAmount)}';

    setState(() {
      usdController.value = usdController.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
      _convertAllCurrencies();
    });
  }

  String _sanitizeInput(String input) {
    final RegExp exp = RegExp(r'[^0-9.]');
    String sanitized = input.replaceAll(exp, '');

    int periodCount = sanitized.split('.').length - 1;
    if (periodCount > 1) {
      sanitized = sanitized.replaceAll(RegExp(r'\.(?=.*\.)'), '');
    }

    return sanitized;
  }

  void _convertAllCurrencies() {
    setState(() {
      convertedAmounts = exchangeRates.map((currencyCode, rate) {
        return MapEntry(currencyCode, usdAmount * rate);
      });
    });
  }

  String _formatNumber(double number) {
    return NumberFormat.decimalPattern().format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              "QuickCurrency",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter USD Amount",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: usdController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "USD",
                hintText: "Enter amount in USD",
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: exchangeRates.keys.map((currencyCode) {
                  return Container(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                          child: const Icon(
                            Icons.flag,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currencyCode,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (convertedAmounts.containsKey(currencyCode))
                          Text(
                            "$currencyCode: ${_formatNumber(convertedAmounts[currencyCode]!)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/ExchangeRates');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text('Current Exchange Rates',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}