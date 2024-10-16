# <strong>QuickCurrency</strong>

## Overview
QuickCurrency is a currency converter web application designed to provide users with fast and accurate currency conversions built using Flutter and Firebase. The app allows users to convert between multiple currencies, view historical exchange rate graphs, and manage their conversion history. It integrates Flutter for the frontend user interface, Firebase for secure data management, and FreeCurrencyAPI for fetching up-to-date exchange rates.

## Live Website
<strong>https://currencyconverter-28b45.web.app/</strong>

## Features
- <strong>Real-time Currency Conversions:</strong> Instantly convert between 6 different currencies (USD, CAD, MXN, EUR, GBP, JPY, AUD) using the lastest up-to-date exchange rates fetched from FreeCurrencyAPI.
  
- <strong>Currency Conversion History:</strong> Stores each user's conversions in a currency conversion history page by saving each conversion in the firebase database, including the selected and converted currencies, their respective amounts, and the time at which the conversion was made. 
  
- <strong>Currency Conversion History Management:</strong> Provides functionality for the user to view past conversions, delete single entries in their currency conversion history, or clear their currency conversion history by deleting all entries.
  
- <strong>Exchange Rate History Visualization:</strong> Displays historical exchange rate data between USD and other currencies (GBP, JPY, AUD, CAD, MXN, EUR) using a custom scatter plot graph, with data fetched from FreeCurrencyAPI and stored in Firebase. The graphs dynamically update to display the latest exchange rate data.

- <strong>Firebase Authentication:</strong> Implemented with Firebase Authentication in order to ensure secure login, and enabling users to quickly sign up using an email and password.

## Tech Stack
- <strong>Frontend:</strong> Flutter (Dart)
- <strong>Backend:</strong> Firebase Firestore, Firebase Authentication
- <strong>API:</strong> FreeCurrencyAPI
- <strong>Deployment:</strong> Firebase Web Hosting

## Instructions
Instructions on how to use QuickCurrency:

1) Navigate to the live website at https://currencyconverter-28b45.web.app/, The user will be prompted with a brief welcome page, from there they can register or create an account to start using QuickCurrency.
       
2) After successfully signing in, click the "Choose Currency to Convert" button, and then select one of the six currently offered currencies to use as the base currency.

3) After selecting your base currency, enter a numeric value in the input field, and click on any of the grid boxes displaying other currencies to view the converted amount.

4) Use the navigation buttons in the footer to explore additional QuickCurrency features such as:
   - Checking current exchange rates relative to $1 of your base currency
   - Viewing and managing your currency conversion history
   - Viewing the exchange rate graphs
