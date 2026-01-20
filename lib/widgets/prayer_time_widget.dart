import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:home_widget/home_widget.dart';
import './prayer_column.dart';

String iconForPrayer(String name) {
  switch (name) {
    case 'Fajr':
      return 'assets/icons/fajr.svg';
    case 'Dhuhr':
      return 'assets/icons/dhuhr.svg';
    case 'Asr':
      return 'assets/icons/asr.svg';
    case 'Maghrib':
      return 'assets/icons/maghrib.svg';
    case 'Isha':
      return 'assets/icons/isha.svg';
    default:
      return 'assets/icons/default.svg';
  }
}


class PrayerWidgetView extends StatelessWidget {
  const PrayerWidgetView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: HomeWidget.getWidgetData<String>('today_prayers'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('—'));
        }

        final data = jsonDecode(snapshot.data!);
        final List prayers = data['prayers'];

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: prayers.map<Widget>((p) {
              return PrayerColumn(
                name: p['name'],
                time: p['time'],
                iconPath: iconForPrayer(p['name']),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
