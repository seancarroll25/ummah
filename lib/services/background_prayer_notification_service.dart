import 'package:everythingapp/services/prayer_notification_manager.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzLocation;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan_dart/adhan_dart.dart';

// Background task name
const String prayerTimeUpdateTask = 'prayerTimeUpdateTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {

    try {

      tz.initializeTimeZones();

      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('prayer_latitude');
      final longitude = prefs.getDouble('prayer_longitude');
      final timezoneName = prefs.getString('prayer_timezone');

      if (latitude == null || longitude == null || timezoneName == null) {
        return Future.value(false);
      }


      final coordinates = Coordinates(latitude, longitude);
      final timezone = tzLocation.getLocation(timezoneName);

      final manager = PrayerTimeManager();
      await manager.scheduleWeekOfPrayers(
        coordinates: coordinates,
        timezone: timezone,
      );

      return Future.value(true);
    } catch (e, st) {
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> initialize() async {

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

  }

  static Future<void> scheduleDailyPrayerTimeUpdate() async {


    await Workmanager().registerPeriodicTask(
      prayerTimeUpdateTask,
      prayerTimeUpdateTask,
      frequency: const Duration(hours: 24),
      initialDelay: _calculateTimeUntilMidnight(),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );


  }

  static Duration _calculateTimeUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);

    return duration;
  }

  static Future<void> cancelDailyTask() async {
    await Workmanager().cancelByUniqueName(prayerTimeUpdateTask);
  }

  static Future<void> saveLocationData({
    required double latitude,
    required double longitude,
    required String timezoneName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_latitude', latitude);
    await prefs.setDouble('prayer_longitude', longitude);
    await prefs.setString('prayer_timezone', timezoneName);

  }
}