import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/PrayerService.dart';
import '../services/widget_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {


  try {
    await WidgetService.initialize();

    // Retrieve last known coordinates
    final latitude = await HomeWidget.getWidgetData<double>('user_latitude') ?? 0.0;
    final longitude = await HomeWidget.getWidgetData<double>('user_longitude') ?? 0.0;

    if (latitude == 0.0 && longitude == 0.0) {
      return;
    }


    final service = PrayerService();
    final times = await service.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );

    final success = await WidgetService.updateWidget(times);


  } catch (_) {
  }
}