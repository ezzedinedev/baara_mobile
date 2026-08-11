import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

import '../../domain/entities/enrolled_training.dart';
import '../controllers/trainings_controller.dart';
import '../widgets/training_card.dart';

/// Liste des formations — UX d'origine restaurée : header en vague
/// ([WavyContentHeader]) sur le gradient formations, barre de recherche locale
/// (titre / organisme / niveau), apparition animée des cartes, pull-to-refresh
/// et bouton "remonter en haut". Les items réutilisent la carte partagée
/// [TrainingCard]. États : skeletons au chargement, vide et erreur.
class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key, this.embedded = false});

  /// Quand `true`, rend seulement le corps (recherche + liste) sans l'en-tête
  /// SankTabShell — pour être hébergé dans le hub Opportunités.
  final bool embedded;

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  final TrainingsController controller = Get.find<TrainingsController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _searchBar() => AppSearchBar(
        controller: _searchController,
        hint: 'Rechercher une formation, organisme...',
        onChanged: (v) => controller.searchQuery.value = v,
      );

  @override
  Widget build(BuildContext context) {
    final body = _list(context);
    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _searchBar(),
          ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      body: SankTabShell(
        title: 'Formations',
        subtitle: 'Parcours pour renforcer votre employabilité.',
        headerActions: [
          AppIconButton(
            icon: AppIcons.filter,
            onTap: () {
              AppHaptics.tap();
              openTrainingsFilter(context, controller);
            },
          ),
        ],
        headerChild: _searchBar(),
        body: body,
      ),
    );
  }

  Widget _list(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final trainings = controller.filteredTrainings;
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
        return AppRefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: () => controller.loadTrainings(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: (errorMessage != null && errorMessage.isNotEmpty)
                    ? ErrorStateView(
                        message: errorMessage,
                        illustration: const ErrorIllustration(),
                        onRetry: () => controller.loadTrainings(refresh: true),
                      )
                    : EmptyState(
                        illustration: const EmptyTrainingsIllustration(),
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

      // « Mes formations » en tête de liste : un parcours commencé doit se
      // retrouver immédiatement, sans refouiller le catalogue.
      final resumable = controller.inProgress;
      final headerCount = resumable.isEmpty ? 0 : 1;

      return AppRefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: controller.refreshAll,
        child: AnimationLimiter(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notif) {
              if (notif.metrics.pixels >= notif.metrics.maxScrollExtent * 0.8 &&
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
              itemCount: headerCount + trainings.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, rawIndex) {
                if (headerCount == 1 && rawIndex == 0) {
                  return _MyTrainingsSection(items: resumable);
                }
                final index = rawIndex - headerCount;

                if (index == trainings.length) {
                  return Obx(
                    () => controller.isLoadingMore.value
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: const AppLoader(strokeWidth: 2),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  );
                }

                final training = trainings[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    curve: AppMotion.emphasizedDecelerate,
                    verticalOffset: AppMotion.listSlideOffset,
                    child: FadeInAnimation(
                      child: TrainingCard(
                        training: training,
                        onTap: () {
                          AppHaptics.tap();
                          Get.toNamed(
                            AppRoutes.trainingDetail
                                .replaceFirst(':id', training.id),
                          );
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
    });
  }
}

/// Ouvre le sheet de filtres des formations (format / niveau / tarif), construit
/// à partir des valeurs réellement présentes, et applique au controller.
/// Partagé par l'écran Formations et le hub Opportunités.
Future<void> openTrainingsFilter(
    BuildContext context, TrainingsController controller) async {
  final formats = controller.trainings
      .map((t) => t.format)
      .where((f) => f.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final levels = controller.trainings
      .map((t) => t.level)
      .where((l) => l.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final groups = <FilterGroup>[
    if (formats.isNotEmpty)
      FilterGroup(key: 'format', label: 'Format', options: formats),
    if (levels.isNotEmpty)
      FilterGroup(key: 'level', label: 'Niveau', options: levels),
    const FilterGroup(key: 'price', label: 'Tarif', options: ['Gratuites']),
  ];
  final result = await showFilterSheet(
    context: context,
    groups: groups,
    selected: {
      'format': controller.activeFormat.value,
      'level': controller.activeLevel.value,
      'price': controller.freeOnly.value ? 'Gratuites' : null,
    },
  );
  if (result != null) {
    controller.activeFormat.value = result['format'];
    controller.activeLevel.value = result['level'];
    controller.freeOnly.value = result['price'] == 'Gratuites';
  }
}

/// « Mes formations » : les parcours commencés, avec la progression réelle.
///
/// Ces inscriptions existaient déjà côté API et repository, mais n'étaient
/// affichées nulle part : une fois inscrit, l'apprenant perdait son parcours de
/// vue et devait le retrouver dans le catalogue.
class _MyTrainingsSection extends StatelessWidget {
  const _MyTrainingsSection({required this.items});

  final List<EnrolledTraining> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mes formations'),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _EnrolledCard(item: items[index]),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Catalogue'),
      ],
    );
  }
}

class _EnrolledCard extends StatelessWidget {
  const _EnrolledCard({required this.item});

  final EnrolledTraining item;

  @override
  Widget build(BuildContext context) {
    final pct = item.progressPct.clamp(0, 100);

    return PressScale(
      curve: AppMotion.spring,
      onTap: () {
        AppHaptics.tap();
        // Directement dans le parcours : l'apprenant est déjà inscrit, le
        // renvoyer sur la fiche de vente n'aurait aucun sens.
        Get.toNamed<void>(
          AppRoutes.trainingPlayer.replaceFirst(':id', item.training.id),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: AppColors.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.training.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.titleColor,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.training.providerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.hintColor),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  item.isCompleted ? 'Terminée' : '$pct % complété',
                  style: AppTextStyles.labelSm.copyWith(
                    color: item.isCompleted
                        ? AppColors.successAccent
                        : AppColors.primaryAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  item.isCompleted
                      ? AppIcons.tickSquare
                      : AppIcons.play,
                  size: 16,
                  color: item.isCompleted
                      ? AppColors.successAccent
                      : AppColors.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 5,
                backgroundColor: AppColors.surfaceHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.isCompleted
                      ? AppColors.successAccent
                      : AppColors.primaryAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
