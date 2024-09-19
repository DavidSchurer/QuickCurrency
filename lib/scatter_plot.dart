import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class ScatterPlotGraph extends StatelessWidget {
  final Map<String, List<ExchangeRateData>> dataMap;

  const ScatterPlotGraph({super.key, required this.dataMap});

  @override
  Widget build(BuildContext context) {
    final List<Widget> graphs = dataMap.entries.map((entry) {
      final currency = entry.key;
      final data = entry.value;
      final currentRate = data.isNotEmpty ? data.last.rate : 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1 USD = ${currentRate.toStringAsFixed(2)} $currency',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            height: 300,
            child: CustomPaint(
              painter: ScatterPlotPainter(data),
            ),
          ),
        ],
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: graphs,
    );
  }
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

      canvas.drawLine(Offset(40, size.height - 40), Offset(size.width, size.height - 40), axisPaint);
      canvas.drawLine(const Offset(40, 0), Offset(40, size.height - 40), axisPaint);

      if (data.isEmpty) {
        return;
      }

      final minTimeStamp = data.map((e) => DateTime.parse(e.date).millisecondsSinceEpoch).reduce((a, b) => a < b ? a : b);
      final maxTimeStamp = data.map((e) => DateTime.parse(e.date).millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b);

      final maxRate = data.map((e) => e.rate).reduce((a, b) => a > b ? a : b);

      for (var rateData in data) {
        double x = ((DateTime.parse(rateData.date).millisecondsSinceEpoch - minTimeStamp) / (maxTimeStamp - minTimeStamp) * (size.width - 50)) + 40;
        double y = size.height - ((rateData.rate / maxRate) * (size.height - 50)) - 40;

        canvas.drawCircle(Offset(x, y), 3, paint);
        }

        var dateLabels = [
          DateTime.fromMillisecondsSinceEpoch(minTimeStamp),
          DateTime.fromMillisecondsSinceEpoch(maxTimeStamp)
        ];

        for (var i = 0; i < dateLabels.length; i++) {
          var x = i == 0 ? 40 : size.width - 50;
          TextSpan span = TextSpan(style: textStyle, text: DateFormat('MM/dd').format(dateLabels[i]));
          TextPainter tp = TextPainter(
            text: span, 
            textDirection: ui.TextDirection.ltr);
          tp.layout();
          tp.paint(canvas, Offset(x.toDouble(), (size.height - 30).toDouble()));
        }

        var rateLabels = [0.0, maxRate];
        for (var i = 0; i < rateLabels.length; i++) {
          var y = i == 0 ? size.height - 50 : 0;
          TextSpan span = TextSpan(style: textStyle, text: rateLabels[i].toStringAsFixed(2));
          TextPainter tp = TextPainter(
            text: span, 
            textDirection: ui.TextDirection.ltr);
          tp.layout();
          tp.paint(canvas, Offset(10, y + 20));
        }
      }

      @override
      bool shouldRepaint(ScatterPlotPainter oldDelegate) {
        return oldDelegate.data != data;
      }
 }