import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';

enum AppToastVariant { success, error, info, warning }

/// Toasts de marque OpporTune BF.
///
/// Card premium qui glisse depuis le haut :
///   - Pastille icône + halo doux (icône bounce-in via elasticOut)
///   - Titre + message avec hiérarchie typo
///   - Mini bouton ✕ à droite pour close manuel
///   - Barre de progression animée en bas (countdown auto-dismiss)
///   - Gradient de fond très léger teinté par la variante
///   - Glow shadow tinté + light shadow pour la profondeur
///
/// Usage simple :
/// ```dart
/// AppToast.success('Candidature envoyée');
/// AppToast.warning('Déjà postulé', 'Vous avez déjà candidaté à cette offre.');
/// AppToast.error('Erreur réseau', 'Vérifiez votre connexion.');
/// ```
class AppToast {
  AppToast._();

  static const Duration _defaultDuration = Duration(milliseconds: 3500);

  static void success(String title, [String? message, Duration? duration]) =>
      _show(
        title: title,
        message: message,
        variant: AppToastVariant.success,
        duration: duration ?? _defaultDuration,
      );

  static void error(String title, [String? message, Duration? duration]) =>
      _show(
        title: title,
        message: message,
        variant: AppToastVariant.error,
        duration: duration ?? const Duration(milliseconds: 4500),
      );

  static void info(String title, [String? message, Duration? duration]) =>
      _show(
        title: title,
        message: message,
        variant: AppToastVariant.info,
        duration: duration ?? _defaultDuration,
      );

  static void warning(String title, [String? message, Duration? duration]) =>
      _show(
        title: title,
        message: message,
        variant: AppToastVariant.warning,
        duration: duration ?? const Duration(milliseconds: 4000),
      );

  static void _show({
    required String title,
    String? message,
    required AppToastVariant variant,
    required Duration duration,
  }) {
    switch (variant) {
      case AppToastVariant.success:
        AppHaptics.success();
        break;
      case AppToastVariant.error:
        AppHaptics.error();
        break;
      case AppToastVariant.warning:
        AppHaptics.confirm();
        break;
      case AppToastVariant.info:
        AppHaptics.tap();
        break;
    }

    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.transparent,
        boxShadows: const [],
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        borderRadius: 20,
        padding: EdgeInsets.zero,
        duration: duration,
        animationDuration: const Duration(milliseconds: 360),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        isDismissible: true,
        dismissDirection: DismissDirection.up,
        messageText: _AppToastBody(
          title: title,
          message: message,
          variant: variant,
          duration: duration,
        ),
      ),
    );
  }
}

class _AppToastBody extends StatefulWidget {
  const _AppToastBody({
    required this.title,
    required this.message,
    required this.variant,
    required this.duration,
  });

  final String title;
  final String? message;
  final AppToastVariant variant;
  final Duration duration;

  @override
  State<_AppToastBody> createState() => _AppToastBodyState();
}

class _AppToastBodyState extends State<_AppToastBody>
    with TickerProviderStateMixin {
  /// Anime l'icone : scale 0 → 1 avec elasticOut (effet bounce premium).
  late final AnimationController _iconCtrl;
  /// Anime la barre de progression : 1.0 → 0.0 sur la duree du toast.
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    )..animateTo(0.0, curve: Curves.linear);
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  ({Color color, Color softBg, IconData icon}) get _palette {
    switch (widget.variant) {
      case AppToastVariant.success:
        return (
          color: AppColors.successStrong,
          softBg: AppColors.successSoft,
          icon: Icons.check_circle_rounded,
        );
      case AppToastVariant.error:
        return (
          color: AppColors.error,
          softBg: AppColors.error.withValues(alpha: 0.12),
          icon: Icons.error_rounded,
        );
      case AppToastVariant.warning:
        return (
          color: AppColors.warning,
          softBg: AppColors.warning.withValues(alpha: 0.14),
          icon: Icons.warning_amber_rounded,
        );
      case AppToastVariant.info:
        return (
          color: AppColors.primary,
          softBg: AppColors.surfaceIconSoft,
          icon: Icons.info_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    final tinted = p.color.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceCard, tinted],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: p.color.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: p.color.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.secondaryDeep.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenu principal
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icone avec bounce-in elasticOut + halo radial autour
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _iconCtrl,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            p.color.withValues(alpha: 0.18),
                            p.softBg,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: p.color.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(p.icon, color: p.color, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            widget.title,
                            style: AppTextStyles.titleMd.copyWith(
                              color: AppColors.titleColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.1,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (widget.message != null &&
                            widget.message!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.message!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                              height: 1.4,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton close ✕ — petit, discret, tappable.
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        AppHaptics.tap();
                        if (Get.isSnackbarOpen) Get.closeAllSnackbars();
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar countdown — fine, teintee, animee de 100% a 0%.
            AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, __) {
                return SizedBox(
                  height: 3,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(color: p.color.withValues(alpha: 0.10)),
                      FractionallySizedBox(
                        widthFactor: _progressCtrl.value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                p.color.withValues(alpha: 0.5),
                                p.color,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
