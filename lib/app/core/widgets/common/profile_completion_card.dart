import 'package:flutter/material.dart';

import 'package:get/get.dart';



import '../../theme/app_colors.dart';

import '../../theme/app_dimens.dart';

import '../../theme/app_icons.dart';

import '../../theme/app_shapes.dart';

import '../../theme/app_text_styles.dart';

import '../../../features/profile/presentation/controllers/documents_controller.dart';

import '../../../features/profile/presentation/controllers/profile_controller.dart';

import '../../../../routes/app_routes.dart';

import '../../utils/haptics.dart';
import '../../utils/profile_completion.dart';
import 'list_nav_chevron.dart';



/// Checklist de complétion profil sur l'accueil (masquée à 100 %).

class ProfileCompletionCard extends StatelessWidget {

  const ProfileCompletionCard({super.key});



  bool _hasDocuments() {

    if (!Get.isRegistered<DocumentsController>()) return false;

    return Get.find<DocumentsController>().documents.isNotEmpty;

  }



  @override

  Widget build(BuildContext context) {

    if (!Get.isRegistered<ProfileController>()) return const SizedBox.shrink();



    final profileCtrl = Get.find<ProfileController>();

    return Obx(() {

      final profile = profileCtrl.profile.value;

      if (profile == null) return const SizedBox.shrink();



      final hasDocs = _hasDocuments();

      final pct = profile.completionPercent(hasDocuments: hasDocs);

      if (pct >= 100 || profile.isProfileComplete) {

        return const SizedBox.shrink();

      }



      final missing =

          profileCompletionMissing(profile, hasDocuments: hasDocs, limit: 3);

      if (missing.isEmpty) return const SizedBox.shrink();



      return Padding(

        padding: const EdgeInsets.fromLTRB(

          AppSpacing.pageH,

          0,

          AppSpacing.pageH,

          AppSpacing.md,

        ),

        child: Material(

          color: AppColors.surfaceCard,

          borderRadius: AppShapes.squircleRadius(AppRadius.lg),

          child: Padding(

            padding: const EdgeInsets.all(16),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    Icon(AppIcons.profile,

                        size: 20, color: AppColors.primaryAccent),

                    const SizedBox(width: 8),

                    Expanded(

                      child: Text(

                        'Profil à $pct %',

                        style: AppTextStyles.titleMd.copyWith(

                          fontWeight: FontWeight.w800,

                        ),

                      ),

                    ),

                    Text(

                      'Voir tout',

                      style: AppTextStyles.labelMd.copyWith(

                        color: AppColors.primaryAccent,

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 10),

                ClipRRect(

                  borderRadius: AppShapes.pill,

                  child: LinearProgressIndicator(

                    value: pct / 100,

                    minHeight: 6,

                    backgroundColor:

                        AppColors.outlineVariant.withValues(alpha: 0.35),

                    valueColor: AlwaysStoppedAnimation<Color>(

                      AppColors.primaryAccent,

                    ),

                  ),

                ),

                const SizedBox(height: 12),

                ...missing.map(

                  (item) => Padding(

                    padding: const EdgeInsets.only(bottom: 6),

                    child: Material(

                      color: Colors.transparent,

                      child: InkWell(

                        borderRadius: AppShapes.squircleRadius(AppRadius.sm),

                        onTap: () {

                          AppHaptics.tap();

                          Get.toNamed(item.route);

                        },

                        child: Padding(

                          padding: const EdgeInsets.symmetric(vertical: 4),

                          child: Row(

                            children: [

                              Icon(item.icon,

                                  size: 16, color: AppColors.primaryAccent),

                              const SizedBox(width: 8),

                              Expanded(

                                child: Text(

                                  item.label,

                                  style: AppTextStyles.bodySm.copyWith(

                                    color: AppColors.bodyColor,

                                    fontWeight: FontWeight.w600,

                                  ),

                                ),

                              ),

                              const ListNavChevron(size: 18),

                            ],

                          ),

                        ),

                      ),

                    ),

                  ),

                ),

                Align(

                  alignment: Alignment.centerRight,

                  child: TextButton(

                    onPressed: () {

                      AppHaptics.tap();

                      Get.toNamed(AppRoutes.profile);

                    },

                    child: Text(

                      'Compléter mon profil',

                      style: AppTextStyles.labelMd.copyWith(

                        color: AppColors.primaryAccent,

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ),

        ),

      );

    });

  }

}

