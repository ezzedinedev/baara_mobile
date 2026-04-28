import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/cv_builder_controller.dart';

part 'cv_manual_editor_parts/widgets.dart';

/// Éditeur manuel du CV — champs scalaires principaux (identité, contacts,
/// bio, objectif) + listes de chaînes pour compétences/langues.
///
/// Pour les collections complexes (expériences, formations) un écran
/// dédié sera à créer — pour l'instant un placeholder avec CTA vers
/// l'assistant IA.
class CvManualEditorScreen extends GetView<CvBuilderController> {
  const CvManualEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Édition manuelle', style: AppTextStyles.headlineSm),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.cv.value == null) {
          return const PageSkeleton(showHero: false, rowCount: 6);
        }
        // Erreur de chargement initial : on propose un retry plutôt qu'une
        // page vide ou un snackbar isolé.
        if (controller.errorMessage.value.isNotEmpty &&
            controller.cv.value == null) {
          return ErrorStateView(
            message: controller.errorMessage.value,
            onRetry: controller.load,
          );
        }
        final cv = controller.cv.value ?? const <String, dynamic>{};
        final userMap = controller.user.value ?? const <String, dynamic>{};

        return AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 280),
              childAnimationBuilder: (child) => SlideAnimation(
                verticalOffset: 14,
                child: FadeInAnimation(child: child),
              ),
              children: [
            const _SectionTitle('Identité', icon: Icons.badge_outlined),
            _ScalarField(
              controller: controller,
              field: 'first_name',
              initialValue: userMap['first_name']?.toString() ?? '',
              label: 'Prénom',
              icon: Icons.person_outline_rounded,
              isProfileField: true,
            ),
            _ScalarField(
              controller: controller,
              field: 'last_name',
              initialValue: userMap['last_name']?.toString() ?? '',
              label: 'Nom',
              icon: Icons.person_outline_rounded,
              isProfileField: true,
            ),
            _ScalarField(
              controller: controller,
              field: 'headline',
              initialValue: cv['headline']?.toString() ?? '',
              label: 'Titre professionnel',
              icon: Icons.work_outline_rounded,
              hint: 'Ex. : Développeur Flutter Junior',
            ),
            _ScalarField(
              controller: controller,
              field: 'desired_role',
              initialValue: cv['desired_role']?.toString() ?? '',
              label: 'Poste visé',
              icon: Icons.flag_outlined,
            ),
            _ScalarField(
              controller: controller,
              field: 'date_of_birth',
              initialValue: cv['date_of_birth']?.toString() ?? '',
              label: 'Date de naissance',
              icon: Icons.cake_outlined,
              hint: 'YYYY-MM-DD',
              keyboardType: TextInputType.datetime,
            ),
            _ScalarField(
              controller: controller,
              field: 'nationality',
              initialValue: cv['nationality']?.toString() ?? '',
              label: 'Nationalité',
              icon: Icons.flag_circle_outlined,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Contact', icon: Icons.contact_mail_outlined),
            _ScalarField(
              controller: controller,
              field: 'email',
              initialValue: cv['email']?.toString() ?? '',
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            _ScalarField(
              controller: controller,
              field: 'phone',
              initialValue: cv['phone']?.toString() ?? '',
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _ScalarField(
              controller: controller,
              field: 'location',
              initialValue: cv['location']?.toString() ?? '',
              label: 'Ville / région',
              icon: Icons.location_on_outlined,
            ),
            _ScalarField(
              controller: controller,
              field: 'country_residence',
              initialValue: cv['country_residence']?.toString() ?? '',
              label: 'Pays de résidence',
              icon: Icons.public_rounded,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Liens', icon: Icons.link_rounded),
            _ScalarField(
              controller: controller,
              field: 'linkedin_url',
              initialValue: cv['linkedin_url']?.toString() ?? '',
              label: 'LinkedIn',
              icon: Icons.work_history_rounded,
              keyboardType: TextInputType.url,
            ),
            _ScalarField(
              controller: controller,
              field: 'portfolio_url',
              initialValue: cv['portfolio_url']?.toString() ?? '',
              label: 'Portfolio',
              icon: Icons.web_rounded,
              keyboardType: TextInputType.url,
            ),
            _ScalarField(
              controller: controller,
              field: 'github_url',
              initialValue: cv['github_url']?.toString() ?? '',
              label: 'GitHub',
              icon: Icons.code_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Présentation', icon: Icons.description_outlined),
            _ScalarField(
              controller: controller,
              field: 'bio',
              initialValue: cv['bio']?.toString() ?? '',
              label: 'Bio',
              icon: Icons.auto_stories_outlined,
              maxLines: 5,
              hint: 'Décris-toi en 3-4 phrases.',
            ),
            _ScalarField(
              controller: controller,
              field: 'objective',
              initialValue: cv['objective']?.toString() ?? '',
              label: 'Objectif professionnel',
              icon: Icons.emoji_objects_outlined,
              maxLines: 4,
              hint: 'Ce que tu veux accomplir.',
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Compétences', icon: Icons.star_outline_rounded),
            _TagListField(
              controller: controller,
              field: 'hard_skills',
              initialValues: _listFrom(cv['hard_skills']),
              label: 'Compétences techniques',
              hint: 'Ex. : Flutter, Dart, API REST',
              color: AppColors.categoryBlue,
            ),
            _TagListField(
              controller: controller,
              field: 'soft_skills',
              initialValues: _listFrom(cv['soft_skills']),
              label: 'Soft skills',
              hint: 'Ex. : communication, leadership',
              color: AppColors.categoryPurple,
            ),
            _TagListField(
              controller: controller,
              field: 'certifications',
              initialValues: _listFrom(cv['certifications']),
              label: 'Certifications',
              hint: 'Ex. : AWS Cloud Practitioner',
              color: AppColors.categoryOrange,
            ),
            _TagListField(
              controller: controller,
              field: 'interests',
              initialValues: _listFrom(cv['interests']),
              label: 'Centres d\'intérêt',
              hint: 'Ex. : photographie, lecture',
              color: AppColors.categoryCyan,
            ),
            const SizedBox(height: 18),
            _ComplexSectionsHint(),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final saving = controller.isSaving.value;
        if (!saving) return const SizedBox.shrink();
        return Container(
          color: AppColors.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Enregistrement…',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static List<String> _listFrom(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return <String>[];
  }
}

