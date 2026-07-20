import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

/// Écran « Mon abonnement » — une VITRINE honnête : par défaut l'utilisateur est
/// sur le forfait GRATUIT. On affiche le forfait actuel et ses avantages, puis
/// une carte « Premium » mise en avant (teaser) avec un CTA « Bientôt
/// disponible » désactivé. AUCUNE facturation, AUCUN formulaire de paiement,
/// AUCUN prix inventé : si un prix apparaît, il est en FCFA et clairement
/// étiqueté « indicatif / Bientôt ».
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  // Avantages inclus dans le forfait gratuit actuel.
  static const _freeBenefits = <String>[
    'Accès aux offres et formations',
    'Candidatures de base',
    'Fil communauté & réseau',
    'Recommandations IA standard',
  ];

  // Avantages teasés par le forfait Premium (à venir).
  static const _premiumBenefits = <String>[
    'Boost de profil auprès des recruteurs',
    'Recommandations IA avancées',
    'Badge Premium sur votre profil',
    'Support prioritaire',
    'Statistiques détaillées',
  ];

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Mon abonnement',
      titleIcon: IconlyLight.star,
      body: AnimationLimiter(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH,
            AppSpacing.xl,
            AppSpacing.pageH,
            AppSpacing.xxl + 80,
          ),
          children: AnimationConfiguration.toStaggeredList(
            duration: AppMotion.medium,
            childAnimationBuilder: (w) => SlideAnimation(
              verticalOffset: AppMotion.listSlideOffset,
              curve: AppMotion.emphasizedDecelerate,
              child: FadeInAnimation(child: w),
            ),
            children: const [
              _CurrentPlanCard(benefits: _freeBenefits),
              SizedBox(height: AppSpacing.lg),
              _PremiumCard(benefits: _premiumBenefits),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte « Forfait actuel » (Gratuit)
// ─────────────────────────────────────────────────────────────────────────────
class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.benefits});
  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.squircleRadius(AppRadius.xl),
        boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : libellé du forfait + badge « Gratuit ».
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forfait actuel',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.hintColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre forfait actuel',
                      style: AppTextStyles.headlineMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Badge(
                label: 'Gratuit',
                icon: IconlyBold.tick_square,
                foreground: AppColors.successAccent,
                background: AppColors.successSoft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.lg),
          // Avantages inclus, avec icônes de validation.
          for (var i = 0; i < benefits.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _BenefitRow(
              label: benefits[i],
              color: AppColors.successAccent,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte « Premium » mise en avant (teaser, à venir)
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.benefits});
  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    return GyroTilt(
      // Inclinaison 3D discrète : la carte « se regarde sous un angle ».
      maxTilt: 0.05,
      child: SheenSweep(
        // Reflet spéculaire lent : la carte Premium « capte la lumière » (verre).
        borderRadius: AppShapes.squircleRadius(AppRadius.xl),
        intensity: 0.16,
        period: const Duration(milliseconds: 3600),
        pause: const Duration(milliseconds: 3400),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            // Voile « marque » subtil + bordure teintée primaire pour distinguer
            // visuellement l'offre Premium sans surcharge.
            gradient: AppColors.meshBrand,
            borderRadius: AppShapes.squircleRadius(AppRadius.xl),
            boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : titre Premium + badge « Premium ».
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                    ),
                    child: Icon(
                      IconlyBold.star,
                      size: 22,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Passez à la vitesse supérieure',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Badge(
                    label: 'Premium',
                    icon: IconlyBold.star,
                    foreground: AppColors.primaryAccent,
                    background: AppColors.surfaceCard,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Avantages Premium, avec icônes teintées marque.
              for (var i = 0; i < benefits.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _BenefitRow(
                  label: benefits[i],
                  color: AppColors.primaryAccent,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Tarif indicatif, clairement étiqueté « Bientôt » en FCFA.
              Row(
                children: [
                  Icon(
                    IconlyLight.info_circle,
                    size: 14,
                    color: AppColors.hintColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tarif indicatif à venir, en FCFA. Bientôt.',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ComingSoonButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// CTA pleine largeur visuellement « bouton » mais désactivé (état « bientôt »).
/// `onPressed: null` côté gesture — on signale clairement l'indisponibilité.
class _ComingSoonButton extends StatelessWidget {
  const _ComingSoonButton();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // Atténuation pour communiquer l'état non-cliquable (coming soon).
      opacity: 0.75,
      child: PressScale(
        enabled: false,
        // Désactivé : pas de tap (onPressed: null). Quand l'offre sera active,
        // on branchera AppHaptics.tap() + la navigation paiement ici.
        onTap: null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: AppShapes.squircleRadius(AppRadius.md),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconlyLight.time_circle,
                size: 18,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Bientôt disponible',
                style: AppTextStyles.buttonLg.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Briques partagées
// ─────────────────────────────────────────────────────────────────────────────

/// Ligne d'avantage : icône de validation + libellé.
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(IconlyBold.tick_square, size: 20, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.titleColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge capsule (pill) : icône + libellé sur fond teinté.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppShapes.pill,
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
