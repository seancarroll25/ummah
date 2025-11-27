import 'package:flutter/material.dart';

class VerseItem extends StatelessWidget {
  final int verseId;
  final String verseText;
  final String translation;

  const VerseItem({
    Key? key,
    required this.verseId,
    required this.verseText,
    required this.translation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use theme colors for background and text
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor; // background for the card
    final verseCircleColor = const Color(0xFF13A694); // app green color

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse ID circle
          Container(
            margin: const EdgeInsets.only(left: 15, top: 5),
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: verseCircleColor, // ✅ use green
            ),
            alignment: Alignment.center,
            child: Text(
              '$verseId',
              style: const TextStyle(
                color: Colors.white, // ID text stays white
                fontSize: 12,
                fontFamily: 'Comfortaa',
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Arabic verse text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              verseText,
              textAlign: TextAlign.end,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 25,
                fontFamily: 'ArabicFont', // keep your Arabic font
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Divider line
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            height: 1,
            color: Theme.of(context).dividerColor, // use theme divider color
          ),

          const SizedBox(height: 10),

          // Translation text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Text(
              translation,
              style: TextStyle(
                fontSize: 15,
                color: textColor, // themed text color
                fontFamily: 'Comfortaa',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
