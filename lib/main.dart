import 'package:everythingapp/pages/MainPage.dart';
import 'package:everythingapp/services/LocationService.dart';
import 'package:everythingapp/services/PrayerService.dart';
import 'package:everythingapp/services/widget_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'background/widget_callback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  await _loadPrayerTimesOnStartup();
  runApp(const MyApp());
}

Future<void> _loadPrayerTimesOnStartup() async {
  try {

    final prayerService = PrayerService();

    // TODO: Get these from user preferences or location
    final prayerTimes = await prayerService.getPrayerTimes(
      lat: 53.3498,  // Dublin - replace with actual user location
      lng: -6.2603,
      method: 2,     // Replace with user's preferred method
    );

    await WidgetService.updateWidget(prayerTimes);
  } catch (_) {
  }
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
