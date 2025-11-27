import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/PrayerTime.dart';
import '../widgets/prayer_time_row.dart'; // import the custom widget

class PrayerPage extends StatefulWidget {
  final String city;
  final String country;

  const PrayerPage({super.key, required this.city, required this.country});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  List<PrayerTime> prayerTimes = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPrayerTimes();
  }

  Future<void> fetchPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url =
        'https://api.aladhan.com/v1/calendarByCity?city=${widget.city}&country=${widget.country}&method=2';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> prayerData = data['data'];

        // Convert to model list
        final times = prayerData.map((item) {
          final date = item['date']['readable'];
          final t = item['timings'];
          return PrayerTime(
            date: date,
            fajr: t['Fajr'],
            duhr: t['Dhuhr'],
            asr: t['Asr'],
            maghrib: t['Maghrib'],
            isha: t['Isha'],
          );
        }).toList();

        // Move today's date to top
        final today = DateFormat('dd MMM yyyy').format(DateTime.now());
        final currentIndex = times.indexWhere((p) => p.date == today);
        if (currentIndex != -1) {
          final todayPrayer = times.removeAt(currentIndex);
          times.insert(0, todayPrayer);
        }

        setState(() {
          prayerTimes = times;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load prayer times');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching data. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    "Prayer - ${widget.city}",
                    style: const TextStyle(
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.home),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: prayerTimes.length,
                itemBuilder: (context, index) {
                  final prayer = prayerTimes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${prayer.date}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
