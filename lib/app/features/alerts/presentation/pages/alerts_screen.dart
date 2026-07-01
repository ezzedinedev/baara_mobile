import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import '../../../offers/presentation/controllers/offer_controller.dart';
import '../../domain/entities/saved_search.dart';
import '../controllers/alerts_controller.dart';

/// Écran « Mes alertes » : liste des recherches sauvegardées du candidat.
/// Chaque alerte peut être (dé)activée (notifications), supprimée, ou rejouée
/// (tap → applique ses filtres à la liste d'offres).
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AlertsController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Mes alertes',
            subtitle: 'Sois notifié dès qu\'une offre correspond',
            height: 220,
            gradient: AppColors.heroOffersGradient,
            onLeadingTap: () => Get.back(),
          ),
          Expanded(child: _AlertsBody(controller: controller)),
        ],
      ),
    );
  }
}

class _AlertsBody extends StatelessWidget {
  const _AlertsBody({required this.controller});
  final AlertsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _skeleton();
      }
      if (controller.errorMessage.value != null) {
        return ErrorStateView(
          message: controller.errorMessage.value!,
          onRetry: controller.load,
        );
      }
      if (controller.alerts.isEmpty) {
        return EmptyState(
          icon: IconlyLight.notification,
          title: 'Aucune alerte',
          subtitle:
              'Filtre les offres puis touche « Créer une alerte » pour être notifié des nouvelles offres qui te correspondent.',
          actionLabel: 'Voir les offres',
          onAction: () => Get.toNamed(AppRoutes.offers),
        );
      }
      return AppRefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: controller.load,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: controller.alerts.length,
            itemBuilder: (context, i) {
              final alert = controller.alerts[i];
              return AnimationConfiguration.staggeredList(
                position: i,
                duration: AppMotion.medium,
                child: SlideAnimation(
                  verticalOffset: AppMotion.listSlideOffset,
                  curve: AppMotion.emphasizedDecelerate,
                  child: FadeInAnimation(
                    child: _AlertCard(alert: alert, controller: controller),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _skeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: SkeletonBox(width: double.infinity, height: 96, radius: 20),
          ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.controller});
  final SavedSearch alert;
  final AlertsController controller;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('alert-${alert.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        AppHaptics.tap();
        final ok = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            ),
            title: Text('Supprimer l\'alerte',
                style:
                    AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
            content: Text(
              'Supprimer « ${alert.label} » ? Tu ne recevras plus de notifications pour cette recherche.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Annuler',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.hintColor)),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('Supprimer',
                    style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.errorAccent,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) => controller.delete(alert),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg - 2),
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: ShapeDecoration(
          color: AppColors.errorSoft,
          shape: AppShapes.squircle(AppRadius.lg),
        ),
        child: Icon(IconlyLight.delete, color: AppColors.errorAccent, size: 22),
      ),
      child: PressScale(
        onTap: () => _openSearch(alert),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg - 2),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceIconSoft,
                      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                    ),
                    child: Icon(IconlyLight.notification,
                        size: 20, color: AppColors.primaryAccent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(alert.label,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  // Bascule notifications on/off.
                  Switch.adaptive(
                    value: alert.notify,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) {
                      AppHaptics.tap();
                      controller.toggleNotify(alert);
                    },
                  ),
                ],
              ),
              if (alert.chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      alert.chips.map((c) => _CriteriaChip(label: c)).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(IconlyLight.work, size: 14, color: AppColors.hintColor),
                  const SizedBox(width: 6),
                  Text(
                    alert.matchCount > 0
                        ? '${alert.matchCount} offre${alert.matchCount > 1 ? 's' : ''} correspondante${alert.matchCount > 1 ? 's' : ''}'
                        : 'Aucune offre pour l\'instant',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor),
                  ),
                  const Spacer(),
                  Text('Voir',
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w700)),
                  Icon(IconlyLight.arrow_right_2,
                      size: 16, color: AppColors.primaryAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rejoue la recherche : applique les filtres de l'alerte à la liste
  /// d'offres. Si le controller d'offres est déjà en pile, on l'applique et on
  /// revient dessus ; sinon on ouvre la liste avec les filtres en arguments.
  void _openSearch(SavedSearch alert) {
    AppHaptics.tap();
    if (Get.isRegistered<OfferController>()) {
      Get.find<OfferController>().applySavedFilters(alert.filters);
      Get.back();
    } else {
      Get.offNamed(AppRoutes.offers, arguments: {'filters': alert.filters});
    }
  }
}

class _CriteriaChip extends StatelessWidget {
  const _CriteriaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: AppColors.surfaceLow,
        shape: AppShapes.squircle(AppRadius.sm),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.bodyColor, fontWeight: FontWeight.w600)),
    );
  }
}
