import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

class LocationLinks {
  LocationLinks._();

  // ==============================
  // ✅ نفس فكرة getParam في JS
  // ==============================
  static String? getParam(String url, String name) {
    final uri = Uri.parse(url);
    return uri.queryParameters[name];
  }

  // ==============================
  // ✅ Google Earth URL
  // ==============================
  static String earthUrl(double lat, double lng) {
    return 'https://earth.google.com/web/search/'
        '${Uri.encodeComponent(lat.toString())},'
        '${Uri.encodeComponent(lng.toString())}';
  }

  // ==============================
  // ✅ Google Maps URL
  // ==============================
  static String mapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps?q='
        '${Uri.encodeComponent(lat.toString())},'
        '${Uri.encodeComponent(lng.toString())}';
  }

  // ==============================
  // ✅ فتح Google Maps
  // ==============================
  static Future<void> openMaps(
    BuildContext context, {
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(mapsUrl(lat, lng));

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      _snack(context, 'تعذر فتح Google Maps', error: true);
    }
  }

  // ==============================
  // ✅ فتح Google Earth
  // ==============================
  static Future<void> openEarth(
    BuildContext context, {
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(earthUrl(lat, lng));

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      _snack(context, 'تعذر فتح Google Earth', error: true);
    }
  }

  // ==============================
  // ✅ نسخ الرابط
  // ==============================
  static Future<void> copyMapsLink(
    BuildContext context, {
    required double lat,
    required double lng,
  }) async {
    await Clipboard.setData(
      ClipboardData(text: mapsUrl(lat, lng)),
    );

    if (!context.mounted) return;

    _snack(context, 'تم نسخ رابط الموقع');
  }

  static Future<void> copyEarthLink(
    BuildContext context, {
    required double lat,
    required double lng,
  }) async {
    await Clipboard.setData(
      ClipboardData(text: earthUrl(lat, lng)),
    );

    if (!context.mounted) return;

    _snack(context, 'تم نسخ رابط Google Earth');
  }

  // ==============================
  // ✅ SnackBar احترافي
  // ==============================
  static void _snack(
    BuildContext context,
    String msg, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.destructive : null,
        ),
      );
  }
}