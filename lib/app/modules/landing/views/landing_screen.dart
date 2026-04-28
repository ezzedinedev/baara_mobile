import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';

/// Landing page : bienvenue + CTA unique "Commencer" + lien "Se connecter".
///
/// Design mobile-first inspiré d'une landing app moderne : hero en dégradé
/// primaire texturé occupant ~55% de la hauteur, séparé par une vague ;
/// contenu (titre + sous-titre + CTAs) dans la carte blanche du bas.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.55).clamp(360.0, 520.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(
            height: heroHeight,
            foregroundIcon: Icons.work_outline_rounded,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue',
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 52,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Trouvez des offres qui vous ressemblent, '
                      'des formations, et lancez votre carrière au Burkina Faso.',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    AuthCtaButton(
                      label: 'Commencer',
                      onPressed: () =>
                          Get.toNamed(AppRoutes.profileSelection),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.tap();
                          Get.toNamed(AppRoutes.candidateLogin);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                            ),
                            children: [
                              const TextSpan(text: 'Vous avez déjà un compte ? '),
                              TextSpan(
                                text: 'Se connecter',
                                style: AppTextStyles.titleMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
