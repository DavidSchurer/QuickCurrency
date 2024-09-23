import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

class ExchangeRatesHistoryPage extends StatefulWidget {
  @override
  _ExchangeRatesHistoryPageState createState() =>
      _ExchangeRatesHistoryPageState();
}

class _ExchangeRatesHistoryPageState extends State<ExchangeRatesHistoryPage> {
  Map<String, List<ExchangeRateData>> _dataMap = {};

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  Future<void> _fetchHistoricalData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exchange_rates')
          .orderBy('date')
          .get();

      final Map<String, List<ExchangeRateData>> historicalDataMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final currency = data['currency'];
        final rate = data['rate'];
        final date = data['date'];

        if (!historicalDataMap.containsKey(currency)) {
          historicalDataMap[currency] = [];
        }

        historicalDataMap[currency]!.add(ExchangeRateData(currency, rate, date));
      }

      setState(() {
        _dataMap.clear();
        _dataMap.addAll(historicalDataMap);
      });
    } catch (e) {
      print('Error fetching historical data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exchange Rate History'),
      ),
      body: ListView(
        children: _dataMap.entries.map((entry) {
          final currency = entry.key;
          final data = entry.value;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  '1 USD = ${data.last.rate.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: ScatterPlotPainter(data),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ExchangeRateData {
  final String currency;
  final double rate;
  final String date;

  ExchangeRateData(this.currency, this.rate, this.date);
}

class ScatterPlotPainter extends CustomPainter {
  final List<ExchangeRateData> data;

  ScatterPlotPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    // Draw X and Y axes, extended slightly past both ends
    canvas.drawLine(Offset(-80, size.height - 40), Offset(size.width + 80, size.height - 40), axisPaint);
    canvas.drawLine(const Offset(80, 0), Offset(80, size.height - 40), axisPaint);

    if (data.isEmpty) {
      return;
    }

    // Calculate min and max timestamps and rates
    final minTimeStamp = data.map((e) => DateTime.parse(e.date).millisecondsSinceEpoch).reduce((a, b) => a < b ? a : b);
    final maxTimeStamp = data.map((e) => DateTime.parse(e.date).millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b);
    final maxRate = data.map((e) => e.rate).reduce((a, b) => a > b ? a : b);
    final minRate = data.map((e) => e.rate).reduce((a, b) => a < b ? a : b);

    // Plot each data point
    for (var rateData in data) {
      double x = ((DateTime.parse(rateData.date).millisecondsSinceEpoch - minTimeStamp) /
              (maxTimeStamp - minTimeStamp) *
              (size.width - 80)) + 40;
      double y = size.height - ((rateData.rate - minRate) / (maxRate - minRate) * (size.height - 50)) - 40;

      // Draw the dot
      canvas.drawCircle(Offset(x, y), 3, paint);

      // Draw the rate labels to the right of the y-axis, aligned with the dots
      TextSpan rateSpan = TextSpan(style: textStyle, text: rateData.rate.toStringAsFixed(2));
      TextPainter rateTp = TextPainter(text: rateSpan, textDirection: ui.TextDirection.ltr);
      rateTp.layout();
      rateTp.paint(canvas, Offset(45, y - rateTp.height / 2));
    }

    // Draw the date labels (slightly outside the x-axis range)
    var dateLabels = [
      DateTime.fromMillisecondsSinceEpoch(minTimeStamp),
      DateTime.fromMillisecondsSinceEpoch(maxTimeStamp)
    ];

    for (var i = 0; i < dateLabels.length; i++) {
      var x = i == 0 ? 40 : size.width - 60;
      TextSpan dateSpan = TextSpan(style: textStyle, text: DateFormat('MM/dd').format(dateLabels[i]));
      TextPainter dateTp = TextPainter(text: dateSpan, textDirection: ui.TextDirection.ltr);
      dateTp.layout();
      dateTp.paint(canvas, Offset(x.toDouble(), (size.height - 30).toDouble()));
    }

    // Draw the rate labels (min and max rate)
    var rateLabels = [minRate, maxRate];
    for (var i = 0; i < rateLabels.length; i++) {
      var y = i == 0 ? size.height - 50 : 0;
      TextSpan span = TextSpan(style: textStyle, text: rateLabels[i].toStringAsFixed(2));
      TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(10, y + 20));
    }
  }

  @override
  bool shouldRepaint(ScatterPlotPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}