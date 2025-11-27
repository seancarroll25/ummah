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
    // Calculate remaining seconds until the next minute
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;

    // First delay to align with the start of the next minute
    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      // Update immediately at the start of the minute
      setState(() {
        _currentTime = _formatCurrentTime();
      });

      // Then start periodic timer every minute
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        setState(() {
          _currentTime = _formatCurrentTime();
        });
      });
    });
  }

  String _formatCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
    // For 12-hour format with AM/PM: DateFormat('hh:mm a').format(DateTime.now());
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
