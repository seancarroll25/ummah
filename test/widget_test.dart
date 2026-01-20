import 'package:everythingapp/models/PrayerTimesWidgetModel.dart';
import 'package:everythingapp/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';

class TestPage extends StatefulWidget {
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _log = '';

  void _addLog(String msg) {
    setState(() {
      _log += '$msg\n';
    });
    print(msg);
  }

  Future<void> _testWidget() async {
    setState(() => _log = '');

    _addLog('🧪 TEST STARTED');

    try {
      // 1. Set app group
      _addLog('1️⃣ Setting app group...');
      await HomeWidget.setAppGroupId('group.com.getsilat.silat');
      _addLog('✅ App group set');

      // 2. Create test data
      _addLog('2️⃣ Creating test data...');
      final testTimes = PrayerTimesModel({
        'Fajr': DateTime(2025, 1, 1, 5, 30),
        'Dhuhr': DateTime(2025, 1, 1, 12, 15),
        'Asr': DateTime(2025, 1, 1, 15, 45),
        'Maghrib': DateTime(2025, 1, 1, 18, 20),
        'Isha': DateTime(2025, 1, 1, 19, 45),
      });
      _addLog('✅ Test data created');

      // 3. Call widget service
      _addLog('3️⃣ Updating widget...');
      final success = await WidgetService.updateWidget(testTimes);
      _addLog(success ? '✅ Widget service returned true' : '❌ Widget service returned false');

      // 4. VERIFY DATA WAS SAVED
      _addLog('4️⃣ Verifying data was saved...');
      final savedData = await HomeWidget.getWidgetData<String>('today_prayers');

      if (savedData == null) {
        _addLog('❌❌❌ DATA NOT SAVED! ❌❌❌');
        _addLog('');
        _addLog('This is the problem!');
        _addLog('Data is NOT being written to shared storage.');
      } else {
        _addLog('✅ Data WAS saved!');
        _addLog('');
        _addLog('Saved data:');
        _addLog(savedData);
        _addLog('');

        // Try to parse it
        try {
          final decoded = jsonDecode(savedData);
          _addLog('✅ Data is valid JSON');
          _addLog('Date: ${decoded['date']}');
          _addLog('Prayers: ${decoded['prayers'].length}');
        } catch (e) {
          _addLog('❌ Data is NOT valid JSON: $e');
        }
      }

      _addLog('');
      _addLog('✅ TEST COMPLETE');

    } catch (e, stack) {
      _addLog('');
      _addLog('❌ ERROR: $e');
      _addLog('Stack: $stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Widget Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _testWidget,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'RUN DEBUG TEST',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log.isEmpty ? 'Press button to test' : _log,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}