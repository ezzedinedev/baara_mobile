import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/offers/data/models/interview_details_model.dart';

enum MapTarget { googleMaps, waze, appleMaps }

extension MapTargetMeta on MapTarget {
  String get label {
    switch (this) {
      case MapTarget.googleMaps:
        return 'Google Maps';
      case MapTarget.waze:
        return 'Waze';
      case MapTarget.appleMaps:
        return 'Plans (Apple)';
    }
  }
}

class MapNavigationLauncher {
  MapNavigationLauncher._();
  static Future<bool> openDefault(InterviewNavigation nav) async {
    if (kIsWeb) {
      return _launch(nav.googleMapsUrl ?? nav.wazeUrl ?? nav.appleMapsUrl);
    }
    if (Platform.isIOS && nav.appleMapsUrl != null) {
      return _launch(nav.appleMapsUrl);
    }
    return _launch(nav.googleMapsUrl ?? nav.wazeUrl ?? nav.appleMapsUrl);
  }

  static Future<bool> open(InterviewNavigation nav, MapTarget target) async {
    switch (target) {
      case MapTarget.googleMaps:
        return _launch(nav.googleMapsUrl);
      case MapTarget.waze:
        return _launch(nav.wazeUrl);
      case MapTarget.appleMaps:
        return _launch(nav.appleMapsUrl);
    }
  }

  static Future<bool> openCoordinates(double lat, double lng) {
    return _launch(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
  }

  static Future<bool> openIcs(String icsUrl) => _launch(icsUrl);

  static Future<bool> _launch(String? url) async {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
