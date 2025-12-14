// lib/pages/MainPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../pages/prayer.dart';
import '../pages/quran.dart';
import '../pages/names.dart';
import '../pages/tasbih.dart';
import '../pages/QiblaPage.dart';
import '../widgets/time_display.dart';

class MainPage extends StatefulWidget {
  final String? city;
  final String? country;

  const MainPage({super.key, this.city, this.country});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Location / display fields
  String userCity = "Loading...";
  String userCountry = "";
  String hijriDate = "Loading...";
  String gregorianDate = "Loading...";
  String nextPrayer = "Loading...";
  bool isLoading = true;

  Map<String, String> todayPrayerTimes = {};

  // RevenueCat state
  static const String _entitlementId = "deen"; // Your entitlement
  bool _hasDeen = false;
  VoidCallback? _pendingFeatureCallback;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initRevenueCatListenerAndState();
  }

  @override
  void dispose() {
    // There's no removeCustomerInfoUpdateListener API in some versions; if you have one, remove the listener here.
    // Purchases.removeCustomerInfoUpdateListener(_customerInfoUpdated); // Uncomment if available in your SDK version.
    super.dispose();
  }

  // -------------------- RevenueCat setup --------------------
  void _initRevenueCatListenerAndState() async {
    // Add listener to react to entitlement updates
    Purchases.addCustomerInfoUpdateListener(_customerInfoUpdated);

    // Fetch initial state
    try {
      final info = await Purchases.getCustomerInfo();
      final isActive = info.entitlements.all[_entitlementId]?.isActive ?? false;
      setState(() {
        _hasDeen = isActive;
      });
    } catch (e) {
      // If fetching fails, we keep _hasDeen false
      debugPrint("Error fetching initial RevenueCat CustomerInfo: $e");
    }
  }

  void _customerInfoUpdated(CustomerInfo info) {
    final isActive = info.entitlements.all[_entitlementId]?.isActive ?? false;
    final previouslyActive = _hasDeen;
    if (isActive != previouslyActive) {
      setState(() => _hasDeen = isActive);
    }

    // If user just gained access and there is a pending feature, navigate
    if (!previouslyActive && isActive && _pendingFeatureCallback != null) {
      final cb = _pendingFeatureCallback!;
      // Clear before navigating to avoid double-calls
      _pendingFeatureCallback = null;

      // Delay a tick to ensure Flutter regained focus after native paywall
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          cb();
        } catch (e) {
          debugPrint("Error running pending feature callback: $e");
        }
      });
    }
  }

  // -------------------- Feature launcher --------------------
  /// Use this to open features.
  /// If [premium] is true, the method will show paywall if needed.
  Future<void> _openFeature({required Widget page, required bool premium}) async {
    // Free feature => open immediately
    if (!premium) {
      _navigateTo(page);
      return;
    }

    // Premium feature: if already has deen entitlement, open
    if (_hasDeen) {
      _navigateTo(page);
      return;
    }

    // Otherwise, set pending callback and show paywall
    _pendingFeatureCallback = () => _navigateTo(page);

    try {
      // Present RevenueCat paywall (this opens native paywall)
      await RevenueCatUI.presentPaywall();

      // After the paywall closes, try to fetch updated info immediately
      // (sometimes listener fires, sometimes we need to poll)
      final info = await Purchases.getCustomerInfo();
      final nowActive = info.entitlements.all[_entitlementId]?.isActive ?? false;

      if (nowActive) {
        // Clear pending and navigate immediately
        final cb = _pendingFeatureCallback;
        _pendingFeatureCallback = null;
        if (cb != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              cb();
            } catch (e) {
              debugPrint("Error navigating after immediate CustomerInfo fetch: $e");
            }
          });
        }
      } else {
        // If still not active, we rely on listener to open when entitlement updates
        // If user cancelled, pendingFeature remains and nothing will happen (safe)
        debugPrint("Paywall closed, purchase not yet active (or cancelled). Relying on listener for updates.");
      }
    } catch (e) {
      debugPrint("Error presenting paywall: $e");
      // Clear pending to avoid stale callback if desired:
      // _pendingFeatureCallback = null;
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // -------------------- Location & Prayer logic (kept from your original) --------------------
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location disabled";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Permission denied";
      }

      if (permission == LocationPermission.deniedForever) throw "Permission denied forever";

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      String city = place.locality ?? place.subAdministrativeArea ?? "Unknown city";
      String country = place.country ?? "Unknown country";

      setState(() {
        userCity = city;
        userCountry = country;
      });

      await _fetchTodayPrayerTimes(city, country);
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() {
        userCity = "Unknown city";
        userCountry = "Unknown country";
        todayPrayerTimes = {
          'Fajr': '--',
          'Dhuhr': '--',
          'Asr': '--',
          'Maghrib': '--',
          'Isha': '--',
        };
        hijriDate = "--";
        gregorianDate = "--";
        nextPrayer = "--";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTodayPrayerTimes(String city, String country) async {
    try {
      final url = 'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=2';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) throw Exception('Failed to fetch prayer times');

      final data = json.decode(response.body);
      final timings = data['data']['timings'];

      final hijriData = data['data']['date']['hijri'];
      final gregData = data['data']['date']['gregorian'];
      final hijriStr = "${hijriData['day']} ${hijriData['month']['en']} ${hijriData['year']}";
      final gregorianStr = "${gregData['day']} ${gregData['month']['en']} ${gregData['year']}";

      setState(() {
        todayPrayerTimes = {
          'Fajr': timings['Fajr'],
          'Dhuhr': timings['Dhuhr'],
          'Asr': timings['Asr'],
          'Maghrib': timings['Maghrib'],
          'Isha': timings['Isha'],
          'Sunrise': timings['Sunrise'],
        };

        final extraPrayers = _calculateExtraPrayers(todayPrayerTimes);
        todayPrayerTimes.addAll(extraPrayers);

        hijriDate = hijriStr;
        gregorianDate = gregorianStr;
        nextPrayer = _calculateNextPrayer();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching prayer times: $e");
      setState(() {
        todayPrayerTimes = {
          'Fajr': '--',
          'Dhuhr': '--',
          'Asr': '--',
          'Maghrib': '--',
          'Isha': '--',
        };
        hijriDate = "--";
        gregorianDate = "--";
        nextPrayer = "--";
        isLoading = false;
      });
    }
  }

  Map<String, String> _calculateExtraPrayers(Map<String, String> times) {
    Map<String, String> extraPrayers = {};

    try {
      final now = DateTime.now();

      DateTime fajr = _parseTime(times['Fajr']!, now);
      DateTime dhuhr = _parseTime(times['Dhuhr']!, now);
      DateTime maghrib = _parseTime(times['Maghrib']!, now);
      DateTime sunrise = _parseTime(times['Sunrise']!, now);

      Duration nightDuration = fajr.difference(maghrib);
      DateTime middleOfNight = maghrib.add(nightDuration ~/ 2);
      extraPrayers['Middle of the Night'] = _formatTime(middleOfNight);

      DateTime tahajjud = fajr.subtract(nightDuration ~/ 3);
      extraPrayers['Tahajjud'] = _formatTime(tahajjud);

      DateTime duha = sunrise.add(const Duration(minutes: 20));
      extraPrayers['Duha'] = _formatTime(duha);
    } catch (e) {
      debugPrint("Error calculating extra prayers: $e");
    }

    return extraPrayers;
  }

  DateTime _parseTime(String timeStr, DateTime now) {
    final parts = timeStr.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _calculateNextPrayer() {
    final now = DateTime.now();
    String? upcomingPrayer;
    Duration minDiff = const Duration(days: 1);

    todayPrayerTimes.forEach((name, timeStr) {
      try {
        final parts = timeStr.split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

        if (prayerTime.isAfter(now)) {
          final diff = prayerTime.difference(now);
          if (diff < minDiff) {
            minDiff = diff;
            upcomingPrayer = name;
          }
        }
      } catch (e) {
        debugPrint("Error parsing prayer time $name: $e");
      }
    });

    return upcomingPrayer ?? "No more prayers today";
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 25, top: 30, right: 25, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location
              Row(
                children: [
                  const SizedBox(height: 60),
                  SvgPicture.asset(
                    "assets/images/drawable/location.svg",
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "$userCity, $userCountry",
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: "Comfortaa",
                      letterSpacing: 0.03,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Time
              TimeDisplay(),
              const SizedBox(height: 5),
              Text(
                "Next prayer: $nextPrayer",
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.03,
                  fontFamily: "Comfortaa",
                ),
              ),
              const SizedBox(height: 40),

              // Date/Hijri
              Row(
                children: [
                  Text(
                    "Date: $gregorianDate",
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: "Comfortaa",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "Hijri: $hijriDate",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Comfortaa",
                ),
              ),
              const SizedBox(height: 20),

              // Prayer times list
              Column(
                children: [
                  _prayerRow("Fajr", todayPrayerTimes['Fajr'] ?? '--', "assets/images/drawable/fajr.svg"),
                  _prayerRow("Dhuhr", todayPrayerTimes['Dhuhr'] ?? '--', "assets/images/drawable/duhur.svg"),
                  _prayerRow("Asr", todayPrayerTimes['Asr'] ?? '--', "assets/images/drawable/asr.svg"),
                  _prayerRow("Maghrib", todayPrayerTimes['Maghrib'] ?? '--', "assets/images/drawable/maghrib.svg"),
                  _prayerRow("Isha", todayPrayerTimes['Isha'] ?? '--', "assets/images/drawable/isha.svg"),
                  const SizedBox(height: 15),
                  _prayerRow("Middle of the Night", todayPrayerTimes['Middle of the Night'] ?? '--', "assets/images/drawable/isha.svg"),
                  _prayerRow("Tahajjud", todayPrayerTimes['Tahajjud'] ?? '--', "assets/images/drawable/fajr.svg"),
                  _prayerRow("Duha", todayPrayerTimes['Duha'] ?? '--', "assets/images/drawable/duhur.svg"),
                ],
              ),
              const SizedBox(height: 40),

              // Features Section
              const Text(
                "All Features",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Comfortaa",
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Prayer (FREE)
                  _featureIcon(
                    title: "Prayer",
                    svgAsset: 'assets/images/drawable/prayer_times.svg',
                    onTap: () => _openFeature(page: PrayerPage(city: userCity, country: userCountry), premium: false),
                  ),
                  const SizedBox(width: 30),

                  // Quran (FREE)
                  _featureIcon(
                    title: "Quran",
                    svgAsset: 'assets/images/drawable/quran.svg',
                    onTap: () => _openFeature(page: const QuranPage(), premium: false),
                  ),

                  const SizedBox(width: 30),

                  // Names (PREMIUM)
                  _featureIcon(
                    title: "Names",
                    svgAsset: 'assets/images/drawable/names.svg',
                    onTap: () => _openFeature(page: const NamesPage(), premium: false),
                  ),

                  const SizedBox(width: 30),

                  // Tasbih (PREMIUM)
                  _featureIcon(
                    title: "Tasbih",
                    svgAsset: 'assets/images/drawable/tasbih.svg',
                    onTap: () => _openFeature(page: const TasbihPage(), premium: false),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  // Qibla (PREMIUM)
                  _featureIcon(
                    title: "Qibla",
                    svgAsset: 'assets/images/drawable/qibla.svg',
                    onTap: () => _openFeature(page: const QiblaPage(), premium: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- helpers --------------------
  Widget _prayerRow(String name, String time, String fileName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 24, height: 24, child: SvgPicture.asset(fileName, width: 24, height: 24)),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontSize: 10, fontFamily: "Comfortaa")),
          const Spacer(),
          Text(time, style: const TextStyle(fontSize: 10, fontFamily: "Comfortaa")),
        ],
      ),
    );
  }

  Widget _featureIcon({
    required String title,
    String? svgAsset,
    IconData? iconData,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF13A694),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SizedBox(
                width: 35,
                height: 35,
                child: svgAsset != null
                    ? SvgPicture.asset(
                  svgAsset,
                  width: 35,
                  height: 35,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn),
                )
                    : Icon(iconData ?? Icons.image_not_supported, size: 35, color: const Color(0xFFFFFFFF)),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: "Comfortaa"),
          ),
        ],
      ),
    );
  }
}
