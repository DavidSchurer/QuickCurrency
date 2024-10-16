import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);

  final String freeCurrencyAPIKey = Platform.environment['FREECURRENCYAPI_KEY'] ?? '';

  final String url =
      'https://api.freecurrencyapi.com/v1/latest?apikey=$freeCurrencyAPIKey&currencies=USD,GBP,JPY,AUD,CAD,MXN,EUR';
  
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

        print('Exchange rates fetched and stored successfully.');
      } else {
        print('Error fetching exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rates: $e');
    }
  }