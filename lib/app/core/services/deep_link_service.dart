import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/routes/app_routes.dart';

/// Gère les liens entrants (deep links) :
/// - schéma custom `opportunebf://profil/{id}` (et `…/offres/{id}`)
/// - liens web `https://<site>/profil/{id}` (App Links / Universal Links)
///
/// Mappe l'URI vers une route interne et y navigue via GetX. Singleton initialisé
/// une fois au démarrage de l'app (cf. racine `OpportuneBFApp`).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    // Lien d'ouverture à froid (app lancée par le lien).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial, cold: true);
    } catch (_) {
      // Pas de lien initial / plateforme non supportée : on ignore.
    }

    // Liens reçus pendant que l'app tourne (warm).
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, cold: false),
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void _handle(Uri uri, {required bool cold}) {
    final route = _routeFor(uri);
    if (route == null) return;
    // À froid, on laisse le GetMaterialApp et la route initiale se monter
    // avant de pousser la destination du lien.
    final delay = cold
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 50);
    Future<void>.delayed(delay, () => Get.toNamed<void>(route));
  }

  /// Traduit un URI entrant en route interne, ou `null` s'il n'est pas géré.
  String? _routeFor(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Schéma custom : opportunebf://profil/{id} → host='profil', segs=['{id}'].
    if (uri.scheme == ApiConstants.deepLinkScheme) {
      if (uri.host == 'profil' && segs.isNotEmpty) {
        return AppRoutes.communityProfile.replaceFirst(':id', segs.first);
      }
      if ((uri.host == 'offres' || uri.host == 'offers') && segs.isNotEmpty) {
        return AppRoutes.offerDetail.replaceFirst(':id', segs.first);
      }
      if ((uri.host == 'formations' || uri.host == 'trainings') &&
          segs.isNotEmpty) {
        return AppRoutes.trainingDetail.replaceFirst(':id', segs.first);
      }
      if ((uri.host == 'messages' || uri.host == 'conversations') &&
          segs.isNotEmpty) {
        return AppRoutes.conversation.replaceFirst(':id', segs.first);
      }
      if (uri.host == 'communaute' && segs.length >= 2 && segs[0] == 'membre') {
        return AppRoutes.communityProfile.replaceFirst(':id', segs[1]);
      }
      return null;
    }

    // Liens web (http/https) : /profil/{id} ou /communaute/membre/{id}.
    if (segs.length >= 2 && segs[0] == 'profil') {
      return AppRoutes.communityProfile.replaceFirst(':id', segs[1]);
    }
    if (segs.length >= 3 && segs[0] == 'communaute' && segs[1] == 'membre') {
      return AppRoutes.communityProfile.replaceFirst(':id', segs[2]);
    }
    if (segs.length >= 2 && (segs[0] == 'offres' || segs[0] == 'offers')) {
      return AppRoutes.offerDetail.replaceFirst(':id', segs[1]);
    }
    if (segs.length >= 2 &&
        (segs[0] == 'formations' || segs[0] == 'trainings')) {
      return AppRoutes.trainingDetail.replaceFirst(':id', segs[1]);
    }
    if (segs.length >= 2 &&
        (segs[0] == 'messages' || segs[0] == 'conversations')) {
      return AppRoutes.conversation.replaceFirst(':id', segs[1]);
    }
    return null;
  }
}
