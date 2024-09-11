import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyConversionHistoryPage extends StatefulWidget {

  @override
  _CurrencyConversionHistoryPageState createState() =>
    _CurrencyConversionHistoryPageState();
}

class _CurrencyConversionHistoryPageState extends State<CurrencyConversionHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<List<String>> _history = [];
  List<Conversion> _conversions = [];

  @override
  void initState() {
    super.initState();
    _getUser();
    FirebaseFirestore.instance.collection('conversions').addListener(_loadHistory);
  }

  void _getUser() async {
    final User? user = _auth.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('Logged in as: ${user.email}');
      } else {
        print('Not logged in');
      }
    });
  }

  Future<void> _loadHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final conversions = await FirebaseFirestore.instance
        .collection('conversions')
        .doc(userId)
        .get();
      final history = conversions.data()?['history'] as List<Map<String, dynamic>>? ?? [];
      setState(() {
        _conversions = history.map((conversion) => Conversion.fromMap(conversion)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Conversion History'),
      ),
      body: ListView.builder(
        itemCount: _conversions.length,
        itemBuilder: (context, index) {
          final conversion = _conversions[index];
          return ListTile(
            title: Text('${conversion.fromCurrency} to ${conversion.toCurrency}'),
            subtitle: Text('${conversion.amount} ${conversion.fromCurrency} = ${conversion.toCurrency} ${conversion.conversionRate}'),
            trailing: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(conversion.date as DateTime)),
          );
        },
      )
    );
  }
}

extension on CollectionReference<Map<String, dynamic>> {
  void addListener(Future<void> Function() loadHistory) {}
}

class Conversion {
  final String? date;
  final String? fromCurrency;
  final String? toCurrency;
  final double? amount;
  final double? conversionRate;

  Conversion({
    required this.date,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.conversionRate,
  });

  factory Conversion.fromMap(Map<String, dynamic> map) {
    return Conversion(
      date: map['date'] as String,
      fromCurrency: map['fromCurrency'] as String,
      toCurrency: map['toCurrency'] as String,
      amount: map['amount'] as double,
      conversionRate: map['conversionRate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
    };
  }
}