import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/PrayerTimesWidgetModel.dart';

class PrayerService {
  static const _cacheKey = 'prayer_times_cache';
  static const _cacheDateKey = 'prayer_times_date';
  Future<PrayerTimesModel> getPrayerTimesByCity({
    required String city,
    required String country,
    int method = 2,
  }) async {
    final url =
        'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$method';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch prayer times');
    }

    final data = jsonDecode(res.body)['data']['timings'];
    return PrayerTimesModel.fromApi(data, DateTime.now());
  }
  Future<PrayerTimesModel> getPrayerTimes({ // Changed return type
    required double lat,
    required double lng,
    required int method,
  }) async {
    try {
      print('🔍 Fetching prayer times...');

      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check cache
      if (prefs.getString(_cacheDateKey) == today &&
          prefs.containsKey(_cacheKey)) {
        print('✅ Using cached prayer times');
        final cached = jsonDecode(prefs.getString(_cacheKey)!);
        return PrayerTimesModel.fromApi(cached, DateTime.now());
      }

      // Fetch from API
      print('🌐 Fetching from API...');
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$timestamp'
            '?latitude=$lat&longitude=$lng&method=$method',
      );

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('Failed to fetch prayer times: ${res.statusCode}');
      }

      final data = jsonDecode(res.body)['data']['timings'];
      print('✅ API response received');

      // Cache the results
      await prefs.setString(_cacheKey, jsonEncode(data));
      await prefs.setString(_cacheDateKey, today);

      return PrayerTimesModel.fromApi(data, DateTime.now());
    } catch (e, stack) {
      print('❌ Error in getPrayerTimes: $e');
      print('Stack: $stack');
      rethrow;
    }
  }
}