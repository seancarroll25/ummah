// lib/pages/MainPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

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
  String userCity = "Loading...";
  String userCountry = "";
  String hijriDate = "Loading...";
  String gregorianDate = "Loading...";
  String nextPrayer = "Loading...";
  bool isLoading = true;

  Map<String, String> todayPrayerTimes = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location disabled";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Permission denied";
      }

      if (permission == LocationPermission.deniedForever) {
        throw "Permission denied forever";
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        userCity = place.locality ??
            place.subAdministrativeArea ??
            "Unknown city";
        userCountry = place.country ?? "Unknown country";
      });

      await _fetchTodayPrayerTimes(userCity, userCountry);
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() {
        userCity = "Unknown city";
        userCountry = "Unknown country";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTodayPrayerTimes(String city, String country) async {
    try {
      final url =
          'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=2';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch prayer times');
      }

      final data = json.decode(response.body);
      final timings = data['data']['timings'];

      final hijriData = data['data']['date']['hijri'];
      final gregData = data['data']['date']['gregorian'];

      setState(() {
        todayPrayerTimes = {
          'Fajr': timings['Fajr'],
          'Dhuhr': timings['Dhuhr'],
          'Asr': timings['Asr'],
          'Maghrib': timings['Maghrib'],
          'Isha': timings['Isha'],
          'Sunrise': timings['Sunrise'],
        };

        todayPrayerTimes.addAll(_calculateExtraPrayers(todayPrayerTimes));

        hijriDate =
        "${hijriData['day']} ${hijriData['month']['en']} ${hijriData['year']}";
        gregorianDate =
        "${gregData['day']} ${gregData['month']['en']} ${gregData['year']}";

        nextPrayer = _calculateNextPrayer();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching prayer times: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, String> _calculateExtraPrayers(
      Map<String, String> times) {
    Map<String, String> extra = {};
    try {
      final now = DateTime.now();

      DateTime fajr = _parseTime(times['Fajr']!, now);
      DateTime maghrib = _parseTime(times['Maghrib']!, now);
      DateTime sunrise = _parseTime(times['Sunrise']!, now);

      Duration night = fajr.difference(maghrib);
      extra['Middle of the Night'] =
          _formatTime(maghrib.add(night ~/ 2));
      extra['Tahajjud'] =
          _formatTime(fajr.subtract(night ~/ 3));
      extra['Duha'] =
          _formatTime(sunrise.add(const Duration(minutes: 20)));
    } catch (e) {
      debugPrint("Extra prayers error: $e");
    }
    return extra;
  }

  DateTime _parseTime(String time, DateTime now) {
    final parts = time.split(":");
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _formatTime(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  String _calculateNextPrayer() {
    final now = DateTime.now();
    String? next;
    Duration min = const Duration(days: 1);

    todayPrayerTimes.forEach((name, t) {
      try {
        final dt = _parseTime(t, now);
        if (dt.isAfter(now)) {
          final diff = dt.difference(now);
          if (diff < min) {
            min = diff;
            next = name;
          }
        }
      } catch (_) {}
    });

    return next ?? "No more prayers today";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
              left: 25, top: 30, right: 25, bottom: 100),
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
                  Expanded(
                      child: Container(
                          height: 1, color: Colors.grey.shade300)),
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

              Column(
                children: [
                  _prayerRow("Fajr", todayPrayerTimes['Fajr'] ?? '--',
                      "assets/images/drawable/fajr.svg"),
                  _prayerRow("Dhuhr",
                      todayPrayerTimes['Dhuhr'] ?? '--',
                      "assets/images/drawable/duhur.svg"),
                  _prayerRow("Asr", todayPrayerTimes['Asr'] ?? '--',
                      "assets/images/drawable/asr.svg"),
                  _prayerRow("Maghrib",
                      todayPrayerTimes['Maghrib'] ?? '--',
                      "assets/images/drawable/maghrib.svg"),
                  _prayerRow("Isha", todayPrayerTimes['Isha'] ?? '--',
                      "assets/images/drawable/isha.svg"),
                  const SizedBox(height: 15),
                  _prayerRow(
                      "Middle of the Night",
                      todayPrayerTimes['Middle of the Night'] ?? '--',
                      "assets/images/drawable/isha.svg"),
                  _prayerRow(
                      "Tahajjud",
                      todayPrayerTimes['Tahajjud'] ?? '--',
                      "assets/images/drawable/fajr.svg"),
                  _prayerRow(
                      "Duha",
                      todayPrayerTimes['Duha'] ?? '--',
                      "assets/images/drawable/duhur.svg"),
                ],
              ),

              const SizedBox(height: 40),

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
                children: [
                  _featureIcon(
                    title: "Prayer",
                    svgAsset:
                    'assets/images/drawable/prayer_times.svg',
                    onTap: () => _navigateTo(
                        PrayerPage(city: userCity, country: userCountry)),
                  ),
                  const SizedBox(width: 30),
                  _featureIcon(
                    title: "Quran",
                    svgAsset: 'assets/images/drawable/quran.svg',
                    onTap: () => _navigateTo(const QuranPage()),
                  ),
                  const SizedBox(width: 30),
                  _featureIcon(
                    title: "Names",
                    svgAsset: 'assets/images/drawable/names.svg',
                    onTap: () => _navigateTo(const NamesPage()),
                  ),
                  const SizedBox(width: 30),
                  _featureIcon(
                    title: "Tasbih",
                    svgAsset: 'assets/images/drawable/tasbih.svg',
                    onTap: () => _navigateTo(const TasbihPage()),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  _featureIcon(
                    title: "Qibla",
                    svgAsset: 'assets/images/drawable/qibla.svg',
                    onTap: () => _navigateTo(const QiblaPage()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prayerRow(String name, String time, String fileName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(fileName, width: 24, height: 24)),
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
                  colorFilter: const ColorFilter.mode(
                      Color(0xFFFFFFFF), BlendMode.srcIn),
                )
                    : const Icon(Icons.image_not_supported,
                    size: 35, color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, fontFamily: "Comfortaa"),
          ),
        ],
      ),
    );
  }
}
