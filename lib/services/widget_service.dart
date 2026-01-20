import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/PrayerTimesWidgetModel.dart';


class WidgetService {
  static const String appGroupId = 'group.com.getsilat.silat';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<bool> updateWidget(PrayerTimesModel times) async {
    try {

      await HomeWidget.setAppGroupId(appGroupId);

      final prayers = PrayerTimesModel.orderedNames.map((name) {
        return {
          'name': name,
          'time': DateFormat('HH:mm').format(times.times[name]!),
        };
      }).toList();

      final payload = {
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'prayers': prayers,
      };

      final jsonPayload = jsonEncode(payload);

      final saveResult = await HomeWidget.saveWidgetData(
        'today_prayers',
        jsonPayload,
      );

      if (saveResult == null || !saveResult) {

        return false;
      }


      final updateResult = await HomeWidget.updateWidget(
        iOSName: 'PrayerTimesWidget',
      );

      if (updateResult == null || !updateResult) {

        return false;
      }

      print('✅ Widget updated successfully');
      return true;

    } catch (e, stack) {

      return false;
    }
  }
}