import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/offers/data/models/interview_details_model.dart';

/// Cible de navigation supportee — chaque cible mappe sur un deep link
/// fourni par le backend (cf. `ApplicationApiController::buildInterviewPayload`).
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

/// Helper pour ouvrir un itineraire GPS natif depuis l'app, sans sortir
/// de l'experience OpporTune (les deep links sont gardes "first-party").
///
/// Toutes les methodes sont best-effort : si l'app cible n'est pas installee,
/// `url_launcher` retombe sur le browser web mobile, qui propose lui-meme
/// l'install ou l'ouverture in-app.
class MapNavigationLauncher {
  MapNavigationLauncher._();

  /// Ouvre la cible recommandee pour l'OS courant. Sur iOS : Apple Maps,
  /// sinon Google Maps. Si l'OS n'a pas la cible, on tombe sur la 1ere
  /// disponible parmi google/waze/apple dans la nav fournie.
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

  /// Construit un deep link Google Maps a partir de coordonnees brutes.
  /// Utile si le backend ne renvoie pas (encore) le payload `navigation`
  /// — par exemple sur d'anciennes versions de l'API.
  static Future<bool> openCoordinates(double lat, double lng) {
    return _launch(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
  }

  /// Telecharge le .ics d'un entretien (ouvre dans le browser puis ajout
  /// au calendrier natif selon la conf de l'utilisateur).
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
