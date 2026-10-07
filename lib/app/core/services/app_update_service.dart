import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';
import '../network/api_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_text_styles.dart';
import '../widgets/widgets.dart';

/// Mises à jour de l'application, pilotées depuis l'admin du site
/// (Admin > Application mobile) via `GET /app/version`.
///
/// - Version installée < `minimum` : écran bloquant jusqu'à la mise à jour.
/// - Version installée < `latest`  : invitation reportable, montrée une seule
///   fois par version.
///
/// Toute erreur (réseau, serveur) est silencieuse : on ne bloque jamais un
/// utilisateur parce que la vérification a échoué.
abstract final class AppUpdateService {
  static const _dismissedKey = 'app_update_dismissed_version';
  static bool _checked = false;

  static Future<void> checkAndPrompt() async {
    if (_checked || kIsWeb) return;
    _checked = true;
    try {
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      final response = await Get.find<ApiProvider>()
          .getJson('${ApiConstants.appVersion}?platform=$platform');
      final data = response['data'];
      if (data is! Map) return;

      final latest = '${data['latest'] ?? ''}';
      final minimum = '${data['minimum'] ?? ''}';
      final message = (data['message'] as String?)?.trim();
      final storeUrl = '${data['store_url'] ?? ''}';
      final current = (await PackageInfo.fromPlatform()).version;

      if (isOlder(current, minimum)) {
        Get.offAll<void>(
          () => _ForceUpdateScreen(message: message, storeUrl: storeUrl),
          transition: Transition.fadeIn,
        );
        return;
      }
      if (!isOlder(current, latest)) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dismissedKey) == latest) return;
      await Get.bottomSheet<void>(
        _UpdateSheet(version: latest, message: message, storeUrl: storeUrl),
        isScrollControlled: true,
      );
      await prefs.setString(_dismissedKey, latest);
    } catch (e) {
      if (kDebugMode) debugPrint('[AppUpdate] vérification ignorée : $e');
    }
  }

  /// `a` < `b` en comparant les versions « 1.2.3 » champ par champ.
  @visibleForTesting
  static bool isOlder(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final x = parts(a);
    final y = parts(b);
    if (y.every((n) => n == 0)) return false;
    for (var i = 0; i < 3; i++) {
      final xi = i < x.length ? x[i] : 0;
      final yi = i < y.length ? y[i] : 0;
      if (xi != yi) return xi < yi;
    }
    return false;
  }

  static Future<void> _openStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Mise à jour obligatoire : même langage que le splash, aucune sortie.
class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen({required this.message, required this.storeUrl});

  final String? message;
  final String storeUrl;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: BaaraMark.brandForest,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: [
                const Spacer(),
                const BaaraMark(
                  size: 96,
                  color: Colors.white,
                  headColor: BaaraMark.brandLime,
                ),
                const SizedBox(height: 32),
                Semantics(
                  header: true,
                  child: Text(
                    'Mise à jour requise',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayHero.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (message == null || message!.isEmpty)
                      ? 'Cette version de Baara n\'est plus prise en charge. '
                          'Installez la dernière version pour continuer.'
                      : message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                AuthCtaButton(
                  label: 'Mettre à jour',
                  backgroundColor: BaaraMark.brandLime,
                  foregroundColor: BaaraMark.brandForest,
                  onPressed: () => AppUpdateService._openStore(storeUrl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nouvelle version disponible : invitation reportable.
class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.version,
    required this.message,
    required this.storeUrl,
  });

  final String version;
  final String? message;
  final String storeUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SheetHandle()),
              const SizedBox(height: 18),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BaaraMark.brandForest,
                  borderRadius: AppShapes.squircleRadius(14),
                ),
                child: const BaaraMark(
                  size: 26,
                  color: Colors.white,
                  headColor: BaaraMark.brandLime,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Nouvelle version disponible',
                style: AppTextStyles.headlineMd
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                (message == null || message!.isEmpty)
                    ? 'Baara $version est disponible, avec des améliorations '
                        'et des corrections.'
                    : message!,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.bodyColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              AuthCtaButton(
                label: 'Mettre à jour',
                onPressed: () {
                  Get.back<void>();
                  AppUpdateService._openStore(storeUrl);
                },
              ),
              Center(
                child: TextButton(
                  onPressed: () => Get.back<void>(),
                  child: Text(
                    'Plus tard',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.bodyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
