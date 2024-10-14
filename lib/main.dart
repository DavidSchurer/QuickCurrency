import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'exchange_rates_page.dart';
import 'currency_conversion_history_page.dart';
import 'welcome_page.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'exchange_rates_history.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final bool isGuest;
  const MyApp({Key? key, this.isGuest = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      home: const WelcomePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/ExchangeRates') {
          final args = settings.arguments as String;
          return MaterialPageRoute(
              builder: (context) => ExchangeRatesPage(selectedCurrency: args));
        } else if (settings.name == '/CurrencyConversionHistory') {
          return MaterialPageRoute(
              builder: (context) =>
                  CurrencyConversionHistoryPage(isGuest: isGuest));
        } else if (settings.name == '/CurrencyConverterHomePage') {
          return MaterialPageRoute(
              builder: (context) => const CurrencyConverterHomePage());
        } else if (settings.name == '/ExchangeRatesHistory') {
          return MaterialPageRoute(
              builder: (context) => ExchangeRatesHistoryPage());
        }
        return null;
      },
    );
  }
}

class CurrencyConverterHomePage extends StatefulWidget {
  final bool isGuest;
  const CurrencyConverterHomePage({Key? key, this.isGuest = false})
      : super(key: key);

  @override
  _CurrencyConverterHomePageState createState() =>
      _CurrencyConverterHomePageState();
}

class _CurrencyConverterHomePageState extends State<CurrencyConverterHomePage> {
  String _selectedCurrencyText = "Enter USD Amount";
  String _hintText = "Enter amount in USD";
  String? loggedInUserEmail;

  final usdController = TextEditingController();
  double inputAmount = 0.0;
  String selectedCurrency = "USD";
  final Map<String, double> exchangeRates = {};
  Map<String, double> convertedAmounts = {};

  final Map<String, String> currencySymbols = {
    'USD': '\$',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'MXN': 'MX\$',
    'EUR': '€',
  };

  String? _selectedCurrencyCode;
  double? _selectedCurrencyConversion;

  @override
  void initState() {
    super.initState();
    usdController.addListener(_updateInputAmount);
    fetchExchangeRates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCurrencyPopup());
    _getCurrentUser();
  }

  @override
  void dispose() {
    usdController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    if (widget.isGuest) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        loggedInUserEmail = user.email;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _saveSelectedCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedCurrency', selectedCurrency);
  }

  Future<void> _loadSelectedCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCurrency = prefs.getString('selectedCurrency');

    if (storedCurrency != null) {
      setState(() {
        selectedCurrency = storedCurrency;
        _updateSelectedCurrencyText();
      });
    }
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCurrency = prefs.getString('selectedCurrency');
    double? savedAmount = prefs.getDouble('inputAmount');
    double? savedConversion = prefs.getDouble('conversionRate');

    if (savedCurrency != null) {
      setState(() {
        selectedCurrency = savedCurrency;
        _updateSelectedCurrencyText();
        inputAmount = savedAmount ?? 0.0;
        _convertAllCurrencies();
        _selectedCurrencyCode = savedCurrency;
        _selectedCurrencyConversion = savedConversion;
      });
    }
  }

  Future<void> _saveConversionHistoryToFirestore(Conversion conversion) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userEmail = user.email;
      await FirebaseFirestore.instance.collection('conversions').add({
        'selectedCurrency': selectedCurrency,
        'userEmail': userEmail,
        'fromCurrency': conversion.fromCurrency,
        'toCurrency': conversion.toCurrency,
        'amount': conversion.amount,
        'conversionRate': conversion.conversionRate,
        'date': conversion.date,
      });
    }
  }

  Future<void> _saveConversionHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('conversionHistory') ?? [];

    String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String entry =
        '$selectedCurrency|$inputAmount|$_selectedCurrencyCode|${_selectedCurrencyConversion?.toStringAsFixed(2)}|$timestamp';

    history.add(entry);
    await prefs.setStringList('conversionHistory', history);

    Conversion conversion = Conversion(
      date: timestamp,
      fromCurrency: selectedCurrency,
      toCurrency: _selectedCurrencyCode!,
      amount: inputAmount,
      conversionRate: _selectedCurrencyConversion!,
    );

    await _saveConversionHistoryToFirestore(conversion);
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.15,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF344D77),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                height: 400,
                child: Column(
                  children: [
                    const Text(
                      "QuickCurrency",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      "Quick and Easy Exchange Rates",
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      child: Image.asset('assets/popupimage.png'),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton(
                        onPressed: () {
                          _chooseCurrencyPopup();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                        ),
                        child: const Text(
                          "Choose Currency to Convert",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: Colors
                    .transparent, // Transparent for custom container styling
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF344D77),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.black, width: 2), // Added black border
                  ),
                  padding: const EdgeInsets.all(
                      16.0), // Add padding inside the border
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Select Currency",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(
                          height: 16), // Add space between title and content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: exchangeRates.keys.map((currency) {
                          bool isHovering = false;
                          bool isSelected = false;

                          return StatefulBuilder(
                            builder: (context, setInnerState) {
                              return MouseRegion(
                                onEnter: (_) =>
                                    setInnerState(() => isHovering = true),
                                onExit: (_) =>
                                    setInnerState(() => isHovering = false),
                                child: GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      selectedCurrency = currency;
                                      _updateSelectedCurrencyText();
                                      usdController.text = '';
                                      inputAmount = 0.0;
                                      convertedAmounts.clear();
                                    });
                                    await _saveSelectedCurrency();
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isHovering || isSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 20),
                                    child: Center(
                                      child: Text(
                                        currency,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
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

  void _navigateToExchangeRatesPage() {
    Navigator.pushNamed(
      context,
      '/ExchangeRates',
      arguments: selectedCurrency,
    );
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF344D77),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _selectedCurrencyText,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usdController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: Colors.black,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        labelText: selectedCurrency,
                        labelStyle:
                            const TextStyle(fontSize: 18, color: Colors.black),
                        hintText: _hintText,
                        hintStyle:
                            const TextStyle(fontSize: 18, color: Colors.black),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: exchangeRates.keys
                    .where((currencyCode) => currencyCode != selectedCurrency)
                    .map((currencyCode) {
                  bool isSelected = currencyCode == _selectedCurrencyCode;

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedCurrencyCode = currencyCode;
                        _selectedCurrencyConversion =
                            convertedAmounts[currencyCode] ?? 0.0;
                      });

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setString('selectedCurrency', selectedCurrency);
                      prefs.setDouble('inputAmount', inputAmount);
                      prefs.setDouble(
                          'conversionRate', _selectedCurrencyConversion ?? 0.0);

                      await _saveConversionHistory();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF344D77)
                            : const Color(0xFF344D77),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
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
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/$currencyCode.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currencyCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (isSelected &&
                              _selectedCurrencyConversion != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${currencySymbols[currencyCode]} ${_selectedCurrencyConversion?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 58, 58, 58),
            width: 5,
          ),
        ),
        child: BottomAppBar(
          color: Color.fromARGB(255, 100, 100, 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _navigateToExchangeRatesPage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF344D77),
                ),
                child: const Text('Current Exchange Rates',
                    style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/CurrencyConversionHistory');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF344D77),
                ),
                child: const Text('View Currency Conversion History',
                    style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/ExchangeRatesHistory');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF344D77),
                ),
                child: const Text('View Exchange Rate Graph',
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}