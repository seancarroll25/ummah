import 'package:intl/intl.dart';

class PrayerTimesModel {
  final Map<String, DateTime> times;

  PrayerTimesModel(this.times);

  static const orderedNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  factory PrayerTimesModel.fromApi(
      Map<String, dynamic> json,
      DateTime date,
      ) {
    DateTime parse(String value) {
      final t = value.split(' ')[0].split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(t[0]),
        int.parse(t[1]),
      );
    }

    return PrayerTimesModel({
      'Fajr': parse(json['Fajr']),
      'Dhuhr': parse(json['Dhuhr']),
      'Asr': parse(json['Asr']),
      'Maghrib': parse(json['Maghrib']),
      'Isha': parse(json['Isha']),
    });
  }
}