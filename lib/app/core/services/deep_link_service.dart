import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/services/auth_token_store.dart';
import 'package:baara/app/core/services/onboarding_service.dart';
import 'package:baara/routes/app_routes.dart';

/// Gère les liens entrants (deep links) :
/// - schéma custom `baara://profil/{id}` (et `…/offres/{id}`)
/// - liens web `https://<site>/profil/{id}` (App Links / Universal Links)
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial, cold: true);
    } catch (_) {}

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

  Future<void> _handle(Uri uri, {required bool cold}) async {
    final route = _routeFor(uri);
    if (route == null) return;

    if (Get.isRegistered<OnboardingService>()) {
      final onboarding = Get.find<OnboardingService>();
      if (!await onboarding.isCompleted()) {
        await onboarding.stashPendingRoute(route);
        const tokenStore = AuthTokenStore();
        final token = await tokenStore.readTokenOrNull();
        if (token != null && token.isNotEmpty &&
            Get.currentRoute != AppRoutes.onboarding) {
          Get.offAllNamed(AppRoutes.onboarding);
        }
        return;
      }
    }

    final delay = cold
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 50);
    Future<void>.delayed(delay, () => Get.toNamed<void>(route));
  }

  String? _routeFor(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();

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

