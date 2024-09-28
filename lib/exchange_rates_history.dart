import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
      backgroundColor: Color.fromARGB(255, 147, 143, 143),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 147, 143, 143),
        title: Text('Exchange Rate History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 30,
            childAspectRatio: 1.0,
          ),
          itemCount: _dataMap.length,
          itemBuilder: (context, index) {
            final currency = _dataMap.keys.elementAt(index);
            final data = _dataMap[currency]!;

            return Container(
              decoration: BoxDecoration(
                color: Color(0xFF344D77),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '1 USD = ${data.last.rate.toStringAsFixed(2)} $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white, // Change text color for better visibility
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 300,
                    child: CustomPaint(
                      painter: ScatterPlotPainter(data),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
    const double scaleFactor = 1.5;

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

    final double scaledWidth = size.width * scaleFactor;
    final double scaledHeight = size.height * scaleFactor;

    // Draw X and Y axes, extended slightly past both ends
    canvas.drawLine(Offset(-80 * scaleFactor, scaledHeight - 40 * scaleFactor), Offset(scaledWidth + 80 * scaleFactor, scaledHeight - 40 * scaleFactor), axisPaint);
    canvas.drawLine(const Offset(80 * scaleFactor, 0), Offset(80 * scaleFactor, scaledHeight - 40 * scaleFactor), axisPaint);

    if (data.isEmpty) {
      return;
    }

    // Calculate min and max timestamps and rates
    final minTimeStamp = data.map((e) => DateTime.parse(e.date).millisecondsSinceEpoch).reduce((a, b) => a < b ? a : b);
    final maxTimeStamp = data.map((e) => DateTime.parse(e.date).millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b);
    final maxRate = data.map((e) => e.rate).reduce((a, b) => a > b ? a : b);
    final minRate = data.map((e) => e.rate).reduce((a, b) => a < b ? a : b);

    final maxRateExtended = maxRate * 1.05;
    final minRateExtended = minRate * 0.95;

    List <Offset> points = [];

    // Plot each data point
    for (var i = 0; i < data.length; i++) {
      double x = ((maxTimeStamp - DateTime.parse(data[i].date).millisecondsSinceEpoch) /
              (maxTimeStamp - minTimeStamp)) *
              (scaledWidth - 80 * scaleFactor) + 40 * scaleFactor;
      double y = scaledHeight - ((data[i].rate - minRateExtended) / (maxRateExtended - minRateExtended) * (scaledHeight - 50 * scaleFactor)) - 40 * scaleFactor;

      points.add(Offset(x, y));
      // Draw the dot
      canvas.drawCircle(Offset(x, y), 6, paint);

      // Draw the rate labels to the right of the y-axis, aligned with the dots
      TextSpan rateSpan = TextSpan(style: textStyle, text: data[i].rate.toStringAsFixed(2));
      TextPainter rateTp = TextPainter(text: rateSpan, textDirection: ui.TextDirection.ltr);
      rateTp.layout();
      rateTp.paint(canvas, Offset(80 * scaleFactor + 10 * scaleFactor, y - rateTp.height / 2));

      TextSpan dateSpan = TextSpan(style: textStyle, text: DateFormat('MM/dd').format(DateTime.parse(data[i].date)) + '\u200B');
      TextPainter dateTp = TextPainter(text: dateSpan, textDirection: ui.TextDirection.ltr);
      dateTp.layout();

      dateTp.paint(canvas, Offset(x - dateTp.width / 2, scaledHeight - 35 * scaleFactor));

          Paint linePaint = Paint()
            ..color = Colors.blue
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

            for (int i = 1; i < points.length; i++) {
              canvas.drawLine(points[i - 1], points[i], linePaint);
            }
    }

    // Draw the rate labels (min and max rate)
    var rateLabels = [minRateExtended, maxRateExtended];
    for (var i = 0; i < rateLabels.length; i++) {
      var y = i == 0 ? scaledHeight - 50 * scaleFactor : 0;
      TextSpan span = TextSpan(
        style: TextStyle (
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      text: rateLabels[i].toStringAsFixed(2),
      );
      TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(80 * scaleFactor + 10 * scaleFactor, y - 7 * scaleFactor));
    }
  }

  @override
  bool shouldRepaint(ScatterPlotPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}