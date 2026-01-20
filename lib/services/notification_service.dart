import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification IDs for each prayer
  static const int fajrId = 1;
  static const int dhuhrId = 2;
  static const int asrId = 3;
  static const int maghribId = 4;
  static const int ishaId = 5;

  Future<void> initialize() async {
    if (_isInitialized) return;


    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {}

  Future<bool> requestPermissions() async {

    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
      _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final bool? result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        return result ?? false;
      }

      return false;

    } else if (Platform.isAndroid) {
      return true;
    }

    return false;
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required tz.Location timezone,
  }) async {
    try {

      final notificationTime = prayerTime.subtract(Duration(minutes: 10));
      final scheduledTime = tz.TZDateTime.from(notificationTime, timezone);

      if (scheduledTime.isBefore(tz.TZDateTime.now(timezone))) {
        return;
      }

      const notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
        android: AndroidNotificationDetails(
          'prayer_times',
          'Prayer Times',
          channelDescription: 'Notifications for daily prayer times',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );

      await _notifications.zonedSchedule(
        id,
        '🕌 $prayerName Prayer Time',
        'It\'s time for $prayerName prayer',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: prayerName,
      );

    } catch (_) {}
  }

  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required tz.Location timezone,
  }) async {

    await initialize();
    await cancelAllNotifications();

    if (prayerTimes.containsKey('Fajr')) {
      await schedulePrayerNotification(
        id: fajrId,
        prayerName: 'Fajr',
        prayerTime: prayerTimes['Fajr']!,
        timezone: timezone,
      );
    }

    if (prayerTimes.containsKey('Dhuhr')) {
      await schedulePrayerNotification(
        id: dhuhrId,
        prayerName: 'Dhuhr',
        prayerTime: prayerTimes['Dhuhr']!,
        timezone: timezone,
      );
    }

    if (prayerTimes.containsKey('Asr')) {
      await schedulePrayerNotification(
        id: asrId,
        prayerName: 'Asr',
        prayerTime: prayerTimes['Asr']!,
        timezone: timezone,
      );
    }

    if (prayerTimes.containsKey('Maghrib')) {
      await schedulePrayerNotification(
        id: maghribId,
        prayerName: 'Maghrib',
        prayerTime: prayerTimes['Maghrib']!,
        timezone: timezone,
      );
    }

    if (prayerTimes.containsKey('Isha')) {
      await schedulePrayerNotification(
        id: ishaId,
        prayerName: 'Isha',
        prayerTime: prayerTimes['Isha']!,
        timezone: timezone,
      );
    }


  }

  Future<void> scheduleWeekOfPrayerNotifications({
    required Coordinates coordinates,
    required tz.Location timezone,
    required CalculationParameters params,
  }) async {

    await initialize();
    await cancelAllNotifications();

    final now = DateTime.now();
    int notificationIdCounter = 1;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final tzDate = tz.TZDateTime.from(targetDate, timezone);


      try {
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

        await _scheduleSingleNotification(
          id: notificationIdCounter++,
          prayerName: 'Fajr',
          prayerTime: fajrTime,
          timezone: timezone,
        );

        await _scheduleSingleNotification(
          id: notificationIdCounter++,
          prayerName: 'Dhuhr',
          prayerTime: dhuhrTime,
          timezone: timezone,
        );

        await _scheduleSingleNotification(
          id: notificationIdCounter++,
          prayerName: 'Asr',
          prayerTime: asrTime,
          timezone: timezone,
        );

        await _scheduleSingleNotification(
          id: notificationIdCounter++,
          prayerName: 'Maghrib',
          prayerTime: maghribTime,
          timezone: timezone,
        );

        await _scheduleSingleNotification(
          id: notificationIdCounter++,
          prayerName: 'Isha',
          prayerTime: ishaTime,
          timezone: timezone,
        );

      } catch (_) {}
    }

 }

  // Helper method to schedule a single notification
  Future<void> _scheduleSingleNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required tz.Location timezone,
  }) async {
    try {
      final notificationTime = prayerTime.subtract(Duration(minutes: 10));
      final scheduledTime = tz.TZDateTime.from(notificationTime, timezone);

      if (scheduledTime.isBefore(tz.TZDateTime.now(timezone))) {
        return;
      }

      const notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
        android: AndroidNotificationDetails(
          'prayer_times',
          'Prayer Times',
          channelDescription: 'Notifications for daily prayer times',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );

      await _notifications.zonedSchedule(
        id,
        '🕌 $prayerName Prayer in 10 minutes',
        'Time to prepare for $prayerName prayer',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: prayerName,
      );

    } catch (_) {}
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}