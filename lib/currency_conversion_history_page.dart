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

  final Map<String, String> currencySymbols = {
    'USD': '\$',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'MXN': 'MX\$',
    'EUR': '€',
  };

  String getCurrencySymbol(String currencyCode) {
    return currencySymbols[currencyCode] ?? '';
  }

 @override
 Widget build(BuildContext context) {
  final user = _auth.currentUser;

  if (user == null) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Conversion History'),
      ),
      body: Center(
        child: Text('User not logged in'),
      ),
    );
  }
  return Scaffold(
    appBar: AppBar(
      title: Text('Currency Conversion History'),
    ),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
      .collection('conversions')
      .where('userEmail', isEqualTo: user.email)
      .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No conversions found for ${user.email}.'));
        }

        final conversions = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Conversion.fromMap(data);
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Selected Currency')),
                DataColumn(label: Text('Selected Amount')),
                DataColumn(label: Text('Converted Currency')),
                DataColumn(label: Text('Converted Amount')),
                DataColumn(label: Text('Date')),
              ],
                rows: conversions.map((conversion) {
                  return DataRow(cells: <DataCell>[
                    DataCell(Text(conversion.fromCurrency ?? '')),
                    DataCell(Text(
                        '${getCurrencySymbol(conversion.fromCurrency ?? '')}${conversion.amount.toString()}')),
                    DataCell(Text(conversion.toCurrency ?? '')),
                    DataCell(Text(
                        '${getCurrencySymbol(conversion.toCurrency ?? '')}${conversion.conversionRate.toString()}')),
                    DataCell(Text(conversion.date ?? '')),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
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
      date: map['date'] != null ? map['date'] as String : '',
      fromCurrency: map['fromCurrency'] != null ? map['fromCurrency'] as String : '',
      toCurrency: map['toCurrency'] != null ? map['toCurrency'] as String : '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (map['conversionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
      'conversionRate': conversionRate,
    };
  }
}