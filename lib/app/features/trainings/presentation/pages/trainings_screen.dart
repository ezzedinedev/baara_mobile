import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import '../../domain/entities/training.dart';
import '../controllers/trainings_controller.dart';
import '../widgets/training_card.dart';

/// Liste des formations — UX d'origine restaurée : header en vague
/// ([WavyContentHeader]) sur le gradient formations, barre de recherche locale
/// (titre / organisme / niveau), apparition animée des cartes, pull-to-refresh
/// et bouton "remonter en haut". Les items réutilisent la carte partagée
/// [TrainingCard]. États : skeletons au chargement, vide et erreur.
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

  bool _matchesQuery(Training training) {
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
      body: SankTabShell(
        title: 'Formations',
        subtitle: 'Parcours pour renforcer votre employabilité.',
        headerActions: [
          AppIconButton(
            icon: IconlyLight.filter,
            onTap: () => AppHaptics.tap(),
          ),
        ],
        headerChild: AppSearchBar(
          controller: _searchController,
          hint: 'Rechercher une formation, organisme...',
          onChanged: (v) => _query.value = v,
        ),
        body: Obx(() {
              final isLoading = controller.isLoading.value;
              _query.value; // dépendance réactive pour le filtre local.
              final trainings = controller.trainings
                  .where(_matchesQuery)
                  .toList(growable: false);
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
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: (errorMessage != null && errorMessage.isNotEmpty)
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
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
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
            }),
      ),
    );
  }
}
