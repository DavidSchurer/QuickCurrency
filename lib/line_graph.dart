import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class LineGraph extends StatelessWidget {
  final Map<String, List<ExchangeRateData>> dataMap;

  LineGraph({required this.dataMap});

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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            height: 200,
            child: CustomPaint(
              painter: LineGraphPainter(data),
            ),
          ),
        ],
      );
    }).toList();

    return ListView(
      padding: EdgeInsets.all(16.0),
      children: graphs,
    );
  }
}

class LineGraphPainter extends CustomPainter {
  final List<ExchangeRateData> data;

  LineGraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

      final axisPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1;

      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

      if (data.isEmpty) {
        return;
      }

      final List<Offset> points = [];
      final maxRate = data.map((e) => e.rate).reduce((a, b) => a > b ? a : b);

      for (int i = 0; i < data.length; i++) {
        double x = (i / (data.length - 1)) * size.width;
        double y = size.height - (data[i].rate / maxRate * size.height);
        points.add(Offset(x, y));
      }

      canvas.drawPoints(PointMode.polygon, points, paint);
  }

  @override
  bool shouldRepaint(LineGraphPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}