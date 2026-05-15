import 'package:geolocator/geolocator.dart'; // المكتبة الرسمية للتعامل مع الموقع الجغرافي

/// كلاس مساعد لتغليف بيانات الموقع (خط الطول والعرض) مع ملصق توضيحي وحالة الفشل.
class UserLocationData {
  final double latitude;
  final double longitude;
  final bool
      isFallback; // هل الموقع حقيقي أم افتراضي (في حال رفض المستخدم الصلاحية)
  final String label;

  const UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    required this.label,
  });
}

/// تعتمد هذه الخدمة على مستشعرات الهاتف لتوفير تجربة بحث ذكية بناءً على القرب المكاني.
class LocationService {
  // موقع افتراضي (الرياض) يستخدم في حال تعذر الوصول للموقع الفعلي
  static const UserLocationData _fallback = UserLocationData(
    latitude: 24.7136,
    longitude: 46.6753,
    isFallback: true,
    label: 'الموقع الافتراضي: الرياض',
  );

  /// طلب الصلاحيات وجلب الموقع الحالي للجهاز بدقة عالية.
  Future<UserLocationData> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallback;
      // فحص ومعالجة صلاحيات الوصول للموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback;
      }
      // جلب الإحداثيات الفعلية للجهاز
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

  /// حساب المسافة بالكيلومترات: تستخدم معادلة (Haversine) الرياضية لمقارنة موقعين جغرافيين.
  double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000;
  }
}
