import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'dart:async';

class ExchangeRatesHistoryPage extends StatefulWidget {
  @override
  _ExchangeRatesHistoryPageState createState() =>
      _ExchangeRatesHistoryPageState();
}

class _ExchangeRatesHistoryPageState extends State<ExchangeRatesHistoryPage> {
  Timer? _timer;
  Map<String, List<ExchangeRateData>> _dataMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAndStoreExchangeRates();

    _timer = Timer.periodic(Duration(hours: 24), (timer) {
      _fetchAndStoreExchangeRates();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndStoreExchangeRates() async {
    const String url =
        'https://api.freecurrencyapi.com/v1/latest?apikey=$apiKey&currencies=USD,GBP,JPY,AUD,CAD,MXN,EUR';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['data'];

        DateTime currentDate = DateTime.now();
        String formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);

        for (String currency in rates.keys) {
          double rate = rates[currency];

          final existingRate = await FirebaseFirestore.instance
              .collection('exchange_rates')
              .where('currency', isEqualTo: currency)
              .where('date', isEqualTo: formattedDate)
              .limit(1)
              .get();

          if (existingRate.docs.isEmpty) {
            await FirebaseFirestore.instance.collection('exchange_rates').add({
              'currency': currency,
              'rate': rate,
              'date': formattedDate,
            });
          }
        }

        await _fetchHistoricalData();
      } else {
        print('Error fetching exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rates: $e');
    }
  }

  Future<void> _fetchHistoricalData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exchange_rates')
          .orderBy('date')
          .get();

      final Map<String, Map<String, ExchangeRateData>> uniqueHistoricalDataMap =
          {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final currency = data['currency'];
        final rate = data['rate'];
        final date = data['date'];

        if (!uniqueHistoricalDataMap.containsKey(currency)) {
          uniqueHistoricalDataMap[currency] = {};
        }

        uniqueHistoricalDataMap[currency]![date] =
            ExchangeRateData(currency, rate, date);
      }

      Map<String, List<ExchangeRateData>> historicalDataMap = {};
      uniqueHistoricalDataMap.forEach((currency, dataMap) {
        historicalDataMap[currency] = dataMap.values.toList();
      });

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
        child: ListView.builder(
          itemCount: _dataMap.length,
          itemBuilder: (context, index) {
            final currency = _dataMap.keys.elementAt(index);
            final data = _dataMap[currency]!;

            return Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              padding: EdgeInsets.only(top: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Color(0xFF344D77),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '\$1 USD -> $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 400, // Increased the height of the graph
                    width: double.infinity, // Take full width of the screen
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
    const double labelPadding = 30.0;
    const double axisPadding = 50.0;

    // Adjusting the color of the lines to match the dots and setting bold lines
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0 // Slightly thicker than default but not too thick
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    // Adjust the placement of the graph within the available size
    final double graphWidth =
        size.width - 80; // Leave extra room for y-axis labels
    final double graphHeight =
        size.height - 60; // Leave 10px space for X axis labels

    // Shift the y-axis more towards the right to leave space for y-axis labels
    final Offset origin =
        Offset(30, size.height - 50); // Offset for x and y axis start

    // Draw X and Y axes with appropriate spacing
    canvas.drawLine(
      Offset(origin.dx, origin.dy),
      Offset(origin.dx + graphWidth, origin.dy), // X-axis from left to right
      axisPaint,
    );
    canvas.drawLine(
      Offset(origin.dx, origin.dy),
      Offset(origin.dx, origin.dy - graphHeight), // Y-axis from bottom to top
      axisPaint,
    );

    if (data.isEmpty) {
      return;
    }

    // Calculate min and max timestamps and rates
    final minTimeStamp = data
        .map((e) => DateTime.parse(e.date).millisecondsSinceEpoch)
        .reduce(min);
    final maxTimeStamp = data
        .map((e) => DateTime.parse(e.date).millisecondsSinceEpoch)
        .reduce(max);
    final maxRate = data.map((e) => e.rate).reduce(max);
    final minRate = data.map((e) => e.rate).reduce(min);

    final maxRateExtended = maxRate * 1.05;
    final minRateExtended = minRate * 0.95;

    List<Offset> points = [];

    // Calculate the interval for x-axis labels to avoid overcrowding
    int xLabelInterval =
        (data.length / 5).ceil(); // Display roughly 5 date labels
    double lastXLabelPosition = -double.infinity;
    double lastYLabelPosition = -double.infinity;

for (int i = 0; i < data.length; i++) {
  double x = origin.dx + (i / (data.length - 1)) * graphWidth;
  double y = origin.dy - ((data[i].rate - minRateExtended) / (maxRateExtended - minRateExtended) * (graphHeight * 2));

  points.add(Offset(x, y));

  // Draw the dot
  canvas.drawCircle(Offset(x, y), 4, paint);

  // Draw x-axis date labels
  if (i % 1 == 0) { // label every single dot
    final dateLabel = DateFormat('MM/dd').format(DateTime.parse(data[i].date));
    final dateSpan = TextSpan(style: textStyle, text: dateLabel);
    final dateTp = TextPainter(text: dateSpan, textDirection: ui.TextDirection.ltr);
    dateTp.layout();

    canvas.save();
    canvas.translate(x - dateTp.width / 2, origin.dy + 25); // adjust position above x-axis
    canvas.rotate(-pi / 4);
    dateTp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  // Draw y-axis rate labels
  final rateLabel = data[i].rate.toStringAsFixed(2);
  final rateSpan = TextSpan(style: textStyle, text: rateLabel);
  final rateTp = TextPainter(text: rateSpan, textDirection: ui.TextDirection.ltr);
  rateTp.layout();

  rateTp.paint(canvas, Offset(origin.dx - rateTp.width - 15, y - rateTp.height / 2)); // position near y-axis
}

    // Connect the points with lines of the same color as the dots
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
