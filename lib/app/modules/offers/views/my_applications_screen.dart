import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/asset_url.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/offers_controller.dart';
import '../data/models/application_model.dart';
import '../data/models/offer_model.dart';

/// Vue "Mes candidatures" — deux onglets :
/// 1. **Postulées** : liste des candidatures envoyées (`GET /applications`)
/// 2. **Favoris**   : offres mises en favori (`GET /offers/saved/list`)
///
/// Le filtre par statut ne s'applique qu'à l'onglet Postulées (caché sinon).
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final OffersController controller = Get.find<OffersController>();
  final Rx<ApplicationStatus?> _filter = Rx<ApplicationStatus?>(null);
  late final TabController _tabController;
  final RxInt _activeTab = 0.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _activeTab.value = _tabController.index;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyApplications();
      controller.loadSavedOffers(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                Obx(
                  () => _activeTab.value == 0
                      ? WavyHeaderActionButton(
                          icon: IconlyLight.filter,
                          onTap: () {
                            AppHaptics.tap();
                            _showFilterSheet(context);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          _TabsBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AppliedTab(
                  controller: controller,
                  filter: _filter,
                  matches: _matches,
                ),
                _SavedTab(controller: controller),
              ],
            ),
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
                'applications.filter_title'.tr,
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
                      label: 'applications.filter.all'.tr,
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

/// Bandeau d'onglets segmente entre le hero et le contenu.
class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: controller,
          onTap: (_) => AppHaptics.tap(),
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.bodyColor,
          labelStyle: AppTextStyles.titleMd.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: AppTextStyles.titleMd.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'applications.tab.applied'.tr),
            Tab(text: 'applications.tab.saved'.tr),
          ],
        ),
      ),
    );
  }
}

/// Onglet "Postulées" : reprend la liste existante des candidatures.
class _AppliedTab extends StatelessWidget {
  const _AppliedTab({
    required this.controller,
    required this.filter,
    required this.matches,
  });

  final OffersController controller;
  final Rx<ApplicationStatus?> filter;
  final bool Function(ApplicationModel) matches;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoadingApplications.value;
      final error = controller.applicationsError.value;
      final raw = controller.myApplications;
      filter.value;
      final filtered = raw.where(matches).toList(growable: false);

      if (isLoading && raw.isEmpty) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
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
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: error.isNotEmpty
                    ? ErrorStateView(
                        message: error,
                        onRetry: controller.loadMyApplications,
                      )
                    : EmptyState(
                        icon: IconlyLight.work,
                        title: filter.value == null
                            ? 'applications.empty_all'.tr
                            : 'applications.empty_filtered'.tr,
                        subtitle: filter.value == null
                            ? 'applications.empty_all_sub'.tr
                            : 'applications.empty_filtered_sub'.tr,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
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
    });
  }
}

/// Onglet "Favoris" : offres sauvegardees, navigables et retirables.
class _SavedTab extends StatelessWidget {
  const _SavedTab({required this.controller});

  final OffersController controller;

  Future<void> _refresh() => controller.loadSavedOffers(refresh: true);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoadingSaved.value;
      final error = controller.savedOffersError.value;
      final list = controller.savedOffers;

      if (isLoading && list.isEmpty) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const OfferCardSkeleton(height: 140),
        );
      }

      if (list.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: error.isNotEmpty
                    ? ErrorStateView(message: error, onRetry: _refresh)
                    : EmptyState(
                        icon: IconlyLight.heart,
                        title: 'applications.saved.empty'.tr,
                        subtitle: 'applications.saved.empty_sub'.tr,
                      ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: AnimationLimiter(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final offer = list[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 280),
                child: SlideAnimation(
                  verticalOffset: 14,
                  child: FadeInAnimation(
                    child: _SavedOfferTile(
                      offer: offer,
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(
                          AppRoutes.offerDetail.replaceFirst(':id', offer.id),
                        );
                      },
                      onUnsave: () async {
                        AppHaptics.success();
                        final ok = await controller.unsaveOffer(offer.id);
                        if (ok) {
                          AppToast.info(
                            'applications.saved.removed_toast'.tr,
                          );
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

class _SavedOfferTile extends StatelessWidget {
  const _SavedOfferTile({
    required this.offer,
    required this.onTap,
    required this.onUnsave,
  });

  final OfferModel offer;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final raw = offer.companyLogo;
    final logoUrl = (raw == null || raw.isEmpty) ? '' : resolveAssetUrl(raw);

    return BrandCard(
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.18),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / placeholder.
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.20),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: logoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      IconlyBold.work,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    IconlyBold.work,
                    size: 22,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.company.isEmpty
                      ? offer.sector
                      : offer.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      IconlyLight.location,
                      size: 13,
                      color: AppColors.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        offer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.hintColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      IconlyLight.work,
                      size: 13,
                      color: AppColors.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        offer.contractType.isEmpty
                            ? '—'
                            : offer.contractType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.hintColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bouton "retirer des favoris" : cœur plein, hit area large.
          Tooltip(
            message: 'applications.saved.remove'.tr,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onUnsave,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconlyBold.heart,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

    return BrandCard(
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.18),
      onTap: hasOffer
          ? () {
              AppHaptics.tap();
              Get.toNamed(
                AppRoutes.offerDetail.replaceFirst(':id', offer!.id),
              );
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
