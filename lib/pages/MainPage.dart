// lib/pages/MainPage.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../pages/prayer.dart';
import '../pages/quran.dart';
import '../pages/names.dart';
import '../pages/tasbih.dart';
import '../pages/QiblaPage.dart';
import '../testpage.dart';
import '../widgets/premium_guard.dart';
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
  String fetchedUserCity = "Loading...";
  String fetchedUserCountry = "";
  String hijriDate = "Loading...";
  String gregorianDate = "Loading...";
  String nextPrayer = "Loading...";
  bool isLoading = true;

  Map<String, String> todayPrayerTimes = {};
  Coordinates? userCoordinates;
  tz.Location? userTimezone;

  @override
  void initState() {
    super.initState();
    debugPrint("MainPage.initState(): START");
    _initializeTimezone();
    _determinePosition();
    debugPrint("MainPage.initState(): END");
  }

  Future<void> _initializeTimezone() async {
    debugPrint("MainPage._initializeTimezone(): START");
    try {
      // Initialize timezone database
      // Note: You need to call tz.initializeTimeZones() in your main.dart
      // and load the timezone database before using this
      final String timeZoneName = DateTime.now().timeZoneName;
      debugPrint("MainPage._initializeTimezone(): System timezone: $timeZoneName");
    } catch (e) {
      debugPrint("MainPage._initializeTimezone(): Error: $e");
    }
    debugPrint("MainPage._initializeTimezone(): END");
  }

  void _navigateTo(Widget page) {
    debugPrint("MainPage._navigateTo(): Navigating to ${page.runtimeType}");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _shareApp() {
    debugPrint("MainPage._shareApp(): START");
    final box = context.findRenderObject() as RenderBox?;

    if (box == null) {
      debugPrint("MainPage._shareApp(): box is null, returning");
      return;
    }

    final String shareText = '''
📿 Strengthen your Deen with this app!

🕌 Prayer Times based on your location
📖 Quran
📿 Tasbih
🧭 Qibla Direction

May Allah reward you for sharing 🤍

📲 Download:
https://apps.apple.com/app/silat-quran-qibla-tasbih/id6756083062
''';

    Share.share(
      shareText,
      subject: 'Share Islamic App',
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
    debugPrint("MainPage._shareApp(): END");
  }

  Future<void> _determinePosition() async {
    debugPrint("MainPage._determinePosition(): START");
    try {
      debugPrint("Checking if location services are enabled...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location disabled";

      debugPrint("Checking permissions...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Permission denied";
      }

      if (permission == LocationPermission.deniedForever) {
        throw "Permission denied forever";
      }

      debugPrint("Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      debugPrint("Position: ${position.latitude}, ${position.longitude}");

      // Store coordinates for prayer time calculation
      userCoordinates = Coordinates(position.latitude, position.longitude);

      debugPrint("Reverse geocoding...");
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isEmpty) throw "No placemarks returned";

      Placemark place = placemarks[0];
      debugPrint("Placemark: ${place.locality}, ${place.country}");

      setState(() {
        fetchedUserCity = place.locality!;
        fetchedUserCountry = place.country!;
      });

      if (!mounted) {
        debugPrint("MainPage._determinePosition(): Not mounted, returning");
        return;
      }

      debugPrint("MainPage._determinePosition(): Setting state with location");
      setState(() {
        userCity = place.locality ??
            place.subAdministrativeArea ??
            "Unknown city 3";
        userCountry = place.country ?? "Unknown country";
      });

      debugPrint("Saving data to HomeWidget...");
      await HomeWidget.saveWidgetData('user_city', userCity);
      await HomeWidget.saveWidgetData('user_country', userCountry);

      // Detect and set user's timezone
      await _detectTimezone();

      debugPrint("Calculating today's prayer times...");
      await _calculateTodayPrayerTimes();

      debugPrint("Updating widget...");
      await HomeWidget.updateWidget(iOSName: 'PrayerTimesWidget');

      debugPrint("MainPage._determinePosition(): END (success)");
    } catch (e, st) {
      debugPrint("Location error: $e\n$st");
      if (!mounted) {
        debugPrint(
            "MainPage._determinePosition(): Not mounted after error, returning");
        return;
      }
      setState(() {
        userCity = "Unknown city 2";
        userCountry = "Unknown country";
        isLoading = false;
      });
      debugPrint("MainPage._determinePosition(): END (error)");
    }
  }

  Future<void> _detectTimezone() async {
    debugPrint("MainPage._detectTimezone(): START");
    try {
      // Use the city and country to determine timezone
      String timezoneName = 'UTC';

      debugPrint("MainPage._detectTimezone(): Detecting timezone for $userCity, $userCountry");

      // Map major cities to timezones
      if (userCity.toLowerCase().contains('san francisco') ||
          userCity.toLowerCase().contains('los angeles') ||
          userCity.toLowerCase().contains('seattle') ||
          userCity.toLowerCase().contains('portland')) {
        timezoneName = 'America/Los_Angeles';
      } else if (userCity.toLowerCase().contains('new york') ||
          userCity.toLowerCase().contains('boston') ||
          userCity.toLowerCase().contains('miami')) {
        timezoneName = 'America/New_York';
      } else if (userCity.toLowerCase().contains('chicago') ||
          userCity.toLowerCase().contains('dallas')) {
        timezoneName = 'America/Chicago';
      } else if (userCity.toLowerCase().contains('denver') ||
          userCity.toLowerCase().contains('phoenix')) {
        timezoneName = 'America/Denver';
      } else if (userCity.toLowerCase().contains('london')) {
        timezoneName = 'Europe/London';
      } else if (userCity.toLowerCase().contains('paris')) {
        timezoneName = 'Europe/Paris';
      } else if (userCity.toLowerCase().contains('dubai')) {
        timezoneName = 'Asia/Dubai';
      } else if (userCity.toLowerCase().contains('riyadh') ||
          userCity.toLowerCase().contains('mecca') ||
          userCity.toLowerCase().contains('medina')) {
        timezoneName = 'Asia/Riyadh';
      } else if (userCity.toLowerCase().contains('cairo')) {
        timezoneName = 'Africa/Cairo';
      } else if (userCity.toLowerCase().contains('istanbul')) {
        timezoneName = 'Europe/Istanbul';
      } else if (userCity.toLowerCase().contains('karachi')) {
        timezoneName = 'Asia/Karachi';
      } else if (userCountry.toLowerCase().contains('united states')) {
        // For US cities not in the list, try to guess based on coordinates
        if (userCoordinates != null) {
          final longitude = userCoordinates!.longitude;
          if (longitude < -120) {
            timezoneName = 'America/Los_Angeles'; // Pacific
          } else if (longitude < -105) {
            timezoneName = 'America/Denver'; // Mountain
          } else if (longitude < -90) {
            timezoneName = 'America/Chicago'; // Central
          } else {
            timezoneName = 'America/New_York'; // Eastern
          }
        }
      }

      userTimezone = tz.getLocation(timezoneName);
      debugPrint("MainPage._detectTimezone(): Using timezone: ${userTimezone!.name}");
    } catch (e) {
      debugPrint("MainPage._detectTimezone(): Error: $e");
      userTimezone = tz.UTC;
    }
    debugPrint("MainPage._detectTimezone(): END");
  }

  Future<void> _calculateTodayPrayerTimes() async {
    debugPrint("MainPage._calculateTodayPrayerTimes(): START");
    try {
      if (userCoordinates == null) {
        throw Exception('User coordinates not available');
      }

      if (userTimezone == null) {
        await _detectTimezone();
      }

      // Create timezone-aware date - MUST get timezone first, then create date from it
      tz.TZDateTime date = tz.TZDateTime.from(DateTime.now(), userTimezone!);

      debugPrint("MainPage._calculateTodayPrayerTimes(): Calculating for coordinates: ${userCoordinates!.latitude}, ${userCoordinates!.longitude}");
      debugPrint("MainPage._calculateTodayPrayerTimes(): Timezone: ${userTimezone!.name}");
      debugPrint("MainPage._calculateTodayPrayerTimes(): TZDateTime: $date");

      // Set up calculation parameters based on location
      CalculationParameters params;

      // Choose calculation method based on country/region
      if (userCountry.toLowerCase().contains('united states') ||
          userCountry.toLowerCase().contains('canada')) {
        // ISNA (North America) method - uses 15° for both Fajr and Isha
        params = CalculationMethodParameters.northAmerica();
        debugPrint("MainPage: Using North America (ISNA) method for $userCountry");
      } else if (userCountry.toLowerCase().contains('egypt')) {
        params = CalculationMethodParameters.egyptian();
      } else if (userCountry.toLowerCase().contains('saudi') ||
          userCity.toLowerCase().contains('mecca') ||
          userCity.toLowerCase().contains('makkah')) {
        params = CalculationMethodParameters.ummAlQura();
      } else if (userCountry.toLowerCase().contains('dubai') ||
          userCountry.toLowerCase().contains('uae') ||
          userCountry.toLowerCase().contains('emirates')) {
        params = CalculationMethodParameters.dubai();
      } else if (userCountry.toLowerCase().contains('turkey')) {
        params = CalculationMethodParameters.turkiye();
      } else if (userCountry.toLowerCase().contains('singapore') ||
          userCountry.toLowerCase().contains('malaysia') ||
          userCountry.toLowerCase().contains('indonesia')) {
        params = CalculationMethodParameters.singapore();
      } else if (userCountry.toLowerCase().contains('pakistan')) {
        params = CalculationMethodParameters.karachi();
      } else if (userCountry.toLowerCase().contains('qatar')) {
        params = CalculationMethodParameters.qatar();
      } else if (userCountry.toLowerCase().contains('kuwait')) {
        params = CalculationMethodParameters.kuwait();
      } else if (userCountry.toLowerCase().contains('iran')) {
        params = CalculationMethodParameters.tehran();
      } else {
        // Default to Muslim World League for other locations
        params = CalculationMethodParameters.muslimWorldLeague();
      }

      // Set madhab
      params.madhab = Madhab.shafi; // Change to Madhab.hanafi if needed

      // Calculate prayer times - pass TZDateTime
      PrayerTimes prayerTimes = PrayerTimes(
        coordinates: userCoordinates!,
        date: date,
        calculationParameters: params,
        precision: true,
      );

      // Convert prayer times from UTC to the timezone
      DateTime fajrTime = tz.TZDateTime.from(prayerTimes.fajr, userTimezone!);
      DateTime sunriseTime = tz.TZDateTime.from(prayerTimes.sunrise, userTimezone!);
      DateTime dhuhrTime = tz.TZDateTime.from(prayerTimes.dhuhr, userTimezone!);
      DateTime asrTime = tz.TZDateTime.from(prayerTimes.asr, userTimezone!);
      DateTime maghribTime = tz.TZDateTime.from(prayerTimes.maghrib, userTimezone!);
      DateTime ishaTime = tz.TZDateTime.from(prayerTimes.isha, userTimezone!);

      debugPrint("MainPage: Fajr UTC: ${prayerTimes.fajr}");
      debugPrint("MainPage: Fajr Local: $fajrTime");

      // Format times
      final timeFormat = DateFormat('HH:mm');

      debugPrint("MainPage._calculateTodayPrayerTimes(): Setting state with prayer times");
      setState(() {
        todayPrayerTimes = {
          'Fajr': timeFormat.format(fajrTime),
          'Sunrise': timeFormat.format(sunriseTime),
          'Dhuhr': timeFormat.format(dhuhrTime),
          'Asr': timeFormat.format(asrTime),
          'Maghrib': timeFormat.format(maghribTime),
          'Isha': timeFormat.format(ishaTime),
        };

        // Calculate extra prayers
        todayPrayerTimes.addAll(_calculateExtraPrayers(
          fajrTime,
          sunriseTime,
          maghribTime,
        ));

        // Set dates
        hijriDate = _getHijriDate(DateTime.now());
        gregorianDate = DateFormat('d MMMM yyyy').format(DateTime.now());

        nextPrayer = _calculateNextPrayer();
        isLoading = false;
      });

      debugPrint("MainPage._calculateTodayPrayerTimes(): END (success)");
    } catch (e, st) {
      debugPrint("Error calculating prayer times: $e\n$st");
      setState(() {
        isLoading = false;
      });
      debugPrint("MainPage._calculateTodayPrayerTimes(): END (error)");
    }
  }

  String _getHijriDate(DateTime date) {
    debugPrint("MainPage._getHijriDate(): START");
    try {
      // Simple Hijri date calculation
      // For more accurate conversion, consider using a dedicated Hijri calendar package
      final hijri = _convertToHijri(date);
      debugPrint("MainPage._getHijriDate(): END");
      return hijri;
    } catch (e) {
      debugPrint("MainPage._getHijriDate(): Error: $e");
      return "Hijri date unavailable";
    }
  }

  String _convertToHijri(DateTime gregorianDate) {
    // This is a basic conversion. For production, use a proper Hijri calendar library
    // like 'hijri' package
    final jd = _gregorianToJulian(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
    );
    final hijri = _julianToHijri(jd);

    final hijriMonths = [
      'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaban',
      'Ramadan', 'Shawwal', 'Dhul-Qadah', 'Dhul-Hijjah'
    ];

    return "${hijri['day']} ${hijriMonths[hijri['month']! - 1]} ${hijri['year']}";
  }

  int _gregorianToJulian(int year, int month, int day) {
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + (12 * a) - 3;
    return day + ((153 * m + 2) ~/ 5) + (365 * y) + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
  }

  Map<String, int> _julianToHijri(int jd) {
    int l = jd - 1948440 + 10632;
    int n = ((l - 1) ~/ 10631);
    l = l - 10631 * n + 354;
    int j = ((10985 - l) ~/ 5316) * (50 * l / 17719).toInt() + (l ~/ 5670) * (43 * l / 15238).toInt();
    l = l - ((30 - j) ~/ 15) * (17719 * j / 50).toInt() - (j ~/ 16) * (15238 * j / 43).toInt() + 29;
    int month = ((24 * l) ~/ 709);
    int day = l - ((709 * month) ~/ 24);
    int year = 30 * n + j - 30;

    return {'year': year, 'month': month, 'day': day};
  }

  Map<String, String> _calculateExtraPrayers(
      DateTime fajr,
      DateTime sunrise,
      DateTime maghrib,
      ) {
    debugPrint("MainPage._calculateExtraPrayers(): START");
    Map<String, String> extra = {};
    try {
      final timeFormat = DateFormat('HH:mm');

      // Calculate Middle of the Night (between Maghrib and Fajr)
      DateTime nextFajr = fajr;
      if (fajr.isBefore(maghrib)) {
        nextFajr = fajr.add(const Duration(days: 1));
      }
      Duration night = nextFajr.difference(maghrib);
      DateTime middleOfNight = maghrib.add(night ~/ 2);
      extra['Middle of the Night'] = timeFormat.format(middleOfNight);

      // Calculate Tahajjud (last third of the night)
      DateTime tahajjud = nextFajr.subtract(night ~/ 3);
      extra['Tahajjud'] = timeFormat.format(tahajjud);

      // Calculate Duha (20 minutes after sunrise)
      DateTime duha = sunrise.add(const Duration(minutes: 20));
      extra['Duha'] = timeFormat.format(duha);
    } catch (e) {
      debugPrint("Extra prayers error: $e");
    }
    debugPrint("MainPage._calculateExtraPrayers(): END");
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
    debugPrint("MainPage._calculateNextPrayer(): START");
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

    debugPrint("MainPage._calculateNextPrayer(): END - next is $next");
    return next ?? "No more prayers today";
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("MainPage.build(): START - isLoading = $isLoading");
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: isLoading
          ? (() {
        debugPrint("MainPage.build(): Showing loading spinner");
        return const Center(child: CircularProgressIndicator());
      })()
          : Builder(
        builder: (context) {
          debugPrint("MainPage.build(): Building main content");
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 25, top: 30, right: 25, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (() {
                    debugPrint("MainPage.build(): Building _shareWidget");
                    return _shareWidget();
                  })(),
                  const SizedBox(height: 12),
                  (() {
                    debugPrint("MainPage.build(): Building location row");
                    return Row(
                      children: [
                        const SizedBox(height: 60),
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
                    );
                  })(),
                  const SizedBox(height: 12),
                  (() {
                    debugPrint("MainPage.build(): Building TimeDisplay");
                    return TimeDisplay();
                  })(),
                  const SizedBox(height: 5),
                  (() {
                    debugPrint(
                        "MainPage.build(): Building next prayer text");
                    return Text(
                      "Next prayer: $nextPrayer",
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.03,
                        fontFamily: "Comfortaa",
                      ),
                    );
                  })(),
                  const SizedBox(height: 40),
                  (() {
                    debugPrint("MainPage.build(): Building date row");
                    return Row(
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
                    );
                  })(),
                  const SizedBox(height: 5),
                  (() {
                    debugPrint("MainPage.build(): Building hijri date");
                    return Text(
                      "Hijri: $hijriDate",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Comfortaa",
                      ),
                    );
                  })(),
                  const SizedBox(height: 20),
                  (() {
                    debugPrint(
                        "MainPage.build(): Building prayer times column");
                    return Column(
                      children: [
                        _prayerRow("Fajr", todayPrayerTimes['Fajr'] ?? '--',
                            "assets/images/drawable/fajr.svg"),
                        _prayerRow("Dhuhr", todayPrayerTimes['Dhuhr'] ?? '--',
                            "assets/images/drawable/duhur.svg"),
                        _prayerRow("Asr", todayPrayerTimes['Asr'] ?? '--',
                            "assets/images/drawable/asr.svg"),
                        _prayerRow("Maghrib",
                            todayPrayerTimes['Maghrib'] ?? '--',
                            "assets/images/drawable/maghrib.svg"),
                        _prayerRow("Isha", todayPrayerTimes['Isha'] ?? '--',
                            "assets/images/drawable/isha.svg"),
                        const SizedBox(height: 15),
                      ],
                    );
                  })(),
                  const SizedBox(height: 40),
                  (() {
                    debugPrint(
                        "MainPage.build(): Building 'All Features' text");
                    return const Text(
                      "All Features",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Comfortaa",
                      ),
                    );
                  })(),
                  const SizedBox(height: 10),
                  (() {
                    debugPrint(
                        "MainPage.build(): Building feature icons row");
                    return Row(
                      children: [
                        _featureIcon(
                          title: "Prayer",
                          svgAsset:
                          'assets/images/drawable/prayer_times.svg',
                          onTap: () => _navigateTo(

                            PrayerPage(
                              city: userCity,
                              country: userCountry,
                              coordinates: userCoordinates,

                            )
                          ),
                        ),
                        const SizedBox(width: 30),
                        _featureIcon(
                          title: "Quran",
                          svgAsset: 'assets/images/drawable/quran.svg',
                          onTap: () => _navigateTo(
                            PremiumGuard(child:
                              const QuranPage(),


                    )
                          ),
                        ),
                        const SizedBox(width: 30),
                        _featureIcon(
                          title: "Names",
                          svgAsset: 'assets/images/drawable/names.svg',
                          onTap: () => _navigateTo(
                              PremiumGuard(child: const NamesPage(),

                              )
                          ),
                        ),
                        const SizedBox(width: 30),
                        _featureIcon(
                          title: "Tasbih",
                          svgAsset: 'assets/images/drawable/tasbih.svg',
                          onTap: () => _navigateTo(PremiumGuard(
                              child: const TasbihPage(),


                          )),
                        ),
                      ],
                    );
                  })(),
                  const SizedBox(height: 18),
                  (() {
                    debugPrint(
                        "MainPage.build(): Building qibla icon row");
                    return Row(
                      children: [
                        _featureIcon(
                          title: "Qibla",
                          svgAsset: 'assets/images/drawable/qibla.svg',
                          onTap: () => _navigateTo(PremiumGuard(
                              child: const QiblaPage(),

                          )),
                        ),
                      ],
                    );
                  })(),
                  (() {
                    debugPrint("MainPage.build(): Column complete");
                    return const SizedBox.shrink();
                  })(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _prayerRow(String name, String time, String fileName) {
    debugPrint(
        "MainPage._prayerRow(): Building row for $name with $fileName");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(fileName, width: 24, height: 24)),
          const SizedBox(width: 10),
          Text(name,
              style:
              const TextStyle(fontSize: 10, fontFamily: "Comfortaa")),
          const Spacer(),
          Text(time,
              style:
              const TextStyle(fontSize: 10, fontFamily: "Comfortaa")),
        ],
      ),
    );
  }

  Widget _shareWidget() {
    debugPrint("MainPage._shareWidget(): Building widget");
    return GestureDetector(
      onTap: _shareApp,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(0xFF13A694).withOpacity(0.2),
              Color(0xFF13A694).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF13A694).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF13A694),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF13A694).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Share the app with the Ummah to help others strengthen their deen.",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Comfortaa",
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF13A694),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureIcon({
    required String title,
    String? svgAsset,
    required VoidCallback onTap,
  }) {
    debugPrint(
        "MainPage._featureIcon(): Building icon for $title with ${svgAsset ?? 'no SVG'}");
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: "Comfortaa"),
          ),
        ],
      ),
    );
  }
}