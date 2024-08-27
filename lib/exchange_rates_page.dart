import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class ExchangeRatesPage extends StatefulWidget {
  const ExchangeRatesPage({super.key});

  @override
  _ExchangeRatesPageState createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends State<ExchangeRatesPage> {
  final Map<String, List<FlSpot>> historicalRates = {};
  final Map<String, double> currentRates = {};
  final List<String> currencies = ['GBP', 'JPY', 'AUD', 'CAD', 'MXN', 'EUR'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCurrentRates();
    fetchHistoricalRates();
  }

  Future<void> fetchCurrentRates() async {
    const String apiKey = 'e93a69020e0c3e3ab120f0d99dc321ae';
    final String url = 'http://data.fixer.io/api/latest?access_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            for (var currency in currencies) {
              currentRates[currency] = data['rates'][currency];
            }
          });
        } else {
          print('Error fetching current rates: ${data['error']['info']}');
        }
      } else {
        print(
            'Failed to fetch current rates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchHistoricalRates() async {
    const String apiKey = 'e93a69020e0c3e3ab120f0d99dc321ae';
    final DateTime now = DateTime.now();
    final List<FlSpot> emptyList =
        List.generate(30, (index) => FlSpot(index.toDouble(), 0.0));

    // Initialize historicalRates with empty lists
    for (var currency in currencies) {
      historicalRates[currency] = List.from(emptyList);
    }

    try {
      // Fetch data for each day for the last 30 days
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now()
            .subtract(Duration(days: i))
            .toIso8601String()
            .split('T')[0];
        final String url = 'http://data.fixer.io/api/$date?access_key=$apiKey';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            for (var currency in currencies) {
              if (data['rates'].containsKey(currency)) {
                final index = 29 - i; // To display recent data at the end
                setState(() {
                  historicalRates[currency]![index] =
                      FlSpot(i.toDouble(), data['rates'][currency]);
                });
              }
            }
          } else {
            print('Error fetching historical rates: ${data['error']['info']}');
          }
        } else {
          print(
              'Failed to fetch historical rates. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Rates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final data = historicalRates[currency]!;
                  final currentRate = currentRates[currency] ?? 0.0;

                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 USD = ${currentRate.toStringAsFixed(2)} $currency',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          value.toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          value.toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: data,
                                  isCurved: true,
                                  color: Colors.blueAccent,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
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
