import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'line_graph.dart';
import 'config.dart';
import 'models.dart';

void initializeFirebase() async {
  await Firebase.initializeApp();
}

class ExchangeRateHistoryPage extends StatefulWidget {
  @override
  _ExchangeRateHistoryPageState createState() =>
      _ExchangeRateHistoryPageState();
}

class _ExchangeRateHistoryPageState extends State<ExchangeRateHistoryPage> {
  final Map<String, List<ExchangeRateData>> _dataMap = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAndStoreCurrentRates();
    _fetchHistoricalData();
    _scheduleDataFetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndStoreCurrentRates() async {
    const String url =
        'https://api.freecurrencyapi.com/v1/latest?apikey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['data'];
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy-MM-dd').format(now);

        final currencies = ['CAD', 'MXN', 'EUR', 'GBP', 'JPY', 'AUD'];
        for (var currency in currencies) {
          await FirebaseFirestore.instance.collection('exchange_rates').add({
            'currency': currency,
            'rate': rates[currency] ?? 1.0,
            'date': formattedDate,
          });
        }

        print('Data fetched and stored successfully.');
        _fetchHistoricalData();
      }
    } catch (e) {
      print('Error fetching rates: $e');
    }
  }

  Future<void> _fetchHistoricalData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('exchange_rates').get();
      final Map<String, List<ExchangeRateData>> historicalDataMap = {};

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        final currency = data['currency'];
        final rate = data['rate'];
        final date = data['date'];

        if (!historicalDataMap.containsKey(currency)) {
          historicalDataMap[currency] = [];
        }
        historicalDataMap[currency]!.add(ExchangeRateData(currency, rate, date));
      });

      setState(() {
        _dataMap.clear();
        _dataMap.addAll(historicalDataMap);
      });
    } catch (e) {
      print('Error fetching historical data: $e');
    }
  }

  void _scheduleDataFetch() {
    const duration = Duration(hours: 12);
    _timer = Timer.periodic(duration, (Timer timer) async {
      await _fetchAndStoreCurrentRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exchange Rate History')),
      body: LineGraph(dataMap: _dataMap),
    );
  }
}