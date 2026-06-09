import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/map_navigation.dart';

import '../../data/models/application_model.dart';
import '../../data/models/upcoming_interview_model.dart';
import '../controllers/applications_controller.dart';
import 'applications_pipeline_view.dart';

/// Liste des candidatures du candidat : statut, offre visée, score de
/// matching et entretien éventuel. Données via [ApplicationsController].
///
/// Deux modes de visualisation locaux : liste verticale (par défaut) ou
/// pipeline kanban en colonnes par statut, basculables via le toggle du
/// header.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final ApplicationsController controller = Get.find<ApplicationsController>();

  /// false = liste verticale ; true = pipeline kanban. État purement local
  /// (aucune route dédiée).
  bool _pipelineMode = false;

  void _setMode(bool pipeline) {
    if (_pipelineMode == pipeline) return;
    AppHaptics.tap();
    setState(() => _pipelineMode = pipeline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Mes candidatures',
            subtitle: 'Suivez l\'avancement de vos postulations',
            height: 230,
            gradient: AppColors.heroOffersGradient,
            onLeadingTap: () => Get.back(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ViewModeToggle(
                pipeline: _pipelineMode,
                onChanged: _setMode,
              ),
            ),
          ),
          Expanded(
            child: _pipelineMode
                ? const ApplicationsPipelineView()
                : _ApplicationsListView(controller: controller),
          ),
        ],
      ),
    );
  }
}

/// Toggle Liste ↔ Pipeline (deux segments d'icônes).
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.pipeline, required this.onChanged});
  final bool pipeline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            icon: IconlyLight.document,
            selected: !pipeline,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _ToggleSegment(
            icon: Icons.view_column_rounded,
            selected: pipeline,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.onPrimary : AppColors.hintColor,
        ),
      ),
    );
  }
}

/// Contenu en mode liste verticale (comportement historique de l'écran).
class _ApplicationsListView extends StatelessWidget {
  const _ApplicationsListView({required this.controller});
  final ApplicationsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _ApplicationsSkeleton();
      }
      if (controller.errorMessage.value != null) {
        return ErrorStateView(
          message: controller.errorMessage.value!,
          onRetry: controller.load,
        );
      }
      if (controller.applications.isEmpty) {
        return EmptyState(
          icon: IconlyLight.paper,
          title: 'Aucune candidature',
          subtitle:
              'Vous n\'avez pas encore postulé. Explorez les offres et tentez votre chance !',
          actionLabel: 'Voir les offres',
          onAction: () => Get.toNamed(AppRoutes.offers),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            if (controller.upcomingInterviews.isNotEmpty)
              _UpcomingInterviewsSection(
                  items: controller.upcomingInterviews.toList()),
            ...controller.applications.map((app) => _ApplicationCard(app: app)),
          ],
        ),
      );
    });
  }
}

/// Section "Prochains entretiens" — alimentée par
/// GET /applications/interviews/upcoming (géoloc + itinéraire + .ics).
class _UpcomingInterviewsSection extends StatelessWidget {
  const _UpcomingInterviewsSection({required this.items});
  final List<UpcomingInterview> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_rounded,
                size: 18, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Prochains entretiens',
                style: AppTextStyles.titleMd
                    .copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((i) => _InterviewCard(item: i)),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.item});
  final UpcomingInterview item;

  @override
  Widget build(BuildContext context) {
    final iv = item.interview;
    final when = iv?.dateHuman ??
        (iv?.date != null ? _formatDate(iv!.date!) : null);
    final canRoute = (iv?.hasCoordinates ?? false) &&
        iv?.lat != null &&
        iv?.lng != null;
    final canCalendar = (iv?.icsUrl ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.offerTitle,
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if ((item.companyName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.companyName!,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.bodyColor)),
          ],
          if (when != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 15, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(when,
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
          if ((iv?.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined,
                    size: 15, color: AppColors.hintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(iv!.address!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor)),
                ),
              ],
            ),
          ],
          if (canRoute || canCalendar) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canRoute)
                  Expanded(
                    child: _InterviewAction(
                      icon: Icons.directions_rounded,
                      label: 'Itinéraire',
                      onTap: () {
                        AppHaptics.tap();
                        MapNavigationLauncher.openCoordinates(iv!.lat!, iv.lng!);
                      },
                    ),
                  ),
                if (canRoute && canCalendar) const SizedBox(width: 10),
                if (canCalendar)
                  Expanded(
                    child: _InterviewAction(
                      icon: Icons.calendar_month_rounded,
                      label: 'Calendrier',
                      onTap: () {
                        AppHaptics.tap();
                        MapNavigationLauncher.openIcs(iv!.icsUrl!);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InterviewAction extends StatelessWidget {
  const _InterviewAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.color, this.bg, this.icon);
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
}

_StatusStyle _statusStyle(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.newApp:
      return _StatusStyle('Envoyée', AppColors.secondary,
          AppColors.secondarySoft, Icons.send_rounded);
    case ApplicationStatus.shortlisted:
      return _StatusStyle('Présélectionné', AppColors.success,
          AppColors.successSoft, Icons.star_rounded);
    case ApplicationStatus.interview:
      return _StatusStyle('Entretien', AppColors.warning,
          AppColors.warningSoft, Icons.event_available_rounded);
    case ApplicationStatus.rejected:
      return _StatusStyle('Non retenue', AppColors.error, AppColors.errorSoft,
          Icons.do_not_disturb_on_rounded);
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.app});
  final ApplicationModel app;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(app.status);
    final title = app.offer?.title ?? 'Offre #${app.offerId}';
    final company = app.offer?.company ?? '';
    final location = app.offer?.location ?? '';
    final matchPct = (app.aiMatchScore <= 1
            ? app.aiMatchScore * 100
            : app.aiMatchScore)
        .round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(company,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.bodyColor)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(style: style),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (location.isNotEmpty) ...[
                Icon(IconlyLight.location,
                    size: 14, color: AppColors.hintColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(location,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
              ],
              Icon(IconlyLight.calendar,
                  size: 14, color: AppColors.hintColor),
              const SizedBox(width: 4),
              Text(_formatDate(app.appliedAt),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.hintColor)),
              const Spacer(),
              if (matchPct > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSelected,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$matchPct% match',
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (app.isRejected &&
              (app.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Text(app.rejectionReason!,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.error, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style});
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 5),
          Text(style.label,
              style: AppTextStyles.labelSm
                  .copyWith(color: style.color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


class _ApplicationsSkeleton extends StatelessWidget {
  const _ApplicationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 5; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: SkeletonBox(width: double.infinity, height: 120, radius: 20),
          ),
      ],
    );
  }
}
