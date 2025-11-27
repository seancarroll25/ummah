import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'test_aVutuZrKfnrBKOnfDeUkBFBLlAU';
  } else if (Platform.isAndroid) {
    apiKey = 'test_aVutuZrKfnrBKOnfDeUkBFBLlAU';
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}