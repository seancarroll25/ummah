import 'package:flutter/material.dart';
import 'package:everythingapp/pages/MainPage.dart';
import 'package:everythingapp/services/LocationService.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Initialize RevenueCat before runApp
  await Purchases.configure(
    PurchasesConfiguration("test_aVutuZrKfnrBKOnfDeUkBFBLlAU"),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? city;
  String? country;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// 2️⃣ Combined async initialization
  Future<void> _initApp() async {
    // a) Get location
    try {
      final locationData = await LocationService.getUserCityAndCountry();
      city = locationData.city;
      country = locationData.country;
    } catch (_) {
      city = "Unknown city";
      country = "Unknown country";
    }

    // b) Show RevenueCat Paywall on load
    await RevenueCatUI.presentPaywall(); // automatically opens your configured paywall

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(
        city: city ?? "Unknown city",
        country: country ?? "Unknown country",
      ),
    );
  }
}
