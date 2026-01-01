import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/PrayerService.dart';
import '../services/widget_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  try {

    // Initialize the widget service
    await WidgetService.initialize();

    // Get user preferences
    final prefs = await SharedPreferences.getInstance();
    final method = prefs.getInt('prayer_method') ?? 2;
    final city =
        await HomeWidget.getWidgetData<String>('user_city') ?? 'Unknown';
    final country =
        await HomeWidget.getWidgetData<String>('user_country') ?? 'Unknown';

    // Fetch prayer times
    final service = PrayerService();
    final times = await service.getPrayerTimesByCity(
      city: city,
      country: country,
      method: method,
    );

    // Update the widget
    await WidgetService.updateWidget(times);

  } catch (_) {

  }
}