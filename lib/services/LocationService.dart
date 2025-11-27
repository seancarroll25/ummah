import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDataModel {
  final String city;
  final String country;

  LocationDataModel(this.city, this.country);
}

class LocationService {
  static Future<LocationDataModel> getUserCityAndCountry() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationDataModel("Location disabled", "");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationDataModel("Permission denied", "");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationDataModel("Permission denied forever", "");
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    final place = placemarks.first;
    final city = place.locality ?? place.subAdministrativeArea ?? "Unknown city";
    final country = place.country ?? "Unknown country";
    return LocationDataModel(city, country);
  }
}
