import 'package:shared_preferences/shared_preferences.dart';

class ScanLimitService {
  static const _lastScanKey = 'last_scan_date';

  Future<bool> canScanToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScan = prefs.getString(_lastScanKey);
    final today = _today();
    return lastScan != today;
  }

  Future<void> registerScan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScanKey, _today());
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
