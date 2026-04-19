import 'package:geolocator/geolocator.dart';

class UserLocationData {
  final double latitude;
  final double longitude;
  final bool isFallback;
  final String label;

  const UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    required this.label,
  });
}

class LocationService {
  static const UserLocationData _fallback = UserLocationData(
    latitude: 24.7136,
    longitude: 46.6753,
    isFallback: true,
    label: 'الموقع الافتراضي: الرياض',
  );

  Future<UserLocationData> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallback;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return UserLocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        isFallback: false,
        label: 'تم تحديد موقعك الحالي',
      );
    } catch (_) {
      return _fallback;
    }
  }

  double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000;
  }
}
