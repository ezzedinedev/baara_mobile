import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import '../../data/models/application_model.dart';
import '../controllers/applications_controller.dart';

/// Vue "pipeline" (kanban) des candidatures du candidat : colonnes
/// horizontales scrollables groupées par statut. Réutilise les données de
/// [ApplicationsController] (mêmes états loading/error/empty que la liste).
class ApplicationsPipelineView extends GetView<ApplicationsController> {
  const ApplicationsPipelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _PipelineSkeleton();
      }
      if (controller.errorMessage.value != null) {
        return ErrorStateView(
          message: controller.errorMessage.value!,
          illustration: const ErrorIllustration(),
          onRetry: controller.load,
        );
      }
      if (controller.applications.isEmpty) {
        return EmptyState(
          illustration: const EmptyApplicationsIllustration(),
          title: 'Aucune candidature',
          subtitle:
              'Vous n\'avez pas encore postulé. Explorez les offres et tentez votre chance !',
          actionLabel: 'Voir les offres',
          onAction: () => Get.toNamed(AppRoutes.offers),
        );
      }

      final grouped = _groupByStatus(controller.applications);

      return AppRefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: controller.load,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            for (final col in _columns)
              _PipelineColumn(
                config: col,
                apps: grouped[col.status] ?? const [],
              ),
          ],
        ),
      );
    });
  }

  static Map<ApplicationStatus, List<ApplicationModel>> _groupByStatus(
      List<ApplicationModel> apps) {
    final map = <ApplicationStatus, List<ApplicationModel>>{};
    for (final app in apps) {
      (map[app.status] ??= []).add(app);
    }
    return map;
  }
}

/// Configuration d'une colonne du pipeline (libellé + couleurs cohérentes
/// avec les badges de la liste).
class _ColumnConfig {
  const _ColumnConfig(this.status, this.label, this.icon);
  final ApplicationStatus status;
  final String label;
  final IconData icon;
}

const List<_ColumnConfig> _columns = [
  _ColumnConfig(ApplicationStatus.newApp, 'Envoyées', IconlyLight.send),
  _ColumnConfig(ApplicationStatus.shortlisted, 'Présélection', IconlyBold.star),
  _ColumnConfig(ApplicationStatus.interview, 'Entretien', IconlyLight.calendar),
  _ColumnConfig(
      ApplicationStatus.rejected, 'Refusées', Icons.do_not_disturb_on_rounded),
];

/// Couleur d'accent par statut (getters theme-aware → pas de const ici).
Color _statusColor(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.newApp:
      return AppColors.primaryAccent;
    case ApplicationStatus.shortlisted:
      return AppColors.successAccent;
    case ApplicationStatus.interview:
      return AppColors.warningAccent;
    case ApplicationStatus.rejected:
      return AppColors.errorAccent;
  }
}

Color _statusSoft(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.newApp:
      return AppColors.secondarySoft;
    case ApplicationStatus.shortlisted:
      return AppColors.successSoft;
    case ApplicationStatus.interview:
      return AppColors.warningSoft;
    case ApplicationStatus.rejected:
      return AppColors.errorSoft;
  }
}

class _PipelineColumn extends StatelessWidget {
  const _PipelineColumn({required this.config, required this.apps});
  final _ColumnConfig config;
  final List<ApplicationModel> apps;

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(config.status);
    final soft = _statusSoft(config.status);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête coloré + compteur.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: ShapeDecoration(
              color: soft,
              shape: AppShapes.squircle(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(config.icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.label,
                    style: AppTextStyles.titleMd
                        .copyWith(color: accent, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${apps.length}',
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Cartes empilées verticalement (scroll vertical par colonne).
          Expanded(
            child: apps.isEmpty
                ? _EmptyColumn(accent: accent)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: apps.length,
                    itemBuilder: (context, i) =>
                        _PipelineCard(app: apps[i], accent: accent),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: AppColors.surfaceLow,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Aucune candidature',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.app, required this.accent});
  final ApplicationModel app;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = app.offer?.title ?? 'Offre #${app.offerId}';
    final company = app.offer?.company ?? '';
    final matchPct =
        (app.aiMatchScore <= 1 ? app.aiMatchScore * 100 : app.aiMatchScore)
            .round();

    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', app.offerId));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          // Profondeur en couches (2026) + liseré d'accent de colonne.
          boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (company.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                company,
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (matchPct > 0) ...[
              const SizedBox(height: 10),
              MatchScorePill(score: matchPct, dense: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _PipelineSkeleton extends StatelessWidget {
  const _PipelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        for (var c = 0; c < 3; c++)
          Container(
            width: 280,
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SkeletonBox(
                    width: double.infinity, height: 44, radius: 16),
                const SizedBox(height: 12),
                for (var i = 0; i < 3; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonBox(
                        width: double.infinity, height: 96, radius: 16),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
