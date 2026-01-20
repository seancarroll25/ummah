import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/PrayerTimesWidgetModel.dart';

class PrayerService {
  static const _cacheKey = 'prayer_times_cache';
  static const _cacheDateKey = 'prayer_times_date';
  static const _cacheTimezoneKey = 'prayer_times_timezone';

  static const Madhab _defaultMadhab = Madhab.shafi;
  static const CalculationMethod _defaultMethod = CalculationMethod.muslimWorldLeague;

  Future<PrayerTimesModel> getPrayerTimes({
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final userTimezone = await _detectTimezone(latitude, longitude, city, country);
    final timezoneName = userTimezone.name;


    final cachedDate = prefs.getString(_cacheDateKey);
    final cachedTimezone = prefs.getString(_cacheTimezoneKey);

    if (cachedDate == today &&
        cachedTimezone == timezoneName &&
        prefs.containsKey(_cacheKey)) {
      final cached = jsonDecode(prefs.getString(_cacheKey)!);
      return PrayerTimesModel.fromApi(cached, now);
    }

    final coordinates = Coordinates(latitude, longitude);
    final params = _getCalculationParams(country);
    params.madhab = _defaultMadhab;

    final tzDate = tz.TZDateTime.from(now, userTimezone);

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: tzDate,
      calculationParameters: params,
      precision: true,
    );

    final fajrTime = tz.TZDateTime.from(prayerTimes.fajr, userTimezone);
    final sunriseTime = tz.TZDateTime.from(prayerTimes.sunrise, userTimezone);
    final dhuhrTime = tz.TZDateTime.from(prayerTimes.dhuhr, userTimezone);
    final asrTime = tz.TZDateTime.from(prayerTimes.asr, userTimezone);
    final maghribTime = tz.TZDateTime.from(prayerTimes.maghrib, userTimezone);
    final ishaTime = tz.TZDateTime.from(prayerTimes.isha, userTimezone);

    final timeFormat = DateFormat('HH:mm');

    final timings = {
      'Fajr': timeFormat.format(fajrTime),
      'Sunrise': timeFormat.format(sunriseTime),
      'Dhuhr': timeFormat.format(dhuhrTime),
      'Asr': timeFormat.format(asrTime),
      'Maghrib': timeFormat.format(maghribTime),
      'Isha': timeFormat.format(ishaTime),
    };

    await prefs.setString(_cacheKey, jsonEncode(timings));
    await prefs.setString(_cacheDateKey, today);
    await prefs.setString(_cacheTimezoneKey, timezoneName);

    return PrayerTimesModel.fromApi(timings, now);
  }

  Future<tz.Location> _detectTimezone(
      double latitude,
      double longitude,
      String? city,
      String? country,
      ) async {
    try {
      String timezoneName = 'UTC';

      if (city != null && country != null) {
        final cityLower = city.toLowerCase();
        final countryLower = country.toLowerCase();

        if (cityLower.contains('san francisco') ||
            cityLower.contains('los angeles') ||
            cityLower.contains('seattle') ||
            cityLower.contains('portland')) {
          timezoneName = 'America/Los_Angeles';
        } else if (cityLower.contains('new york') ||
            cityLower.contains('boston') ||
            cityLower.contains('miami')) {
          timezoneName = 'America/New_York';
        } else if (cityLower.contains('chicago') ||
            cityLower.contains('dallas')) {
          timezoneName = 'America/Chicago';
        } else if (cityLower.contains('denver') ||
            cityLower.contains('phoenix')) {
          timezoneName = 'America/Denver';
        } else if (cityLower.contains('london')) {
          timezoneName = 'Europe/London';
        } else if (cityLower.contains('paris')) {
          timezoneName = 'Europe/Paris';
        } else if (cityLower.contains('dubai')) {
          timezoneName = 'Asia/Dubai';
        } else if (cityLower.contains('riyadh') ||
            cityLower.contains('mecca') ||
            cityLower.contains('medina')) {
          timezoneName = 'Asia/Riyadh';
        } else if (cityLower.contains('cairo')) {
          timezoneName = 'Africa/Cairo';
        } else if (cityLower.contains('istanbul')) {
          timezoneName = 'Europe/Istanbul';
        } else if (cityLower.contains('karachi')) {
          timezoneName = 'Asia/Karachi';
        } else if (cityLower.contains('dublin')) {
          timezoneName = 'Europe/Dublin';
        } else if (countryLower.contains('united states')) {
          // Guess based on longitude for US cities
          if (longitude < -120) {
            timezoneName = 'America/Los_Angeles';
          } else if (longitude < -105) {
            timezoneName = 'America/Denver';
          } else if (longitude < -90) {
            timezoneName = 'America/Chicago';
          } else {
            timezoneName = 'America/New_York';
          }
        } else if (countryLower.contains('ireland')) {
          timezoneName = 'Europe/Dublin';
        } else if (countryLower.contains('united kingdom')) {
          timezoneName = 'Europe/London';
        }
      }

      return tz.getLocation(timezoneName);
    } catch (e) {
      return tz.UTC;
    }
  }

  CalculationParameters _getCalculationParams(String? country) {
    if (country == null) return CalculationMethodParameters.muslimWorldLeague();

    final countryLower = country.toLowerCase();

    if (countryLower.contains('united states') || countryLower.contains('canada')) {
      return CalculationMethodParameters.northAmerica();
    } else if (countryLower.contains('egypt')) {
      return CalculationMethodParameters.egyptian();
    } else if (countryLower.contains('saudi')) {
      return CalculationMethodParameters.ummAlQura();
    } else if (countryLower.contains('dubai') ||
        countryLower.contains('uae') ||
        countryLower.contains('emirates')) {
      return CalculationMethodParameters.dubai();
    } else if (countryLower.contains('turkey')) {
      return CalculationMethodParameters.turkiye();
    } else if (countryLower.contains('singapore') ||
        countryLower.contains('malaysia') ||
        countryLower.contains('indonesia')) {
      return CalculationMethodParameters.singapore();
    } else if (countryLower.contains('pakistan')) {
      return CalculationMethodParameters.karachi();
    } else if (countryLower.contains('qatar')) {
      return CalculationMethodParameters.qatar();
    } else if (countryLower.contains('kuwait')) {
      return CalculationMethodParameters.kuwait();
    } else if (countryLower.contains('iran')) {
      return CalculationMethodParameters.tehran();
    }

    return CalculationMethodParameters.muslimWorldLeague();
  }

  CalculationParameters _paramsFromMethod(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslimWorldLeague:
        return CalculationMethodParameters.muslimWorldLeague();
      case CalculationMethod.northAmerica:
        return CalculationMethodParameters.northAmerica();
      case CalculationMethod.egyptian:
        return CalculationMethodParameters.egyptian();
      case CalculationMethod.ummAlQura:
        return CalculationMethodParameters.ummAlQura();
      case CalculationMethod.karachi:
        return CalculationMethodParameters.karachi();
      case CalculationMethod.dubai:
        return CalculationMethodParameters.dubai();
      case CalculationMethod.qatar:
        return CalculationMethodParameters.qatar();
      case CalculationMethod.kuwait:
        return CalculationMethodParameters.kuwait();
      case CalculationMethod.tehran:
        return CalculationMethodParameters.tehran();
      case CalculationMethod.turkiye:
        return CalculationMethodParameters.turkiye();
      case CalculationMethod.singapore:
        return CalculationMethodParameters.singapore();
      default:
        return CalculationMethodParameters.muslimWorldLeague();
    }
  }
}