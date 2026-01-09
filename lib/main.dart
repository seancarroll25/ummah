import 'package:everythingapp/pages/MainPage.dart';
import 'package:everythingapp/services/LocationService.dart';
import 'package:everythingapp/services/PrayerService.dart';
import 'package:everythingapp/services/subscription_service.dart';
import 'package:everythingapp/services/widget_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'background/widget_callback.dart';

void main() async {
  debugPrint("main(): starting app...");

  // We commented these out previously
   WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
   await HomeWidget.setAppGroupId(WidgetService.appGroupId);
   HomeWidget.registerBackgroundCallback(backgroundCallback);

  await SubscriptionService.init();
   runApp(MyApp());
  debugPrint("main(): runApp complete.");
}

Future<void> _loadPrayerTimesOnStartup({
  required double latitude,
  required double longitude,
  String? city,
  String? country,
}) async {
  debugPrint("_loadPrayerTimesOnStartup(): starting...");

  try {
    // Store location for background updates
    await HomeWidget.saveWidgetData('user_latitude', latitude);
    await HomeWidget.saveWidgetData('user_longitude', longitude);
    if (city != null) await HomeWidget.saveWidgetData('user_city', city);
    if (country != null) await HomeWidget.saveWidgetData('user_country', country);

    debugPrint("_loadPrayerTimesOnStartup(): saved location to widget data");

    final prayerService = PrayerService();
    final prayerTimes = await prayerService.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
    );
    debugPrint("_loadPrayerTimesOnStartup(): fetched prayer times successfully.");

    try {
      await WidgetService.updateWidget(prayerTimes);
      debugPrint("_loadPrayerTimesOnStartup(): widget updated successfully.");
    } catch (widgetError, widgetStack) {
      debugPrint("_loadPrayerTimesOnStartup(): failed to update widget: $widgetError\n$widgetStack");
    }
  } catch (e, st) {
    debugPrint("_loadPrayerTimesOnStartup(): failed to fetch prayer times: $e\n$st");
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
    debugPrint("_MyAppState.initState(): starting initialization...");
    _initApp();
  }

// _initApp() inside MyAppState
  Future<void> _initApp() async {
    debugPrint("_initApp(): fetching location...");
    try {
      final locationData = await LocationService.getUserCityAndCountry();
      city = locationData.city;
      country = locationData.country;
      debugPrint("_initApp(): location fetched: $city, $country");

      try {
        await _loadPrayerTimesOnStartup(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          city: city,
          country: country
        );
        debugPrint("_initApp(): prayer times loaded successfully.");
      } catch (prayerError, prayerStack) {
        debugPrint("_initApp(): error loading prayer times: $prayerError\n$prayerStack");
      }
    } catch (e, st) {
      debugPrint("_initApp(): error fetching location/prayer times: $e\n$st");
      city = "Unknown city 1";
      country = "Unknown country";
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
    debugPrint("_initApp(): initialization complete.");
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("_MyAppState.build(): building widget tree. isLoading = $isLoading");
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
