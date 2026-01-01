import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class PrayerColumn extends StatelessWidget {
  final String name;
  final String time;
  final String iconPath;

  const PrayerColumn({
    super.key,
    required this.name,
    required this.time,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        SvgPicture.asset(
          iconPath,
          width: 22,
          height: 22,
        ),

        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
