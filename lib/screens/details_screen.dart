import 'package:flutter/material.dart';
import '../widgets/verse_item.dart';
class DetailsScreen extends StatelessWidget {
  final dynamic surah;

  const DetailsScreen({Key? key, required this.surah}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verses = surah['verses'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(surah['transliteration']),
      ),
      body: ListView.builder(
        itemCount: verses.length,
        itemBuilder: (context, index) {
          final verse = verses[index];
          return VerseItem(
            verseId: verse['id'],
            verseText: verse['text'],
            translation: verse['translation'],
          );
        },
      ),
    );
  }
}
