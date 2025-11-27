import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? _heading;
  double? _qiblaDirection;
  Position? _position;
  StreamSubscription<CompassEvent>? _compassSub;

  @override
  void initState() {
    super.initState();
    _initLocationAndCompass();
  }

  Future<void> _initLocationAndCompass() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied.")),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() => _position = position);

    _calculateQiblaDirection(position.latitude, position.longitude);

    _compassSub = FlutterCompass.events!.listen((CompassEvent event) {
      setState(() => _heading = event.heading ?? 0);
    });
  }

  void _calculateQiblaDirection(double lat, double lon) {
    const double kaabaLat = 21.4225;
    const double kaabaLon = 39.8262;

    double phiK = kaabaLat * pi / 180;
    double phi = lat * pi / 180;
    double lambdaK = kaabaLon * pi / 180;
    double lambda = lon * pi / 180;

    double qibla = atan2(
      sin(lambdaK - lambda),
      cos(phi) * tan(phiK) - sin(phi) * cos(lambdaK - lambda),
    );

    qibla = qibla * 180 / pi;
    if (qibla < 0) qibla += 360;

    setState(() => _qiblaDirection = qibla);
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading ?? 0;
    final qiblaDir = _qiblaDirection ?? 0;

    // Rotation angle in radians for the Kaaba
    final double kaabaAngle = (qiblaDir - heading) * (pi / 180);

    // Compass size
    final double compassSize = 300;
    // Radius for Kaaba icon to rotate around (slightly smaller than half compass)
    final double radius = compassSize / 2 - 30;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _position == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 26),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "Qibla Finder",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comfortaa'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: compassSize,
                  height: compassSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass dial background
                      Image.asset(
                        'assets/images/drawable/dial.png',
                        width: compassSize,
                        height: compassSize,
                      ),
                      // Needle fixed pointing up
                      Image.asset(
                        'assets/images/drawable/hands.png',
                        width: compassSize * 0.8,
                        height: compassSize * 0.8,
                      ),
                      // Kaaba rotating around the dial
                      Transform.translate(
                        offset: Offset(
                          radius * sin(kaabaAngle),
                          -radius * cos(kaabaAngle),
                        ),
                        child: Image.asset(
                          'assets/images/drawable/7222554.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Heading: ${heading.toStringAsFixed(2)}°",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Qibla: ${qiblaDir.toStringAsFixed(2)}°",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Rotate your phone until the needle points toward the Kaaba",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
