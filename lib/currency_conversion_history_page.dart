import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyConversionHistoryPage extends StatefulWidget {
  @override
  _CurrencyConversionHistoryPageState createState() =>
    _CurrencyConversionHistoryPageState();
}

class _CurrencyConversionHistoryPageState extends State<CurrencyConversionHistoryPage> {
  List<List<String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('conversionHistory') ?? [];

    setState(() {
      _history = history.map((entry) => entry.split('|')).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Conversion History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            border: TableBorder.all(
                color: const Color(0xF344D77),
                width: 2,
              ),
              columns: const [
                DataColumn(label: Text('Selected Currency')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Converted Currency')),
                DataColumn(label: Text('Converted Amount')),
                DataColumn(label: Text('Timestamp')),
              ],
              rows: _history.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(Text(entry[0])),
                    DataCell(Text(entry[1])),
                    DataCell(Text(entry[2])),
                    DataCell(Text(entry[3])),
                    DataCell(Text(entry[4])),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
  }
}