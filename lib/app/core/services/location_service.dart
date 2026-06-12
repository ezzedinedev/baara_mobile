import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Cause d'échec d'une demande de position — permet à l'UI d'afficher un
/// message adapté (et d'orienter l'utilisateur vers le bon réglage).
enum LocationFailure {
  serviceDisabled, // GPS du téléphone désactivé
  permissionDenied, // refusé cette fois
  permissionDeniedForever, // refusé définitivement → réglages de l'app
  timeout, // position non obtenue à temps
  unknown,
}

/// Résultat d'une demande de position : soit une position (+ adresse lisible),
/// soit une cause d'échec typée.
class LocationResult {
  final Position? position;
  final String? address;
  final LocationFailure? failure;

  const LocationResult.success(this.position, this.address) : failure = null;
  const LocationResult.failed(this.failure)
      : position = null,
        address = null;

  bool get ok => position != null;
}

/// Point d'entrée unique pour la géolocalisation GPS de l'app.
/// Centralise : vérification du service, permissions (y compris refus
/// définitif), récupération de la position avec timeout, et reverse-geocoding.
/// Réutilisable partout (messages, entretiens, proximité des offres…).
class LocationService {
  const LocationService();

  static const _timeout = Duration(seconds: 15);

  /// Récupère la position courante. [withAddress] effectue un reverse-geocoding
  /// pour obtenir une adresse lisible (best-effort, n'échoue jamais le résultat).
  Future<LocationResult> getCurrentLocation({bool withAddress = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failed(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failed(
          LocationFailure.permissionDeniedForever);
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult.failed(LocationFailure.permissionDenied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _timeout,
      );
      final address = withAddress ? await _reverseGeocode(position) : null;
      return LocationResult.success(position, address);
    } on TimeoutException {
      return const LocationResult.failed(LocationFailure.timeout);
    } catch (_) {
      return const LocationResult.failed(LocationFailure.unknown);
    }
  }

  /// Adresse lisible « rue, ville, région » à partir des coordonnées.
  Future<String?> _reverseGeocode(Position position) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.locality, p.administrativeArea]
            .whereType<String>()
            .where((x) => x.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    return null;
  }

  /// Ouvre les réglages GPS du téléphone (cas service désactivé).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Ouvre les réglages de l'app (cas refus définitif).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
