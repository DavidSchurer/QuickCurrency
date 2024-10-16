import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import axios from "axios";
import * as dotenv from "dotenv";

dotenv.config();
admin.initializeApp();

const apiKey = functions.config().freecurrencyapi.key; // API key from .env file
const currencies = "USD,GBP,JPY,AUD,CAD,MXN,EUR"; // List of currencies you want

export const fetchExchangeRates = functions.https.onRequest(async (req, res) => {
  // Remove manual PORT definition
  // Log to help debugging
  console.log(`Incoming request on Cloud Function.`);

  const url = `https://api.freecurrencyapi.com/v1/latest?apikey=${apiKey}&currencies=${currencies}`;

  try {
    const response = await axios.get(url);
    const rates = response.data.data;

    const currentDate = new Date().toISOString().split("T")[0]; // Format: YYYY-MM-DD

    const promises = Object.keys(rates).map(async (currency) => {
      const rate = rates[currency];
      const existingRate = await admin.firestore().collection("exchange_rates")
        .where("currency", "==", currency)
        .where("date", "==", currentDate)
        .get();

      if (existingRate.empty) {
        await admin.firestore().collection("exchange_rates").add({
          currency: currency,
          rate: rate,
          date: currentDate,
        });
      }
    });

    await Promise.all(promises);
    console.log("Exchange rates fetched and stored successfully.");
    res.status(200).send("Exchange rates fetched and stored successfully.");
  } catch (error) {
    console.error("Error fetching exchange rates:", error);
    res.status(500).send("Error fetching exchange rates.");
  }
});
