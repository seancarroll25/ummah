import 'package:flutter/material.dart';

class SurahItem extends StatelessWidget {
  final int id;
  final String name;
  final String transliteration;
  final String type;
  final String totalVerses;
  final VoidCallback onTap;

  const SurahItem({
    Key? key,
    required this.id,
    required this.name,
    required this.transliteration,
    required this.type,
    required this.totalVerses,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final circleColor = const Color(0xFF13A694); // app green

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        height: 90,
        child: Row(
          children: [
            // Circle with Surah ID
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor, // ✅ app green
              ),
              alignment: Alignment.center,
              child: Text(
                '$id',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Comfortaa',
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Surah details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transliteration,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$type, ',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                      Text(
                        '$totalVerses Ayah',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arabic name aligned to the end
            Text(
              name,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                color: textColor,
                fontFamily: 'ArabicFont', // your Arabic font
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }
}
