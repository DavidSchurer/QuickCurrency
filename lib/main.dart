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

  String _selectedCurrencyText = "Enter USD Amount";
  String _hintText = "Enter amount in USD";

  final usdController = TextEditingController();
  double inputAmount = 0.0;
  String selectedCurrency = "USD";
  final Map<String, double> exchangeRates = {};
  Map<String, double> convertedAmounts = {};

  @override
  void initState() {
    super.initState();
    usdController.addListener(_updateInputAmount);
    fetchExchangeRates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCurrencyPopup());
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
            exchangeRates['USD'] = 1.0;
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

  void _updateInputAmount() {
    String text = usdController.text;
    text = _sanitizeInput(text);

    if (text.isEmpty) {
      setState(() {
        inputAmount = 0.0;
        convertedAmounts.clear();
      });
      return;
    }

    inputAmount = double.tryParse(text) ?? 0.0;
    String formattedText = '\$${_formatNumber(inputAmount)}';

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
    double amountInUsd = (selectedCurrency == 'USD')
    ? inputAmount
    : inputAmount / exchangeRates[selectedCurrency]!;

    setState(() {
      convertedAmounts = exchangeRates.map((currencyCode, rate) {
        return MapEntry(currencyCode, amountInUsd * rate);
      });
    });
  }

  String _formatNumber(double number) {
    return NumberFormat.decimalPattern().format(number);
  }

  void _showCurrencyPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container (
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF344D77),
              borderRadius: BorderRadius.circular(20),
            ),
            height: 400,
            child: Column(
              children: [
                const Text(
                  "QuickCurrency",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Quick and Easy Exchange Rates",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _chooseCurrencyPopup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    "Choose Currency to Convert",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _chooseCurrencyPopup() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Currency"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: exchangeRates.keys.map((currency) {
              return ListTile(
                title: Text(currency),
                onTap: () {
                  setState(() {
                    selectedCurrency = currency;
                    _updateSelectedCurrencyText();
                    usdController.text = '';
                    inputAmount = 0.0;
                    convertedAmounts.clear();
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _updateSelectedCurrencyText() {
    setState(() {
      _selectedCurrencyText = "Enter $selectedCurrency Amount";
      _hintText = "Enter amount in $selectedCurrency";
    });
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
             Text(
              _selectedCurrencyText,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: usdController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: selectedCurrency,
                hintText: _hintText,
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
                          Text(
                            convertedAmounts[currencyCode]?.toStringAsFixed(2) ?? '0.00',
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