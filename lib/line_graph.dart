import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'exchange_rates_page.dart'; 
import 'currency_conversion_history_page.dart';
import 'welcome_page.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'register_page.dart';
import 'exchange_rates_history.dart';
import 'login_page.dart';
import 'exchange_rates_history.dart';


class LineGraph extends StatefulWidget {
  final List<ExchangeRateData> data;
  final String title;
  final String xLabel;
  final String yLabel;

  LineGraph({
    required this.data,
    this.title = '',
    this.xLabel ='',
    this.yLabel = '',
    });

  @override
  _LineGraphState createState() => _LineGraphState();
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        CustomPaint(
          painter: LineGraphPainter(data, xLabel, yLabel),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 200,
          ),
        ),
      ],
    );
  }
}

class _LineGraphState extends State<LineGraph> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LineGraphPainter(widget.data, widget.xLabel, widget.yLabel),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 200,
      ),
    );
  }
}

class LineGraphPainter extends CustomPainter {
  final List<ExchangeRateData> data;
  final String xLabel;
  final String yLabel;

  LineGraphPainter(this.data, this.xLabel, this.yLabel);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      double x = (i / (data.length - 1)) * size.width;
      double y = size.height - (data[i].rate / data.last.rate) * size.height;
      points.add(Offset(x, y));
    }

    canvas.drawPoints(PointMode.lines, points, paint);

    // Draw xLabel and yLabel if needed
    final textPainter = TextPainter(
      text: TextSpan(
        text: xLabel,
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
      textAlign: TextAlign.left,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 8, size.height - 20));

    final yLabelPainter = TextPainter(
      text: TextSpan(
        text: yLabel,
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
      textAlign: TextAlign.left,
    );
    yLabelPainter.layout();
    yLabelPainter.paint(canvas, Offset(8, 8));
  }

  @override
  bool shouldRepaint(LineGraphPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.xLabel != xLabel || oldDelegate.yLabel != yLabel;
  }
}