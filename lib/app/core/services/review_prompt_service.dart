import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../widgets/common/confirm_sheet.dart';

/// Déclenchement rate-limité du prompt « noter l'app » (après milestones).
class ReviewPromptService {
  ReviewPromptService._();
  static final ReviewPromptService instance = ReviewPromptService._();

  static const _applicationsKey = 'review_prompt_applications';
  static const _shownKey = 'review_prompt_shown_v1';
  static const _milestone = 3;

  Future<void> recordApplicationSent() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_shownKey) == true) return;
    final count = (prefs.getInt(_applicationsKey) ?? 0) + 1;
    await prefs.setInt(_applicationsKey, count);
    if (count >= _milestone) {
      await maybeShowPrompt();
    }
  }

  Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_shownKey) == true) return false;
    return (prefs.getInt(_applicationsKey) ?? 0) >= _milestone;
  }

  Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shownKey, true);
  }

  /// Feuille « Noter Baara » — manuel (Paramètres) ou auto après milestone.
  Future<void> maybeShowPrompt({bool force = false}) async {
    if (!force && !await shouldPrompt()) return;
    final ctx = Get.context;
    if (ctx == null || !ctx.mounted) return;

    if (!force) await markPromptShown();
    if (!ctx.mounted) return;
    final go = await showConfirmSheet(
      context: ctx,
      icon: AppIcons.star,
      iconColor: AppColors.warningAccent,
      title: 'Vous aimez Baara ?',
      message:
          'Votre avis aide d\'autres candidats à trouver leur prochaine '
          'opportunité. Une minute suffit sur le store.',
      confirmLabel: 'Noter l\'app',
      cancelLabel: 'Plus tard',
    );
    if (go == true) await openStoreListing();
  }

  Future<void> openStoreListing() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/search?term=Baara%20bf')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.Baara.bf');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
