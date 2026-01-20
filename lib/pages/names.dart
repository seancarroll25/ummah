import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NamesPage extends StatefulWidget {
  const NamesPage({super.key});

  @override
  State<NamesPage> createState() => _NamesPageState();
}

class _NamesPageState extends State<NamesPage> {
  List<Map<String, dynamic>> names = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchNames();
  }

  Future<void> fetchNames() async {
    const String apiUrl =
        'https://api.aladhan.com/v1/asmaAlHusna/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        setState(() {
          names = data
              .map((item) => {
            "name": item['name'],
            "transliteration": item['transliteration'],
            "number": item['number'].toString(),
          })
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 26),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "99 Names of Allah",
                    style: TextStyle(
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Loading or error states
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isError)
              const Expanded(
                child: Center(
                  child: Text(
                    "Error loading data.\nPlease try again.",
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
            // Names list
              Expanded(
                child: ListView.builder(
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    final item = names[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isDark ? Colors.grey[900] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF13A694), // mountain green
                          child: Text(
                            item["number"],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          item["name"],
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            color:
                            isDark ? Colors.white : Colors.blue.shade900,
                          ),
                        ),
                        subtitle: Text(
                          item["transliteration"],
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
