import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/details_screen.dart';
import '../widgets/surah_item.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({Key? key}) : super(key: key);

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final List<dynamic> _surahList = [];
  List<dynamic> _filteredSurahList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedLanguage = 'English';
  late String _url;

  static const Map<String, String> _urls = {
    "English": "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_en.json",
    "Turkish": "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_tr.json",
    "Indonesian": "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_id.json",
    "French": "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_fr.json",
    "Spanish": "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_es.json",
  };

  @override
  void initState() {
    super.initState();
    _loadLanguageAndData();
  }

  Future<void> _loadLanguageAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    _url = _urls[_selectedLanguage] ??
        "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_en.json";
    _fetchSurahData();
  }

  Future<void> _fetchSurahData() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _surahList.clear();
          _surahList.addAll(data);
          _filteredSurahList = List.from(_surahList);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  void _filterSurahs(String query) {
    setState(() {
      _searchQuery = query;
      _filteredSurahList = _surahList
          .where((surah) => surah['transliteration']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _openDetails(dynamic surah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(surah: surah),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Al-Quran", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SurahSearchDelegate(
                  surahs: _surahList,
                  onSelected: _openDetails,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSurahList.isEmpty
          ? const Center(child: Text('No Surahs Found'))
          : ListView.builder(
        itemCount: _filteredSurahList.length,
        itemBuilder: (context, index) {
          final surah = _filteredSurahList[index];
          return SurahItem(
            id: surah['id'],
            name: surah['name'],
            transliteration: surah['transliteration'],
            type: surah['type'],
            totalVerses: surah['total_verses'].toString(),
            onTap: () => _openDetails(surah),
          );

        },
      ),
    );
  }
}

class SurahSearchDelegate extends SearchDelegate {
  final List surahs;
  final Function(dynamic) onSelected;

  SurahSearchDelegate({required this.surahs, required this.onSelected});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = surahs
        .where((s) =>
        s['transliteration'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = surahs
        .where((s) =>
        s['transliteration'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildList(suggestions);
  }

  Widget _buildList(List surahList) {
    return ListView.builder(
      itemCount: surahList.length,
      itemBuilder: (context, index) {
        final surah = surahList[index];
        return ListTile(
          title: Text("${surah['id']}. ${surah['transliteration']}"),
          subtitle: Text("${surah['name']} — ${surah['type']}"),
          onTap: () => onSelected(surah),
        );
      },
    );
  }
}
