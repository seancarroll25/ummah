import 'package:everythingapp/pages/MainPage.dart';
import 'package:everythingapp/services/LocationService.dart';
import 'package:everythingapp/services/PrayerService.dart';
import 'package:everythingapp/services/background_prayer_notification_service.dart';
import 'package:everythingapp/services/notification_service.dart';
import 'package:everythingapp/services/subscription_service.dart';
import 'package:everythingapp/services/widget_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'background/widget_callback.dart';

void main() async {


  // We commented these out previously
   WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
   await HomeWidget.setAppGroupId(WidgetService.appGroupId);
   HomeWidget.registerBackgroundCallback(backgroundCallback);

  await SubscriptionService.init();

   await NotificationService().initialize();

   // Initialize background service
   await BackgroundService.initialize();

   runApp(MyApp());

}

Future<void> _loadPrayerTimesOnStartup({
  required double latitude,
  required double longitude,
  String? city,
  String? country,
}) async {


  try {
    // Store location for background updates
    await HomeWidget.saveWidgetData('user_latitude', latitude);
    await HomeWidget.saveWidgetData('user_longitude', longitude);
    if (city != null) await HomeWidget.saveWidgetData('user_city', city);
    if (country != null) await HomeWidget.saveWidgetData('user_country', country);



    final prayerService = PrayerService();
    final prayerTimes = await prayerService.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
    );


    try {
      await WidgetService.updateWidget(prayerTimes);
    } catch (_) {}
  } catch (_) {}
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

// _initApp() inside MyAppState
  Future<void> _initApp() async {

    try {
      final locationData = await LocationService.getUserCityAndCountry();
      city = locationData.city;
      country = locationData.country;


      try {
        await _loadPrayerTimesOnStartup(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          city: city,
          country: country
        );

      } catch (_) {

      }
    } catch (e, st) {
      city = "Unknown city";
      country = "Unknown country";
    }

    if (!mounted) return;

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
