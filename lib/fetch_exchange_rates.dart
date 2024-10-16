import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Disable Firestore persistence
  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);

  // Retrieve API key from environment variable
  final String freeCurrencyAPIKey = Platform.environment['FREECURRENCYAPI_KEY'] ?? '';

  // URL for fetching exchange rates
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

        // Check if the exchange rate already exists in Firestore
        final existingRate = await FirebaseFirestore.instance
            .collection('exchange_rates')
            .where('currency', isEqualTo: currency)
            .where('date', isEqualTo: formattedDate)
            .limit(1)
            .get();

        // If not, add the new rate to Firestore
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
