import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/trainings_controller.dart';
import '../models/training_model.dart';

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key});

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  final TrainingsController controller = Get.find<TrainingsController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(TrainingModel training) {
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return training.title.toLowerCase().contains(q) ||
        training.providerName.toLowerCase().contains(q) ||
        training.level.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      body: Column(
        children: [
          RevealOnMount(
            duration: const Duration(milliseconds: 540),
            offsetY: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                WavyContentHeader(
                  title: 'trainings.title'.tr,
                  subtitle: 'trainings.subtitle'.tr,
                  gradient: AppColors.heroTrainingsGradient,
                  actions: [
                    WavyHeaderActionButton(
                      icon: IconlyLight.filter,
                      onTap: () {
                        AppHaptics.tap();
                      },
                    ),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -28,
                  child: AppSearchBar(
                    controller: _searchController,
                    hint: 'Rechercher une formation, organisme...',
                    onChanged: (v) => _query.value = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Obx(() {
        final isLoading = controller.isLoading.value;
        _query.value;
        final trainings =
            controller.trainings.where(_matchesQuery).toList(growable: false);
        final errorMessage = controller.errorMessage.value;

        if (isLoading && trainings.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const TrainingCardSkeleton(),
          );
        }

        if (trainings.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadTrainings(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: errorMessage.isNotEmpty
                      ? ErrorStateView(
                          message: errorMessage,
                          onRetry: () =>
                              controller.loadTrainings(refresh: true),
                        )
                      : EmptyState(
                          icon: IconlyLight.paper,
                          title: 'Aucune formation disponible',
                          subtitle:
                              'De nouvelles formations seront publiées prochainement.',
                          actionLabel: 'Actualiser',
                          onAction: () {
                            AppHaptics.tap();
                            controller.loadTrainings(refresh: true);
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => controller.loadTrainings(refresh: true),
          child: AnimationLimiter(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notif) {
                if (notif.metrics.pixels >=
                        notif.metrics.maxScrollExtent * 0.8 &&
                    !controller.isLoadingMore.value &&
                    controller.hasNextPage.value) {
                  controller.loadMoreTrainings();
                }
                return false;
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: trainings.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == trainings.length) {
                    return Obx(
                      () => controller.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }

                  final training = trainings[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 320),
                    child: SlideAnimation(
                      verticalOffset: 18,
                      child: FadeInAnimation(
                        child: _TrainingCard(
                          training: training,
                          onTap: () {
                            AppHaptics.tap();
                            // TODO: naviguer vers le détail
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
            }),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatefulWidget {
  const _TrainingCard({required this.training, required this.onTap});

  final TrainingModel training;
  final VoidCallback onTap;

  @override
  State<_TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<_TrainingCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get _isFree =>
      widget.training.price == null || widget.training.price == 0;

  bool get _isOpen {
    final s = widget.training.status.toLowerCase();
    return s.contains('ouvert') ||
        s.contains('open') ||
        s.contains('actif') ||
        s.contains('active') ||
        s.contains('publi');
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.training;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.categoryPurple.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) HERO — image 180 + voile + badges glass.
              SizedBox(
                width: double.infinity,
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image / fallback gradient.
                    if (training.coverUrl.isEmpty)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.categoryPurple,
                              AppColors.categoryPurpleDeep,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            IconlyBold.paper,
                            color: AppColors.onPrimary,
                            size: 56,
                          ),
                        ),
                      )
                    else
                      KenBurnsImage(
                        image: NetworkImage(training.coverUrl),
                      ),
                    // Voile concentre dans le bas (stops 0.55+) — preserve
                    // la vivacite de l'image dans la moitie haute.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppColors.imageScrim,
                          stops: AppColors.imageScrimStops,
                        ),
                      ),
                    ),
                    // Status (top-left) + Rating (top-right).
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusBadge(
                        text: training.status.isEmpty
                            ? 'Disponible'
                            : training.status,
                        isOpen: _isOpen,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _GlassChip(
                        icon: IconlyBold.star,
                        iconColor: AppColors.warning,
                        text: training.rating.toStringAsFixed(1),
                      ),
                    ),
                    // Niveau + Format (bottom-left, glass).
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (training.level.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _GlassChip(
                                icon: IconlyLight.chart,
                                text: training.level,
                              ),
                            ),
                          if (training.format.isNotEmpty)
                            _GlassChip(
                              icon: IconlyLight.video,
                              text: training.format,
                            ),
                          const Spacer(),
                          if (training.isBookmarked)
                            const _GlassChip(
                              icon: IconlyBold.bookmark,
                              text: 'Sauve',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 2) BODY — provider + titre + description + stats + prix.
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider row.
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.categoryPurple,
                                AppColors.categoryPurpleDeep,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: training.providerLogo != null &&
                                  training.providerLogo!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    training.providerLogo!,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      _initials(training.providerName),
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  _initials(training.providerName),
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            training.providerName.isEmpty
                                ? 'Organisme'
                                : training.providerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (training.sector.isNotEmpty) ...[
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.hintColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              training.sector,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.categoryPurple,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Titre.
                    Text(
                      training.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (training.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        training.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Stats row.
                    Row(
                      children: [
                        _StatItem(
                          icon: IconlyLight.paper,
                          color: AppColors.categoryBlue,
                          value: '${training.lessons}',
                          label: 'modules',
                        ),
                        const SizedBox(width: 14),
                        if (training.durationLabel.isNotEmpty &&
                            training.durationLabel != 'Duree non precisee')
                          _StatItem(
                            icon: IconlyLight.time_circle,
                            color: AppColors.categoryCyan,
                            value: training.durationLabel,
                            label: '',
                            valueIsLabel: true,
                          ),
                        const SizedBox(width: 14),
                        _StatItem(
                          icon: IconlyLight.profile,
                          color: AppColors.categoryOrange,
                          value: '${training.enrolledCount}',
                          label: 'inscrits',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Prix bandeau bas — gradient si gratuit, accent si payant.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(
                        gradient: _isFree
                            ? LinearGradient(
                                colors: [
                                  AppColors.successSoft,
                                  AppColors.successSoft,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  AppColors.categoryOrange
                                      .withValues(alpha: 0.16),
                                  AppColors.categoryOrange
                                      .withValues(alpha: 0.10),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFree
                              ? AppColors.successDark.withValues(alpha: 0.22)
                              : AppColors.categoryOrange
                                  .withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isFree
                                ? IconlyBold.shield_done
                                : IconlyBold.wallet,
                            size: 16,
                            color: _isFree
                                ? AppColors.successStrong
                                : AppColors.categoryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              training.priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMd.copyWith(
                                color: _isFree
                                    ? AppColors.successStrong
                                    : AppColors.categoryOrange,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (training.certificationLabel.isNotEmpty &&
                              !training.certificationLabel
                                  .toLowerCase()
                                  .contains('non')) ...[
                            const Icon(
                              IconlyLight.shield_done,
                              size: 14,
                              color: AppColors.successDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Certifie',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.successDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? AppColors.onPrimary),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.isOpen});
  final String text;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.successStrong : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.valueIsLabel = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool valueIsLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        if (valueIsLabel)
          Text(
            value,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          )
        else ...[
          Text(
            value,
            style: AppTextStyles.titleMd.copyWith(
              color: AppColors.titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.bodyColor,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

