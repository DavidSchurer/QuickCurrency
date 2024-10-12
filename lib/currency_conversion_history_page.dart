import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyConversionHistoryPage extends StatefulWidget {
  final bool isGuest;
  const CurrencyConversionHistoryPage({Key? key, this.isGuest = false}) : super(key: key);


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

  Future<List<Conversion>> _loadConversionHistoryFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('conversionHistory') ?? [];

    List<Conversion> conversions = history.map((entry) {
      List<String> parts = entry.split('|');
      return Conversion(
        date: parts[4],
        fromCurrency: parts[0],
        toCurrency: parts[2],
        amount: double.parse(parts[1]),
        conversionRate: double.parse(parts[3]),
      );
    }).toList();

    conversions.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

    return conversions;
  }

  Widget _buildConversionHistoryTable(List<Conversion> conversions) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: FittedBox(
        child: DataTable(
          headingRowHeight: 56.0,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          dataTextStyle: const TextStyle(
            color: Colors.black,
          ),
          border: TableBorder.all(
            color: Colors.black,
            width: 1,
          ),
          columns: const <DataColumn>[
            DataColumn(label: Text('Selected Currency')),
            DataColumn(label: Text('Selected Amount')),
            DataColumn(label: Text('Converted Currency')),
            DataColumn(label: Text('Converted Amount')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Delete Conversion')),
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
              DataCell(
                GestureDetector(
                  onTap: () async {
                    try {
                      await FirebaseFirestore.instance
                        .collection('conversions')
                        .doc(conversion.date)
                        .delete();

                        setState(() {
                          conversions.remove(conversion);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Conversion deleted successfully'),
                        ));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error deleting conversion: $e'),
                      ));
                    }
                  },
                  child: const Icon(Icons.close, color: Colors.red), // Red X Icon for deletion
                )
              )
              ]);
          }).toList(),
        ),
      ),
    );
  }

 @override
 Widget build(BuildContext context) {
  if (widget.isGuest) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Conversion History'),
      ),
      body: FutureBuilder<List<Conversion>>(
          future: _loadConversionHistoryFromLocalStorage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No conversion history available'));
            }

            return Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF344D77),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildConversionHistoryTable(snapshot.data!),
              ),
            );
          },
      ),
    );
  } else {
      final user = _auth.currentUser;

      if (user == null) {
        if (!widget.isGuest) {
               return Scaffold(
          appBar: AppBar(
            title: const Text('Currency Conversion History'),
          ),
          body: const Center(
            child: Text('No conversion history available'),
          ),
        );
        }
      }

  return Scaffold(
    backgroundColor: Color.fromARGB(255, 147, 143, 143),
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 147, 143, 143),
      title: const Text('Currency Conversion History'),
    ),
    body: Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF344D77),
          borderRadius: BorderRadius.circular(16),
        ),
        child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection('conversions')
        .where('userEmail', isEqualTo: user?.email)
        .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No conversions found for ${user?.email}.',
              style: const TextStyle(color: Colors.white)));
          }

          final conversions = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Conversion.fromMap(data);
          }).toList();

          conversions.sort((a, b) {
            final dateA = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a.date!);
            final dateB = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b.date!);
            return dateB.compareTo(dateA);
          });

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 56.0,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              dataTextStyle: const TextStyle(
                color: Colors.black,
              ),
              border: TableBorder.all(
                color: Colors.black,
                width: 1,
              ),
              columns: const <DataColumn>[
                DataColumn(label: Text('Selected Currency')),
                DataColumn(label: Text('Selected Amount')),
                DataColumn(label: Text('Converted Currency')),
                DataColumn(label: Text('Converted Amount')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Delete Conversion')),
              ],
                rows: conversions.map((conversion) {
                  return DataRow(cells: <DataCell>[
                    DataCell(Text(conversion.fromCurrency ?? '')),
                    DataCell(Text(
                        '${getCurrencySymbol(conversion.fromCurrency ?? '')}${conversion.amount?.toStringAsFixed(2)}')),
                    DataCell(Text(conversion.toCurrency ?? '')),
                    DataCell(Text(
                        '${getCurrencySymbol(conversion.toCurrency ?? '')}${conversion.conversionRate?.toStringAsFixed(2)}')),
                    DataCell(Text(conversion.date ?? '')),
                    DataCell(
                      GestureDetector(
                        onTap: () async {
                          try {
                            await FirebaseFirestore.instance
                            .collection('conversions')
                            .doc(conversion.date)
                            .delete();

                            setState(() {
                              conversions.remove(conversion);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Conversion deleted successfully.'),
                            ));
                          } catch(e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Conversion deleted successfully.'),
                            ));
                            }
                          },
                          child: const Icon(Icons.close, color: Colors.red),
                      ),
                    ),
                  ]);
                }).toList(),
                 ),
                ),
              );
            },
          ),
        ),
      ),
    );
   }
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