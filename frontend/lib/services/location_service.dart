import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Return cached or fallback if service is disabled
        return _lastKnownPosition ?? _defaultPosition();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _lastKnownPosition ?? _defaultPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _lastKnownPosition ?? _defaultPosition();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _lastKnownPosition = position;
      return position;
    } catch (_) {
      return _lastKnownPosition ?? _defaultPosition();
    }
  }

  // Realistic default coordinates (Dhaka metropolitan) if permissions unavailable
  Position _defaultPosition() {
    return Position(
      longitude: 90.4125,
      latitude: 23.8103,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}
