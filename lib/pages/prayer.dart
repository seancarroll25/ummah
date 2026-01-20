import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/PrayerTime.dart';
import '../widgets/prayer_time_row.dart';

//i have no idea what ts does anymore
class PrayerPage extends StatefulWidget {
  final String city;
  final String country;
  final Coordinates? coordinates; // Optional: pass from MainPage

  const PrayerPage({
    super.key,
    required this.city,
    required this.country,
    this.coordinates,
  });

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  List<PrayerTime> prayerTimes = [];
  bool isLoading = true;
  String? errorMessage;
  tz.Location? userTimezone;
  Coordinates? userCoordinates;

  @override
  void initState() {
    super.initState();
    _initializeAndCalculate();
  }

  Future<void> _initializeAndCalculate() async {
    // If coordinates weren't passed, we need to get them
    if (widget.coordinates != null) {
      userCoordinates = widget.coordinates;
    } else {
      // You might want to get coordinates here using Geolocator
      // For now, we'll show an error
      setState(() {
        isLoading = false;
        errorMessage =
            'Location coordinates not available. Please restart the app.';
      });
      return;
    }

    await _detectTimezone();
    await calculateMonthlyPrayerTimes();
  }

  Future<void> _detectTimezone() async {
    try {
      String timezoneName = 'UTC';

      if (widget.city.toLowerCase().contains('san francisco') ||
          widget.city.toLowerCase().contains('los angeles') ||
          widget.city.toLowerCase().contains('seattle') ||
          widget.city.toLowerCase().contains('portland')) {
        timezoneName = 'America/Los_Angeles';
      } else if (widget.city.toLowerCase().contains('new york') ||
          widget.city.toLowerCase().contains('boston') ||
          widget.city.toLowerCase().contains('miami')) {
        timezoneName = 'America/New_York';
      } else if (widget.city.toLowerCase().contains('chicago') ||
          widget.city.toLowerCase().contains('dallas')) {
        timezoneName = 'America/Chicago';
      } else if (widget.city.toLowerCase().contains('denver') ||
          widget.city.toLowerCase().contains('phoenix')) {
        timezoneName = 'America/Denver';
      } else if (widget.city.toLowerCase().contains('london')) {
        timezoneName = 'Europe/London';
      } else if (widget.city.toLowerCase().contains('paris')) {
        timezoneName = 'Europe/Paris';
      } else if (widget.city.toLowerCase().contains('dubai')) {
        timezoneName = 'Asia/Dubai';
      } else if (widget.city.toLowerCase().contains('riyadh') ||
          widget.city.toLowerCase().contains('mecca') ||
          widget.city.toLowerCase().contains('medina')) {
        timezoneName = 'Asia/Riyadh';
      } else if (widget.city.toLowerCase().contains('cairo')) {
        timezoneName = 'Africa/Cairo';
      } else if (widget.city.toLowerCase().contains('istanbul')) {
        timezoneName = 'Europe/Istanbul';
      } else if (widget.city.toLowerCase().contains('karachi')) {
        timezoneName = 'Asia/Karachi';
      } else if (widget.country.toLowerCase().contains('united states')) {
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
    } catch (e) {
      userTimezone = tz.UTC;
    }
  }

  Future<void> calculateMonthlyPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (userCoordinates == null || userTimezone == null) {
        throw Exception('Coordinates or timezone not initialized');
      }

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final List<PrayerTime> monthlyTimes = [];

      CalculationParameters params;

      if (widget.country.toLowerCase().contains('united states') ||
          widget.country.toLowerCase().contains('canada')) {
        // ISNA (North America) method - uses 15° for both Fajr and Isha
        params = CalculationMethodParameters.northAmerica();
      } else if (widget.country.toLowerCase().contains('egypt')) {
        params = CalculationMethodParameters.egyptian();
      } else if (widget.country.toLowerCase().contains('saudi') ||
          widget.city.toLowerCase().contains('mecca') ||
          widget.city.toLowerCase().contains('makkah')) {
        params = CalculationMethodParameters.ummAlQura();
      } else if (widget.country.toLowerCase().contains('dubai') ||
          widget.country.toLowerCase().contains('uae') ||
          widget.country.toLowerCase().contains('emirates')) {
        params = CalculationMethodParameters.dubai();
      } else if (widget.country.toLowerCase().contains('turkey')) {
        params = CalculationMethodParameters.turkiye();
      } else if (widget.country.toLowerCase().contains('singapore') ||
          widget.country.toLowerCase().contains('malaysia') ||
          widget.country.toLowerCase().contains('indonesia')) {
        params = CalculationMethodParameters.singapore();
      } else if (widget.country.toLowerCase().contains('pakistan')) {
        params = CalculationMethodParameters.karachi();
      } else if (widget.country.toLowerCase().contains('qatar')) {
        params = CalculationMethodParameters.qatar();
      } else if (widget.country.toLowerCase().contains('kuwait')) {
        params = CalculationMethodParameters.kuwait();
      } else if (widget.country.toLowerCase().contains('iran')) {
        params = CalculationMethodParameters.tehran();
      } else {
        params = CalculationMethodParameters.muslimWorldLeague();
      }
      params.madhab = Madhab.shafi;

      final timeFormat = DateFormat('HH:mm');
      final dateFormat = DateFormat('dd MMM yyyy');

      // Calculate prayer times for each day of the month
      for (int day = 1; day <= daysInMonth; day++) {
        try {
          final date = DateTime(now.year, now.month, day);
          final tzDate = tz.TZDateTime.from(date, userTimezone!);

          // Calculate prayer times using timezone-aware date
          PrayerTimes dailyPrayerTimes = PrayerTimes(
            coordinates: userCoordinates!,
            date: tzDate,
            calculationParameters: params,
            precision: true,
          );

          // Convert prayer times to timezone-aware DateTime
          DateTime fajrTime = tz.TZDateTime.from(
            dailyPrayerTimes.fajr,
            userTimezone!,
          );
          DateTime dhuhrTime = tz.TZDateTime.from(
            dailyPrayerTimes.dhuhr,
            userTimezone!,
          );
          DateTime asrTime = tz.TZDateTime.from(
            dailyPrayerTimes.asr,
            userTimezone!,
          );
          DateTime maghribTime = tz.TZDateTime.from(
            dailyPrayerTimes.maghrib,
            userTimezone!,
          );
          DateTime ishaTime = tz.TZDateTime.from(
            dailyPrayerTimes.isha,
            userTimezone!,
          );

          monthlyTimes.add(
            PrayerTime(
              date: dateFormat.format(date),
              fajr: timeFormat.format(fajrTime),
              duhr: timeFormat.format(dhuhrTime),
              asr: timeFormat.format(asrTime),
              maghrib: timeFormat.format(maghribTime),
              isha: timeFormat.format(ishaTime),
            ),
          );
        } catch (e) {
          monthlyTimes.add(
            PrayerTime(
              date: dateFormat.format(DateTime(now.year, now.month, day)),
              fajr: '--:--',
              duhr: '--:--',
              asr: '--:--',
              maghrib: '--:--',
              isha: '--:--',
            ),
          );
        }
      }

      // Move today's date to top
      final today = dateFormat.format(now);
      final currentIndex = monthlyTimes.indexWhere((p) => p.date == today);
      if (currentIndex != -1) {
        final todayPrayer = monthlyTimes.removeAt(currentIndex);
        monthlyTimes.insert(0, todayPrayer);
      }

      setState(() {
        prayerTimes = monthlyTimes;
        isLoading = false;
      });
    } catch (e, st) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error calculating prayer times. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Prayer - ${widget.city}",
                        style: const TextStyle(
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.home),
                  ),
                ],
              ),
            ),

            // Location info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text(
                "${widget.city}, ${widget.country}",
                style: const TextStyle(
                  fontFamily: 'Comfortaa',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),

            const Divider(height: 1),

            // Content area
            Expanded(
              child: isLoading
                  ? (() {
                      return const Center(child: CircularProgressIndicator());
                    })()
                  : errorMessage != null
                  ? (() {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Comfortaa',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  _initializeAndCalculate();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    })()
                  : (() {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: prayerTimes.length,
                        itemBuilder: (context, index) {
                          final prayer = prayerTimes[index];
                          final isToday =
                              index ==
                              0; // First item is today after reordering

                          return Card(
                            margin: const EdgeInsets.only(bottom: 20),
                            elevation: isToday ? 4 : 2,
                            color: isToday
                                ? const Color(0xFF13A694).withOpacity(0.1)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isToday
                                  ? const BorderSide(
                                      color: Color(0xFF13A694),
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Date: ${prayer.date}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Comfortaa',
                                          color: isToday
                                              ? const Color(0xFF13A694)
                                              : null,
                                        ),
                                      ),
                                      if (isToday) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF13A694),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'TODAY',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Comfortaa',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  PrayerTimeRow('Fajr', prayer.fajr),
                                  PrayerTimeRow('Duhr', prayer.duhr),
                                  PrayerTimeRow('Asr', prayer.asr),
                                  PrayerTimeRow('Maghrib', prayer.maghrib),
                                  PrayerTimeRow('Isha', prayer.isha),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    })(),
            ),
          ],
        ),
      ),
    );
  }
}
