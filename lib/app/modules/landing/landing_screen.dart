import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/opportune_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -110,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _LandingHeader(),
                        const SizedBox(height: 24),
                        const _TrustPill(),
                        const SizedBox(height: 16),
                        Text(
                          'Decrochez un emploi',
                          style: AppTextStyles.displayLg.copyWith(
                            fontSize: 48,
                            height: 0.98,
                            color: AppColors.titleColor,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return AppColors.landingHeroGradient
                                .createShader(bounds);
                          },
                          child: Text(
                            'qui vous ressemble',
                            style: AppTextStyles.displayLg.copyWith(
                              fontSize: 48,
                              height: 0.98,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'La plateforme de recrutement pour candidats, '
                          'etudiants et entreprises au Burkina Faso.',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Offres verifiees, orientation, et accompagnement.',
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _KpiRow(),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'COMMENCER MAINTENANT',
                          onPressed: () =>
                              Get.toNamed(AppRoutes.profileSelection),
                          textColor: AppColors.onPrimary,
                          gradient: AppColors.landingCtaGradient,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.candidateLogin),
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 18,
                                    color: AppColors.titleColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Explorer les profils',
                                    style: AppTextStyles.titleMd.copyWith(
                                      color: AppColors.titleColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _SocialProof(),
                        const SizedBox(height: 18),
                        const _RecruitmentMockup(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 410;

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.end,
          children: [
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.candidateLogin),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Connexion',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: isCompact ? 104 : 112,
              height: 38,
              child: GradientButton(
                label: 'S\'INSCRIRE',
                onPressed: () => Get.toNamed(AppRoutes.registerProfile),
                borderRadius: 12,
                gradient: AppColors.landingCtaGradient,
                textColor: AppColors.onPrimary,
                fontSize: 11,
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OpportuneLogo(iconSize: 16, fontSize: 18),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: actions,
              ),
            ],
          );
        }

        return Row(
          children: [
            const OpportuneLogo(iconSize: 16, fontSize: 18),
            const Spacer(),
            actions,
          ],
        );
      },
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '10 247 talents actifs nous font confiance',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.work_outline_rounded,
            value: '5 200+',
            label: 'Offres',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.domain_rounded,
            value: '320+',
            label: 'Entreprises',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.schedule_rounded,
            value: '24 h',
            label: 'Reponse',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(
              fontSize: 18,
              color: AppColors.titleColor,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 11,
              color: AppColors.bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProof extends StatelessWidget {
  const _SocialProof();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 124,
          height: 32,
          child: Stack(
            children: List.generate(5, (index) {
              final color = switch (index) {
                0 => AppColors.primary,
                1 => AppColors.primaryMedium,
                2 => AppColors.primaryLight,
                3 => AppColors.primaryMedium,
                _ => AppColors.primary,
              };
              return Positioned(
                left: index * 21,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: AppColors.surfaceCard,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: AppColors.onPrimary,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                ),
              ),
              Text(
                'Note 4.9/5 par 10 000+ utilisateurs',
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 11,
                  color: AppColors.bodyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecruitmentMockup extends StatelessWidget {
  const _RecruitmentMockup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -92,
            top: 220,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 250,
                height: 108,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            right: -118,
            top: 250,
            child: Transform.rotate(
              angle: 0.14,
              child: Container(
                width: 285,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.recruiterGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 258,
              height: 390,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: AppColors.primaryDark,
                  width: 4,
                ),
                boxShadow: AppColors.ambientShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 72,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppColors.primaryLight.withValues(alpha: 0.35),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 15,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style:
                                  AppTextStyles.bodySm.copyWith(fontSize: 11),
                            ),
                            Text(
                              'Fatou K.',
                              style: AppTextStyles.titleMd.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.landingHeroGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offres correspondant a votre profil',
                            style: AppTextStyles.bodySm.copyWith(
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.82),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '126 offres',
                            style: AppTextStyles.headlineMd.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _PipelineRow(
                      icon: Icons.person_search_rounded,
                      label: 'Nouveaux profils',
                      value: '+42',
                    ),
                    const SizedBox(height: 8),
                    const _PipelineRow(
                      icon: Icons.event_available_rounded,
                      label: 'Entretiens planifies',
                      value: '8',
                    ),
                    const SizedBox(height: 8),
                    const _PipelineRow(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Candidats qualifies',
                      value: 'Top 18',
                    ),
                    const Spacer(),
                    Center(
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.hintColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 36,
            child: Container(
              width: 122,
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
                boxShadow: AppColors.lightShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insertion',
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 10,
                      color: AppColors.bodyColor,
                    ),
                  ),
                  Text(
                    '+31%',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withValues(alpha: 0.25),
            ),
            child: Icon(
              icon,
              size: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
