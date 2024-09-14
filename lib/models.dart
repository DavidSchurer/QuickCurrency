import 'package:flutter/material.dart';

class ExchangeRateData {
  final String currency;
  final double rate;
  final String date;

  ExchangeRateData(this.currency, this.rate, this.date);
}