import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'exchange_rates_page.dart';
import 'currency_conversion_history_page.dart';
import 'line_graph.dart';
import 'welcome_page.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'register_page.dart';
import 'exchange_rates_history.dart';
import 'login_page.dart';

class ExchangeRateHistoryPage extends StatefulWidget {
  @override
  _ExchangeRateHistoryPageState createState() =>
      _ExchangeRateHistoryPageState();
}

class ExchangeRateData {
  final String currency;
  final double rate;

  ExchangeRateData(this.currency, this.rate);
}

class _ExchangeRateHistoryPageState extends State<ExchangeRateHistoryPage> {
  List<ExchangeRateData> _data = [];
  Map<String, List<ExchangeRateData>> _exchangeRates = {};

  Future<void> _fetchCurrentRates() async {
    final String url =
        'https://api.freecurrencyapi.com/v1/latest?apikey=$apiKey&base_currency=USD';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['data'];

        _exchangeRates = {
          'USD': [ExchangeRateData('USD', 1.0)],
          'CAD': [ExchangeRateData('CAD', rates['CAD'])],
          'MXN': [ExchangeRateData('MXN', rates['MXN'])],
          'EUR': [ExchangeRateData('EUR', rates['EUR'])],
          'GBP': [ExchangeRateData('GBP', rates['GBP'])],
          'JPY': [ExchangeRateData('JPY', rates['JPY'])],
          'AUD': [ExchangeRateData('AUD', rates['AUD'])],
        };

        _data = [
          ExchangeRateData('USD', 1.0),
          ExchangeRateData('CAD', rates['CAD']),
          ExchangeRateData('MXN', rates['MXN']),
          ExchangeRateData('EUR', rates['EUR']),
          ExchangeRateData('GBP', rates['GBP']),
          ExchangeRateData('JPY', rates['JPY']),
          ExchangeRateData('AUD', rates['AUD']),
        ];

        setState(() {});
      } else {
        print(
            'Failed to fetch current rates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentRates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exchange Rate History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: _exchangeRates.keys.map((currency) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Exchange Rates: $currency',
                            style: const TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 16),
                          LineGraph(
                            data: _exchangeRates[currency] ?? [],
                          )
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
    );
  }
}
