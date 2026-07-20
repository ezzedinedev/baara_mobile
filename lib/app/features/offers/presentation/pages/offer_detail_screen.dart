import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import '../controllers/offer_detail_controller.dart';
import '../widgets/offer_boost_badge.dart';
import '../../domain/entities/offer.dart';

class OfferDetailScreen extends GetView<OfferDetailController> {
  const OfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const _OfferDetailSkeleton();
        }

        final offer = controller.offer.value;
        if (offer == null) {
          return ErrorStateView(
            message: controller.errorMessage.value ?? 'Erreur inconnue',
            illustration: const ErrorIllustration(),
            onRetry: () async => controller.onInit(),
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              // Permet l'étirement du hero en overscroll (zoom élastique).
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(offer),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
                    // Chorégraphie : les sections montent en cascade
                    // (emphasizedDecelerate via RevealOnMount), une fois le hero
                    // posé. Délais échelonnés pour une entrée vivante mais calme.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RevealOnMount(
                          offsetY: 16,
                          child: _buildMainInfo(offer),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        RevealOnMount(
                          delay: AppMotion.stagger,
                          offsetY: 16,
                          child: _buildKeyInfoGrid(offer),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        RevealOnMount(
                          delay: AppMotion.stagger * 2,
                          offsetY: 16,
                          child: _buildAiOfferActions(offer),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        RevealOnMount(
                          delay: AppMotion.stagger * 3,
                          offsetY: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                  'À propos de l\'offre', IconlyLight.document),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                offer.description,
                                style: AppTextStyles.bodyMd.copyWith(
                                    height: 1.7, color: AppColors.bodyColor),
                              ),
                            ],
                          ),
                        ),
                        if (offer.requiredSkills.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          RevealOnMount(
                            delay: AppMotion.stagger * 4,
                            offsetY: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Compétences requises',
                                    IconlyLight.activity),
                                const SizedBox(height: AppSpacing.lg),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: offer.requiredSkills
                                      .map((s) => _SkillChip(label: s))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Espace pour dégager la CTA sticky.
                        const SizedBox(height: 130),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomAction(),
          ],
        );
      }),
    );
  }

  Widget _buildSliverAppBar(Offer offer) {
    return SliverAppBar(
      expandedHeight: 224,
      pinned: true,
      // Étirement du hero au pull-down + zoom de l'arrière-plan (parallax 2026).
      stretch: true,
      stretchTriggerOffset: 120,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: AppBackButton(onDark: true, onTap: () => Get.back<void>()),
      ),
      leadingWidth: 60,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Obx(
            () => IconButton(
              icon: Icon(
                controller.isSaved.value
                    ? IconlyBold.bookmark
                    : IconlyLight.bookmark,
                color: AppColors.onPrimary,
              ),
              tooltip: controller.isSaved.value
                  ? 'Retirer des favoris'
                  : 'Enregistrer',
              onPressed: () {
                AppHaptics.tap();
                controller.toggleSave();
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // Parallax du hero au scroll + zoom de l'arrière-plan au pull-down.
        collapseMode: CollapseMode.parallax,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Container(
          decoration: BoxDecoration(gradient: AppColors.heroOffersGradient),
          // Halo mesh de marque par-dessus le dégradé (profondeur hero 2026).
          foregroundDecoration:
              BoxDecoration(gradient: AppColors.meshBrandGlow),
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
              // Logo flou en filigrane (profondeur immersive) si dispo.
              if ((offer.companyLogo ?? '').isNotEmpty)
                Positioned(
                  right: -30,
                  top: -10,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Opacity(
                      opacity: 0.35,
                      child: BrandAvatar(
                        seed: offer.company,
                        label: offer.company,
                        size: 200,
                        imageUrl: offer.companyLogo,
                      ),
                    ),
                  ),
                ),
              // Voile pour la lisibilité.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.onDark.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xxl,
                right: AppSpacing.xxl,
                bottom: AppSpacing.xl,
                // Bandeau d'infos entreprise en verre liquide (chrome hero).
                child: GlassSurface(
                  borderRadius: AppShapes.squircleRadius(AppRadius.md),
                  blurSigma: 14,
                  tintAlpha: 0.18,
                  color: AppColors.onDark,
                  borderColor: AppColors.onPrimary.withValues(alpha: 0.22),
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'offer-logo-${offer.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                AppShapes.squircleRadius(AppRadius.md),
                            border: Border.all(
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.30),
                              width: 2,
                            ),
                            boxShadow: AppColors.ambientShadow,
                          ),
                          child: ClipRRect(
                            borderRadius:
                                AppShapes.squircleRadius(AppRadius.md),
                            child: BrandAvatar(
                              seed: offer.company,
                              label: offer.company,
                              size: 64,
                              imageUrl: offer.companyLogo,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              offer.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLg.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (offer.sector.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                offer.sector.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onPrimary
                                      .withValues(alpha: 0.85),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(Offer offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offer.isBoosted && offer.boostTier > 0) ...[
          OfferBoostBadge(
            tier: offer.boostTier,
            label: offer.boostLabel ?? 'À la une',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          offer.title,
          style: AppTextStyles.displayHero.copyWith(fontSize: 28),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            // Compatibilité IA : c'est sur cette page que le candidat décide de
            // postuler, il lui faut donc le chiffre ici. `null` = score inconnu
            // (pas encore de CV) → on n'affiche rien plutôt qu'un faux 0 %.
            if (offer.matchScore != null)
              MatchScorePill(score: offer.matchScore!),
            _InfoPill(icon: IconlyLight.location, label: offer.location),
            if (offer.contractType.isNotEmpty)
              _InfoPill(icon: IconlyLight.work, label: offer.contractType),
            if (offer.isRemote)
              _InfoPill(icon: IconlyLight.location, label: 'Télétravail'),
          ],
        ),
      ],
    );
  }

  /// Grille d'infos clés (salaire / expérience / échéance) en cartes douces.
  Widget _buildKeyInfoGrid(Offer offer) {
    final tiles = <Widget>[
      if (offer.salary.isNotEmpty)
        _KeyInfoTile(
          icon: IconlyLight.wallet,
          label: 'Rémunération',
          value: offer.salary,
        ),
      if ((offer.experienceLabel ?? '').isNotEmpty)
        _KeyInfoTile(
          icon: IconlyLight.chart,
          label: 'Expérience',
          value: offer.experienceLabel!,
        ),
      if ((offer.deadlineLabel ?? '').isNotEmpty)
        _KeyInfoTile(
          icon: IconlyLight.calendar,
          label: 'Échéance',
          value: offer.deadlineLabel!,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _buildAiOfferActions(Offer offer) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.primaryAccent.withValues(alpha: 0.18),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.12),
                  shape: AppShapes.squircle(AppRadius.xs),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Assistant candidature',
                  style: AppTextStyles.titleLg.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Obx(
                () => controller.isAiActionLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AiActionChip(
                icon: IconlyLight.document,
                label: 'Adapter CV',
                onTap: () async {
                  final data = await controller.adaptCv();
                  if (data != null) _showAiResult('CV adapté', data);
                },
              ),
              _AiActionChip(
                icon: IconlyLight.paper,
                label: 'Lettre IA',
                onTap: () async {
                  final letter = await controller.generateCoverLetter();
                  if (letter != null) {
                    _showTextResult('Lettre de motivation', letter.fullText);
                  }
                },
              ),
              _AiActionChip(
                icon: IconlyLight.send,
                label: 'Adapter + postuler',
                onTap: controller.adaptCvAndApply,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTextResult(String title, String text) {
    _showResultSheet(
      title: title,
      child: SelectableText(
        text.trim().isEmpty ? 'Aucun contenu renvoyé.' : text.trim(),
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.bodyColor,
          height: 1.5,
        ),
      ),
    );
  }

  void _showAiResult(String title, Map<String, dynamic> data) {
    // Le CV adapté est une réponse STRUCTURÉE (match_score, suggestions.bio,
    // .objective, .experiences, gaps). L'aplatir en « clé: valeur » affichait
    // les sous-objets via leur .toString() Dart → le dump « {bio: {current:
    // null, suggested: …}} ». On rend chaque section proprement.
    _showResultSheet(title: title, child: _CvAdaptView(data: data));
  }

  void _showResultSheet({required String title, required Widget child}) {
    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Text(
                title,
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.12),
            shape: AppShapes.squircle(AppRadius.xs),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryAccent),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 0),
        decoration: BoxDecoration(
          // Fondu pour que le contenu disparaisse en douceur sous la CTA.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.0),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            // CTA posée sur un panneau de verre liquide (chrome sticky 2026)
            // au lieu d'un simple fondu : profondeur + lisibilité au scroll.
            child: GlassSurface(
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
              blurSigma: 18,
              boxShadow: AppColors.ambientShadow,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Obx(() {
                final applied = controller.hasApplied.value;
                return AuthCtaButton(
                  label:
                      applied ? 'CANDIDATURE ENVOYÉE' : 'POSTULER MAINTENANT',
                  isLoading: controller.isApplying.value,
                  trailing: applied
                      ? IconlyBold.tick_square
                      : IconlyLight.arrow_right_2,
                  onPressed: applied
                      ? null
                      : () => _applyWithOptionalScreening(
                            controller.offer.value,
                          ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _applyWithOptionalScreening(Offer? offer) {
    if (offer == null) return;
    if (!offer.hasScreeningQuestions) {
      controller.apply();
      return;
    }
    final formKey = GlobalKey<FormState>();
    final answers = <String, dynamic>{};
    final textControllers = <String, TextEditingController>{
      for (final q in offer.screeningQuestions)
        if (q.options.isEmpty) q.id: TextEditingController(),
    };

    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 12),
                  Text(
                    'Questions de présélection',
                    style: AppTextStyles.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Répondez aux questions demandées par le recruteur avant de postuler.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final question in offer.screeningQuestions) ...[
                    if (question.options.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: question.label,
                          border: OutlineInputBorder(
                            borderRadius:
                                AppShapes.squircleRadius(AppRadius.md),
                          ),
                        ),
                        items: question.options
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                            .toList(),
                        validator: (value) => question.required &&
                                (value == null || value.trim().isEmpty)
                            ? 'Réponse requise'
                            : null,
                        onChanged: (value) => answers[question.id] = value,
                      )
                    else
                      TextFormField(
                        controller: textControllers[question.id],
                        minLines: question.type == 'textarea' ? 3 : 1,
                        maxLines: question.type == 'textarea' ? 5 : 1,
                        decoration: InputDecoration(
                          labelText: question.label,
                          border: OutlineInputBorder(
                            borderRadius:
                                AppShapes.squircleRadius(AppRadius.md),
                          ),
                        ),
                        validator: (value) => question.required &&
                                (value == null || value.trim().isEmpty)
                            ? 'Réponse requise'
                            : null,
                      ),
                    const SizedBox(height: 14),
                  ],
                  AuthCtaButton(
                    label: 'Envoyer ma candidature',
                    trailing: IconlyLight.send,
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      for (final entry in textControllers.entries) {
                        final value = entry.value.text.trim();
                        if (value.isNotEmpty) answers[entry.key] = value;
                      }
                      Get.back<void>();
                      controller.apply(screeningAnswers: answers);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(() {
      for (final c in textControllers.values) {
        c.dispose();
      }
    });
  }
}

/// Carte d'info clé compacte pour la grille de la fiche offre.
class _KeyInfoTile extends StatelessWidget {
  const _KeyInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryAccent),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.hintColor),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiActionChip extends StatelessWidget {
  const _AiActionChip({
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
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          color: AppColors.primaryAccent.withValues(alpha: 0.10),
          shape: AppShapes.squircle(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconlyLight.tick_square,
              size: 14, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de chargement de la fiche offre : hero + titre + chips + paragraphe.
class _OfferDetailSkeleton extends StatelessWidget {
  const _OfferDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        SkeletonBox(height: 240, radius: 0),
        Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 220, height: 26, radius: 8),
              SizedBox(height: 12),
              SkeletonBox(width: 150, height: 16, radius: 8),
              SizedBox(height: 24),
              Row(
                children: [
                  SkeletonBox(width: 90, height: 30, radius: 999),
                  SizedBox(width: 10),
                  SkeletonBox(width: 70, height: 30, radius: 999),
                  SizedBox(width: 10),
                  SkeletonBox(width: 80, height: 30, radius: 999),
                ],
              ),
              SizedBox(height: 28),
              SkeletonBox(height: 14, radius: 8),
              SizedBox(height: 10),
              SkeletonBox(height: 14, radius: 8),
              SizedBox(height: 10),
              SkeletonBox(width: 240, height: 14, radius: 8),
              SizedBox(height: 28),
              SkeletonBox(height: 54, radius: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rendu structuré du résultat « CV adapté » renvoyé par POST /ai/cv/adapt.
///
/// Forme : { match_score:int, match_summary:String, suggestions:{ bio, objective,
/// hard_skills_reorder:[String], experiences:[{suggested_description, reason}] },
/// gaps:[String] }. On ne montre que ce qui est exploitable (suggestion non vide).
class _CvAdaptView extends StatelessWidget {
  const _CvAdaptView({required this.data});

  final Map<String, dynamic> data;

  static String? _str(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty || s == 'null' ? null : s;
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<String> _strings(dynamic v) => (v is List ? v : const [])
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty && e != 'null')
      .toList();

  @override
  Widget build(BuildContext context) {
    final score = (data['match_score'] as num?)?.round();
    final summary = _str(data['match_summary']);
    final sug = _map(data['suggestions']);
    final bio = _map(sug['bio']);
    final objective = _map(sug['objective']);
    final skills = _strings(sug['hard_skills_reorder']);
    final experiences =
        (sug['experiences'] is List ? sug['experiences'] as List : const [])
            .map(_map)
            .toList();
    final gaps = _strings(data['gaps']);

    final blocks = <Widget>[
      _AdaptScoreHeader(score: score, summary: summary),
    ];

    final bioSug = _str(bio['suggested']);
    if (bioSug != null) {
      blocks.add(_AdaptSuggestion(
        label: 'Bio adaptée',
        suggested: bioSug,
        reason: _str(bio['reason']),
      ));
    }

    final objSug = _str(objective['suggested']);
    if (objSug != null) {
      blocks.add(_AdaptSuggestion(
        label: 'Objectif adapté',
        suggested: objSug,
        reason: _str(objective['reason']),
      ));
    }

    if (skills.isNotEmpty) {
      blocks.add(_AdaptSkills(skills: skills));
    }

    var expShown = 0;
    for (final exp in experiences) {
      final desc = _str(exp['suggested_description']);
      if (desc == null) continue;
      expShown++;
      blocks.add(_AdaptSuggestion(
        label: 'Expérience $expShown',
        suggested: desc,
        reason: _str(exp['reason']),
      ));
    }

    if (gaps.isNotEmpty) {
      blocks.add(_AdaptGaps(gaps: gaps));
    }

    // Seul le score : rien à suggérer, on le dit clairement plutôt que du vide.
    if (blocks.length == 1) {
      blocks.add(Text(
        'Aucune modification suggérée : votre CV est déjà bien aligné sur cette offre.',
        style: AppTextStyles.bodyMd
            .copyWith(color: AppColors.bodyColor, height: 1.5),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          blocks[i],
        ],
      ],
    );
  }
}

class _AdaptScoreHeader extends StatelessWidget {
  const _AdaptScoreHeader({required this.score, required this.summary});

  final int? score;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$score % de correspondance',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (summary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary!,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.bodyColor, height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _AdaptSuggestion extends StatelessWidget {
  const _AdaptSuggestion({
    required this.label,
    required this.suggested,
    this.reason,
  });

  final String label;
  final String suggested;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            suggested,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.titleColor, height: 1.5),
          ),
          if (reason != null) ...[
            const SizedBox(height: 6),
            Text(
              reason!,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdaptSkills extends StatelessWidget {
  const _AdaptSkills({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compétences à mettre en avant',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final skill in skills)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSelected,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  skill,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.primaryAccent),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AdaptGaps extends StatelessWidget {
  const _AdaptGaps({required this.gaps});

  final List<String> gaps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À renforcer pour cette offre',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final gap in gaps)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyLight.arrow_right_2,
                    size: 16, color: AppColors.warningAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    gap,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.bodyColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
