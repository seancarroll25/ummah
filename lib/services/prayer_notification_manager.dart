import 'package:flutter/material.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'notification_service.dart';

class PrayerTimeManager {
  static final PrayerTimeManager _instance = PrayerTimeManager._internal();
  factory PrayerTimeManager() => _instance;
  PrayerTimeManager._internal();

  final NotificationService _notificationService = NotificationService();

  // Calculate and schedule prayer times
  Future<void> calculateAndSchedulePrayerTimes({
    required Coordinates coordinates,
    required tz.Location timezone,
  }) async {

    try {
      final now = DateTime.now();
      final tzDate = tz.TZDateTime.from(now, timezone);

      CalculationParameters params = CalculationMethodParameters.northAmerica()
        ..madhab = Madhab.shafi;

      PrayerTimes prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: tzDate,
        calculationParameters: params,
        precision: true,
      );

      final fajrTime = tz.TZDateTime.from(prayerTimes.fajr, timezone);
      final dhuhrTime = tz.TZDateTime.from(prayerTimes.dhuhr, timezone);
      final asrTime = tz.TZDateTime.from(prayerTimes.asr, timezone);
      final maghribTime = tz.TZDateTime.from(prayerTimes.maghrib, timezone);
      final ishaTime = tz.TZDateTime.from(prayerTimes.isha, timezone);



      final prayerTimesMap = {
        'Fajr': fajrTime,
        'Dhuhr': dhuhrTime,
        'Asr': asrTime,
        'Maghrib': maghribTime,
        'Isha': ishaTime,
      };

      await _notificationService.scheduleAllPrayerNotifications(
        prayerTimes: prayerTimesMap,
        timezone: timezone,
      );

    } catch (_) {}
  }
  Future<void> scheduleWeekOfPrayers({
    required Coordinates coordinates,
    required tz.Location timezone,
  }) async {

    try {
      CalculationParameters params = CalculationMethodParameters.northAmerica()
        ..madhab = Madhab.shafi;

      await _notificationService.scheduleWeekOfPrayerNotifications(
        coordinates: coordinates,
        timezone: timezone,
        params: params,
      );

    } catch (_) {}
  }
  Future<void> logPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    for (var notification in pending) {}
  }
}