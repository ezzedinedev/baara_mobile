import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/core/theme/app_colors.dart';
import '../../app/core/theme/app_text_styles.dart';
import '../../app/core/utils/haptics.dart';

enum AppToastVariant { success, error, info, warning }

/// Toasts de marque : icone coloree dans une pastille + titre + message,
/// slide-in depuis le haut, dismissable au tap. Remplace les `Get.snackbar`
/// generiques pour garantir la cohérence UX.
class AppToast {
  AppToast._();

  static void success(String title, [String? message]) =>
      _show(title: title, message: message, variant: AppToastVariant.success);

  static void error(String title, [String? message]) =>
      _show(title: title, message: message, variant: AppToastVariant.error);

  static void info(String title, [String? message]) =>
      _show(title: title, message: message, variant: AppToastVariant.info);

  static void warning(String title, [String? message]) =>
      _show(title: title, message: message, variant: AppToastVariant.warning);

  static void _show({
    required String title,
    String? message,
    required AppToastVariant variant,
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
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        borderRadius: 18,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 320),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        isDismissible: true,
        dismissDirection: DismissDirection.up,
        messageText: _AppToastBody(
          title: title,
          message: message,
          variant: variant,
        ),
      ),
    );
  }
}

class _AppToastBody extends StatelessWidget {
  const _AppToastBody({
    required this.title,
    required this.message,
    required this.variant,
  });

  final String title;
  final String? message;
  final AppToastVariant variant;

  ({Color color, Color softBg, IconData icon}) get _palette {
    switch (variant) {
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: p.color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: p.color.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.softBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(p.icon, color: p.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMd.copyWith(
                    color: p.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
