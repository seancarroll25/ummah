import 'package:everythingapp/pages/QiblaPage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../pages/prayer.dart';
import '../pages/quran.dart';
import '../pages/names.dart';
import '../pages/tasbih.dart';
import '../widgets/time_display.dart';
import '../pages/QiblaPage.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        userCity = "Location disabled";
        userCountry = "";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          userCity = "Permission denied";
          userCountry = "";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        userCity = "Permission denied forever";
        userCountry = "";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        userCity =
            place.locality ?? place.subAdministrativeArea ?? "Unknown city";
        userCountry = place.country ?? "Unknown country";
      });
    } catch (e) {
      setState(() {
        userCity = "Unknown city";
        userCountry = "Unknown country";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, top: 30, right: 25, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Section
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
                          color: Colors.black, // or Theme color
                        ),
                      ),
                    ],
                  ),


                  // Time Section

                  TimeDisplay(),


                  const SizedBox(height: 5),
                  Text(
                    "Next prayer: Loading...",
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.03,
                      fontFamily: "Comfortaa",
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Date and Hijri
                  Row(
                    children: [
                      Text(
                        "Date: Loading...",
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: "Comfortaa",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(height: 1, color: Colors.grey.shade300),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Hijri: Loading...",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Comfortaa",
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Prayer Times
                  Column(
                    children: [
                      _prayerRow("Fajr", "05:00", "assets/images/drawable/fajr.svg"),
                      _prayerRow("Duhur", "12:30", "assets/images/drawable/duhur.svg"),
                      _prayerRow("Asr", "15:45", "assets/images/drawable/asr.svg"),
                      _prayerRow("Maghrib", "18:20", "assets/images/drawable/maghrib.svg"),
                      _prayerRow("Isha", "19:45", "assets/images/drawable/isha.svg"),
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
                      _featureIcon(
                        title: "Prayer",
                        svgAsset: 'assets/images/drawable/prayer_times.svg',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrayerPage(city: userCity, country: userCountry),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      _featureIcon(
                        title: "Quran",
                        svgAsset: 'assets/images/drawable/quran.svg',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QuranPage()),
                        ),
                      ),
                      const SizedBox(width: 30),
                      _featureIcon(
                        title: "Names",
                        svgAsset: 'assets/images/drawable/names.svg',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NamesPage()),
                        ),
                      ),

                      const SizedBox(width: 30),
                      _featureIcon(
                        title: "Tasbih",
                        svgAsset: 'assets/images/drawable/tasbih.svg',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TasbihPage()),
                        ),
                      ),
                    ],


                  ),
                  Row(

                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 100),
                      _featureIcon(
                        title: "Qibla",
                        svgAsset: 'assets/images/drawable/qibla.svg',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QiblaPage()),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(String name, String time, String file_name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child:
            SvgPicture.asset(
              file_name,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: "Comfortaa",
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: "Comfortaa",
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureIcon({
    required String title,
    String? svgAsset, // SVG path
    IconData? iconData, // fallback icon
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
              color: const Color(0xFF13A694), // mountain green tint
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
                    Color(0xFFFFFFFF),
                    BlendMode.srcIn,
                  ),
                )
                    : Icon(
                  iconData ?? Icons.image_not_supported,
                  size: 35,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: "Comfortaa",
            ),
          ),
        ],
      ),
    );
  }
}
