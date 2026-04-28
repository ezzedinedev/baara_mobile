import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/offers_controller.dart';
import '../models/application_model.dart';

/// Vue "Mes candidatures" — liste des candidatures envoyees par le candidat.
/// Source : `GET /api/v1/applications` via [OffersController.loadMyApplications].
/// Affiche le score serveur (`ai_match_score`), le statut backend, la date,
/// et un filtre par statut.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final OffersController controller = Get.find<OffersController>();
  final Rx<ApplicationStatus?> _filter = Rx<ApplicationStatus?>(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyApplications();
    });
  }

  bool _matches(ApplicationModel a) {
    final f = _filter.value;
    if (f == null) return true;
    return a.status == f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          RevealOnMount(
            offsetY: 18,
            child: WavyContentHeader(
              title: 'applications.title'.tr,
              subtitle: 'applications.subtitle'.tr,
              gradient: AppColors.heroOffersGradient,
              actions: [
                WavyHeaderActionButton(
                  icon: IconlyLight.filter,
                  onTap: () {
                    AppHaptics.tap();
                    _showFilterSheet(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLoading = controller.isLoadingApplications.value;
              final error = controller.applicationsError.value;
              final raw = controller.myApplications;
              _filter.value;
              final filtered =
                  raw.where(_matches).toList(growable: false);

              if (isLoading && raw.isEmpty) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => const OfferCardSkeleton(height: 160),
                );
              }

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.loadMyApplications,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: error.isNotEmpty
                            ? ErrorStateView(
                                message: error,
                                onRetry: controller.loadMyApplications,
                              )
                            : EmptyState(
                                icon: IconlyLight.work,
                                title: _filter.value == null
                                    ? 'Aucune candidature'
                                    : 'Aucune candidature dans ce statut',
                                subtitle: _filter.value == null
                                    ? 'Postulez a vos premieres offres pour les voir ici.'
                                    : 'Changez ou retirez le filtre pour voir plus de candidatures.',
                              ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadMyApplications,
                child: AnimationLimiter(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 130),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 280),
                        child: SlideAnimation(
                          verticalOffset: 14,
                          child: FadeInAnimation(
                            child: _ApplicationTile(application: app),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Filtrer par statut',
                style: AppTextStyles.titleLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Toutes',
                      selected: _filter.value == null,
                      onTap: () {
                        AppHaptics.tap();
                        _filter.value = null;
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    ...ApplicationStatus.values.map(
                      (s) => _FilterChip(
                        label: s.label,
                        selected: _filter.value == s,
                        onTap: () {
                          AppHaptics.tap();
                          _filter.value = s;
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                : null,
            color: selected ? null : AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.titleMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.bodyColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application});
  final ApplicationModel application;

  ({Color color, Color soft, IconData icon, String label}) _statusPalette() {
    switch (application.status) {
      case ApplicationStatus.newApp:
        return (
          color: AppColors.categoryBlue,
          soft: AppColors.categoryBlue.withValues(alpha: 0.12),
          icon: IconlyBold.send,
          label: 'Envoyee',
        );
      case ApplicationStatus.shortlisted:
        return (
          color: AppColors.categoryPurple,
          soft: AppColors.categoryPurple.withValues(alpha: 0.12),
          icon: IconlyBold.star,
          label: 'Preselectionnee',
        );
      case ApplicationStatus.evaluation:
        return (
          color: AppColors.categoryOrange,
          soft: AppColors.categoryOrange.withValues(alpha: 0.12),
          icon: IconlyBold.activity,
          label: 'En evaluation',
        );
      case ApplicationStatus.interview:
        return (
          color: AppColors.categoryCyan,
          soft: AppColors.categoryCyan.withValues(alpha: 0.12),
          icon: IconlyBold.chat,
          label: 'Entretien',
        );
      case ApplicationStatus.offer:
        return (
          color: AppColors.successStrong,
          soft: AppColors.successSoft,
          icon: IconlyBold.tick_square,
          label: 'Offre recue',
        );
      case ApplicationStatus.rejected:
        return (
          color: AppColors.error,
          soft: AppColors.error.withValues(alpha: 0.12),
          icon: IconlyBold.close_square,
          label: 'Rejetee',
        );
      case ApplicationStatus.withdrawn:
        return (
          color: AppColors.bodyColor,
          soft: AppColors.surfaceLow,
          icon: IconlyBold.arrow_left_2,
          label: 'Retiree',
        );
    }
  }

  String _appliedAtLabel() {
    final d = application.appliedAt;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette();
    final score = application.aiMatchScore?.round();
    final hasOffer = application.offer != null;
    final offer = application.offer;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Score circulaire ou badge "—" si pas de score.
              if (score != null)
                _ScoreCircle(score: score)
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLow,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '—',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.hintColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasOffer ? offer!.title : 'Offre #${application.offerId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (hasOffer) ...[
                      const SizedBox(height: 2),
                      Text(
                        offer!.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.soft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: palette.color.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(palette.icon, size: 13, color: palette.color),
                    const SizedBox(width: 5),
                    Text(
                      palette.label,
                      style: AppTextStyles.labelSm.copyWith(
                        color: palette.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                IconlyLight.calendar,
                size: 13,
                color: AppColors.hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                _appliedAtLabel(),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.hintColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (application.isRejected &&
              application.rejectionReason != null &&
              application.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    IconlyLight.info_square,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.rejectionReason!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.error,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final isStrong = score >= 50;
    final ringColor = isStrong ? AppColors.primary : AppColors.warning;
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 3.5,
              backgroundColor: ringColor.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: AppTextStyles.titleMd.copyWith(
                  color: ringColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
              Text(
                '%',
                style: AppTextStyles.labelSm.copyWith(
                  color: ringColor.withValues(alpha: 0.85),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
