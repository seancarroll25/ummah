import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeDisplay extends StatefulWidget {
  const TimeDisplay({super.key});

  @override
  State<TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<TimeDisplay> {
  late String _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = _formatCurrentTime();
    _startTimer();
  }

  void _startTimer() {

    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;


    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      setState(() {
        _currentTime = _formatCurrentTime();
      });

      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        setState(() {
          _currentTime = _formatCurrentTime();
        });
      });
    });
  }

  String _formatCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentTime,
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        fontFamily: "Comfortaa",
        letterSpacing: 0.03,
        color: Colors.black,
      ),
    );
  }
}
