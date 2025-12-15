import 'package:everythingapp/pages/MainPage.dart';
import 'package:everythingapp/services/LocationService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String city = "Loading...";
  String country = "Loading...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Request location permission and get city/country
      final locationData = await LocationService.getUserCityAndCountry();
      city = locationData.city ?? "Unknown city";
      country = locationData.country ?? "Unknown country";
    } catch (e) {
      city = "Unknown city";
      country = "Unknown country";
      print("Error getting location: $e");
    }

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
      home: MainPage(city: city, country: country),
    );
  }
}
