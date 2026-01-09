// LocationService.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDataModel {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  LocationDataModel({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static Future<LocationDataModel> getUserCityAndCountry() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationDataModel(city: "Location disabled", country: "", latitude: 0, longitude: 0);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationDataModel(city: "Permission denied", country: "", latitude: 0, longitude: 0);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationDataModel(city: "Permission denied forever", country: "", latitude: 0, longitude: 0);
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.first;

    final city = place.locality ?? place.subAdministrativeArea ?? "Unknown city";
    final country = place.country ?? "Unknown country";

    return LocationDataModel(
      city: city,
      country: country,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
