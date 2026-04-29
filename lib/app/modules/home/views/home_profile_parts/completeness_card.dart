part of '../home_profile_tab.dart';

/// Card de completude du profil. Affiche un pourcentage + une checklist
/// des items manquants (chips actionnables qui ouvrent l'ecran d'edition
/// approprie). Premium feel : gradient sur la barre de progression,
/// icone check pour les items remplis, icone + pour ceux a completer.
///
/// Logique de scoring : 8 items ponderes (avatar=10, nom=15, headline=15,
/// summary=15, ville=10, telephone=10, skills=15, CV=10) = 100. Le CV
/// vient du `HomeProfileManager.uploadedCv` ou de `cvSections` (builder).
class _ProfileCompletenessCard extends StatelessWidget {
  const _ProfileCompletenessCard({required this.manager});

  final HomeProfileManager manager;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = manager.profile.value;
      final cv = manager.uploadedCv.value;
      final cvSections = manager.cvSections;
      final hasCv = cv.url.trim().isNotEmpty || cvSections.isNotEmpty;

      final items = <_CompletenessItem>[
        _CompletenessItem(
          label: 'Photo de profil',
          icon: IconlyBold.camera,
          weight: 10,
          done: profile.hasAvatar,
          onTap: null, // tap → l'avatar lui-meme dans le header
        ),
        _CompletenessItem(
          label: 'Nom complet',
          icon: IconlyBold.profile,
          weight: 15,
          done: profile.firstName.trim().isNotEmpty &&
              profile.lastName.trim().isNotEmpty,
          onTap: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _CompletenessItem(
          label: 'Titre du profil',
          icon: IconlyBold.bookmark,
          weight: 15,
          done: profile.headline.trim().isNotEmpty,
          onTap: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _CompletenessItem(
          label: 'A propos',
          icon: IconlyBold.paper,
          weight: 15,
          done: profile.summary.trim().length >= 30,
          onTap: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _CompletenessItem(
          label: 'Ville',
          icon: IconlyBold.location,
          weight: 10,
          done: profile.city.trim().isNotEmpty,
          onTap: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _CompletenessItem(
          label: 'Telephone',
          icon: IconlyBold.call,
          weight: 10,
          done: profile.phone.trim().length >= 6,
          onTap: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _CompletenessItem(
          label: 'Competences',
          icon: IconlyBold.activity,
          weight: 15,
          done: profile.skills.length >= 3,
          onTap: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _CompletenessItem(
          label: 'CV',
          icon: IconlyBold.document,
          weight: 10,
          done: hasCv,
          onTap: () => Get.toNamed(AppRoutes.profileCvBuilder),
        ),
      ];

      final scored =
          items.fold<int>(0, (sum, i) => sum + (i.done ? i.weight : 0));
      final total =
          items.fold<int>(0, (sum, i) => sum + i.weight);
      final pct = total == 0 ? 0 : (scored * 100 / total).round();
      final missing = items.where((i) => !i.done).toList(growable: false);

      // Pas la peine de pousser l'utilisateur quand c'est deja complet.
      if (pct >= 100) {
        return _ProfileCompleteBadge();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BrandCard(
          borderColor: AppColors.primary.withValues(alpha: 0.20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$pct%',
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil completer',
                          style: AppTextStyles.titleMd.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Un profil complet recoit ${_estimateBoost(pct)}'
                          ' de vues en plus.',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.bodyColor,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barre de progression custom (degrade primary).
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: MediaQuery.sizeOf(context).width *
                          (pct / 100) *
                          0.78, // ~ largeur dispo apres padding card
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missing
                      .map((item) => _CompletenessChip(item: item))
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// Heuristique de message marketing — purement informatif. Pas de promesse
  /// chiffree backed par la data, juste un nudge psychologique standard.
  String _estimateBoost(int pct) {
    if (pct < 40) return '3x';
    if (pct < 70) return '2x';
    return '40%';
  }
}

/// Item unitaire scoring. Le `weight` somme avec les autres pour le total
/// (actuellement 100 mais flexible si on ajoute/retire des items).
class _CompletenessItem {
  const _CompletenessItem({
    required this.label,
    required this.icon,
    required this.weight,
    required this.done,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int weight;
  final bool done;
  final VoidCallback? onTap;
}

class _CompletenessChip extends StatelessWidget {
  const _CompletenessChip({required this.item});

  final _CompletenessItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 13, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              if (item.onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Affiche quand le profil est 100% complet : juste une bande verte
/// discrete pour confirmer que tout est ok, sans encombrer la page.
class _ProfileCompleteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.successDark.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              IconlyBold.tick_square,
              color: AppColors.successStrong,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profil 100 % complet — bravo !',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.successStrong,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
