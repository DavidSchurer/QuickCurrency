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
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'MXN': 'MX\$',
    'EUR': '€',
  };
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
      body: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
                color: const Color(0xFF344D77),
                border: Border.all(color: Color(0xFF657898), width: 5)),
            child: Center(
              child: Text(
                "Exchange Rate History Graphs",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _dataMap.length,
                itemBuilder: (context, index) {
                  final currency = _dataMap.keys.elementAt(index);
                  final data = _dataMap[currency]!;

                  if (currency == 'USD') {
                    return SizedBox(height: 0);
                  } else {
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
                            'USD to $currency Exchange Rate History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 300,
                            width: double
                                .infinity, // Take full width of the screen
                            child: CustomPaint(
                              painter: ScatterPlotPainter(data, currency),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
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
  final String currency;

  ScatterPlotPainter(this.data, this.currency);

  @override
  void paint(Canvas canvas, Size size) {
    String currencySymbol = "";
    switch (currency) {
      case 'USD':
        currencySymbol = '\$';
        break;
      case 'EUR':
        currencySymbol = '€';
        break;
      case 'GBP':
        currencySymbol = '£';
        break;
      case 'JPY':
        currencySymbol = '¥';
        break;
      case 'AUD':
        currencySymbol = 'AU\$';
        break;
      case 'CAD':
        currencySymbol = 'CA\$';
        break;
      case 'MXN':
        currencySymbol = 'MX\$';
        break;
      default:
        currencySymbol = '';
        break;
    }

    const double labelPadding = 30.0;
    const double axisPadding = 50.0;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    // Adjust the placement of the graph within the available size
    final double graphWidth = size.width - 80; // Leave space for y-axis labels
    final double graphHeight =
        size.height - 60; // Leave space for X-axis labels

    final Offset origin =
        Offset(40, size.height - 40); // Starting point for axes

    // Draw X and Y axes
    canvas.drawLine(
      Offset(origin.dx + 20, origin.dy),
      Offset(origin.dx + 20 + graphWidth, origin.dy), // X-axis
      axisPaint,
    );
    canvas.drawLine(
      Offset(origin.dx + 20, origin.dy),
      Offset(origin.dx + 20, origin.dy - graphHeight), // Y-axis
      axisPaint,
    );

    final xAxisTitleSpan = TextSpan(
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        text: 'Date');
    final xAxisTitleTp =
        TextPainter(text: xAxisTitleSpan, textDirection: ui.TextDirection.ltr);
    xAxisTitleTp.layout();
    canvas.save();
    canvas.translate(origin.dx + graphWidth / 2 - xAxisTitleTp.width / 2,
        origin.dy + axisPadding - 20);
    xAxisTitleTp.paint(canvas, Offset.zero);
    canvas.restore();

    final yAxisTitleSpan = TextSpan(
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        text: '$currency($currencySymbol)');
    final yAxisTitleTp =
        TextPainter(text: yAxisTitleSpan, textDirection: ui.TextDirection.ltr);
    yAxisTitleTp.layout();
    canvas.save();
    canvas.translate(origin.dx + 10,
        origin.dy - graphHeight / 2 - yAxisTitleTp.height / 2 - 135);
    yAxisTitleTp.paint(canvas, Offset.zero);
    canvas.restore();

    if (data.isEmpty) return;

    // Calculate min and max timestamps and rates
    final minTimeStamp = data
        .map((e) => DateTime.parse(e.date).millisecondsSinceEpoch)
        .reduce(min);
    final maxTimeStamp = data
        .map((e) => DateTime.parse(e.date).millisecondsSinceEpoch)
        .reduce(max);
    final maxRate = data.map((e) => e.rate).reduce(max);
    final minRate = data.map((e) => e.rate).reduce(min);

    final range = maxRate - minRate;

    final numIntervals = 5;

    final intervalSize = range / numIntervals;

    final relativeRates = [
      for (int i = 0; i <= numIntervals; i++)
        (minRate + (i * intervalSize)).toStringAsFixed(2)
    ];

    final maxRateExtended = maxRate * 1.05;
    final minRateExtended = minRate * 0.95;

    List<Offset> points = [];

    // Draw points and connect them with lines
    for (int i = 0; i < data.length; i++) {
      double x;
      if (i == 0) {
        x = origin.dx + 20 + (i / (data.length - 1)) * graphWidth;
      } else {
        x = origin.dx + (i / (data.length - 1)) * graphWidth;
      }
      double y = origin.dy -
          ((data[i].rate - minRateExtended) /
              (maxRateExtended - minRateExtended) *
              graphHeight); // Y position

      points.add(Offset(x, y));

      // Draw the dot
      canvas.drawCircle(Offset(x, y), 4, paint);

      // Draw x-axis date labels
      if (i % (data.length ~/ 5) == 0) {
        // label every few dots
        final dateLabel =
            DateFormat('MM/dd').format(DateTime.parse(data[i].date));
        final dateSpan = TextSpan(
            style: textStyle.copyWith(fontWeight: FontWeight.bold),
            text: dateLabel);
        final dateTp =
            TextPainter(text: dateSpan, textDirection: ui.TextDirection.ltr);
        dateTp.layout();

        canvas.save();
        canvas.translate(x - dateTp.width / 2,
            origin.dy + 10); // adjust position above x-axis
        dateTp.paint(canvas, Offset.zero);
        canvas.restore();
      }

      final yAxisLabelStyle = TextStyle(
        color: Colors.black,
        fontSize: 12,
      );

      // Draw y-axis rate labels
      for (int i = 0; i <= numIntervals; i++) {
        final rateLabel = relativeRates[i];
        final rateSpan = TextSpan(style: yAxisLabelStyle, text: rateLabel);
        final rateTp =
            TextPainter(text: rateSpan, textDirection: ui.TextDirection.ltr);
        rateTp.layout();

        rateTp.paint(
            canvas,
            Offset(
                origin.dx - rateTp.width + 7,
                origin.dy -
                    (i * intervalSize / range) * graphHeight -
                    rateTp.height / 2));
      }
    }

    // Connect the points with lines
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
