import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../../widgets/widgets.dart';
import '../controllers/cv_builder_controller.dart';
import '../repositories/cv_builder_repository.dart';

/// Prévisualisation du CV construit côté app — version texte structurée
/// (les rubriques sont rendues natif via Flutter pour éviter un WebView).
/// Pour une fidélité 100% identique au PDF serveur, lancer le download
/// qui passe par `cv-builder.pdf.blade.php`.
class CvPreviewScreen extends GetView<CvBuilderController> {
  const CvPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Aperçu du CV', style: AppTextStyles.headlineSm),
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
        final cv = controller.cv.value ?? const <String, dynamic>{};
        final user = controller.user.value ?? const <String, dynamic>{};
        final isEmpty = cv.isEmpty;

        if (controller.isLoading.value && cv.isEmpty) {
          return const PageSkeleton(rowCount: 5);
        }

        // Erreur de chargement → bouton Reessayer.
        if (controller.errorMessage.value.isNotEmpty && cv.isEmpty) {
          return ErrorStateView(
            message: controller.errorMessage.value,
            onRetry: () => controller.load(),
          );
        }

        if (isEmpty) {
          return const EmptyState(
            icon: Icons.description_outlined,
            title: 'CV vide',
            subtitle: 'Commence à remplir ton CV avec l\'assistant ou l\'éditeur manuel.',
          );
        }

        return AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 320),
              childAnimationBuilder: (child) => SlideAnimation(
                verticalOffset: 18,
                child: FadeInAnimation(child: child),
              ),
              children: [
                _CvHeader(cv: cv, user: user),
                const SizedBox(height: 18),
                if (_nonEmpty(cv['bio']))
                  _Section(title: 'À propos', body: _textBody(cv['bio'])),
                if (_nonEmpty(cv['objective']))
                  _Section(title: 'Objectif', body: _textBody(cv['objective'])),
                _ListSection(
                  title: 'Compétences techniques',
                  items: _listStr(cv['hard_skills']),
                  color: AppColors.categoryBlue,
                ),
                _ListSection(
                  title: 'Soft skills',
                  items: _listStr(cv['soft_skills']),
                  color: AppColors.categoryPurple,
                ),
                _LanguageSection(languages: cv['languages']),
                _ExperienceSection(experiences: cv['experiences']),
                _EducationSection(educations: cv['educations']),
                _ListSection(
                  title: 'Certifications',
                  items: _listStr(cv['certifications']),
                  color: AppColors.categoryOrange,
                ),
                _ListSection(
                  title: 'Centres d\'intérêt',
                  items: _listStr(cv['interests']),
                  color: AppColors.categoryCyan,
                ),
                const SizedBox(height: 24),
                _DownloadHint(),
              ],
            ),
          ),
        );
      }),
    );
  }

  static bool _nonEmpty(dynamic v) {
    if (v == null) return false;
    return v.toString().trim().isNotEmpty;
  }

  static Widget _textBody(dynamic v) {
    return Text(
      v.toString(),
      style: AppTextStyles.bodyMd.copyWith(height: 1.5),
    );
  }

  static List<String> _listStr(dynamic v) {
    if (v is List) {
      return v.whereType<String>().toList();
    }
    return const [];
  }
}

class _CvHeader extends StatelessWidget {
  const _CvHeader({required this.cv, required this.user});

  final Map<String, dynamic> cv;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final fullName = [
      user['first_name']?.toString() ?? '',
      user['last_name']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    final headline = cv['headline']?.toString() ?? '';
    final role = cv['desired_role']?.toString() ?? '';
    final location = cv['location']?.toString() ?? '';
    final email = cv['email']?.toString() ?? '';
    final phone = cv['phone']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullName.isEmpty ? 'Nom à compléter' : fullName,
            style: AppTextStyles.displayMd.copyWith(fontSize: 26),
          ),
          if (headline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              headline,
              style: AppTextStyles.titleLg.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
          if (role.isNotEmpty && role != headline) ...[
            const SizedBox(height: 2),
            Text(
              role,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (location.isNotEmpty)
                _ContactLine(icon: Icons.location_on_outlined, text: location),
              if (email.isNotEmpty)
                _ContactLine(icon: Icons.email_outlined, text: email),
              if (phone.isNotEmpty)
                _ContactLine(icon: Icons.phone_outlined, text: phone),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.bodyColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.primary,
                fontSize: 11,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            body,
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.items,
    required this.color,
  });

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: title,
      body: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items
            .map((i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    i,
                    style: AppTextStyles.labelSm.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({required this.languages});
  final dynamic languages;

  @override
  Widget build(BuildContext context) {
    if (languages is! List || languages.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Langues',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: languages.map<Widget>((lang) {
          if (lang is Map) {
            final name = lang['name']?.toString() ?? '';
            final level = lang['level']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    name.isEmpty ? '(langue)' : name,
                    style: AppTextStyles.titleMd.copyWith(fontSize: 13),
                  ),
                  if (level.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· $level',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor),
                    ),
                  ],
                ],
              ),
            );
          }
          return Text(
            lang.toString(),
            style: AppTextStyles.bodyMd,
          );
        }).toList(),
      ),
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({required this.experiences});
  final dynamic experiences;

  @override
  Widget build(BuildContext context) {
    if (experiences is! List || experiences.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: 'Expériences',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: experiences.whereType<Map>().map<Widget>((exp) {
          final m = Map<String, dynamic>.from(exp);
          final title = m['title']?.toString() ?? '';
          final company = m['company']?.toString() ?? '';
          final period = m['period']?.toString() ?? '';
          final bullets =
              (m['bullets'] as List?)?.whereType<String>() ?? const [];
          final desc = m['description']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: AppTextStyles.titleMd),
                if (company.isNotEmpty || period.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [company, period].where((s) => s.isNotEmpty).join(' · '),
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.bodyColor),
                  ),
                ],
                if (bullets.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...bullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b,
                              style:
                                  AppTextStyles.bodyMd.copyWith(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: AppTextStyles.bodyMd.copyWith(height: 1.45),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EducationSection extends StatelessWidget {
  const _EducationSection({required this.educations});
  final dynamic educations;

  @override
  Widget build(BuildContext context) {
    if (educations is! List || educations.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      title: 'Formations',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: educations.whereType<Map>().map<Widget>((ed) {
          final m = Map<String, dynamic>.from(ed);
          final degree = m['degree']?.toString() ?? '';
          final school = m['school']?.toString() ?? '';
          final period = m['period']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree.isEmpty ? '(diplôme)' : degree,
                  style: AppTextStyles.titleMd,
                ),
                if (school.isNotEmpty || period.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [school, period].where((s) => s.isNotEmpty).join(' · '),
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.bodyColor),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DownloadHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = CvBuilderRepository(apiProvider: Get.find());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.download_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Télécharger le PDF',
                  style: AppTextStyles.titleMd.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le PDF officiel est généré côté serveur (identique au web).\n'
                  'URL : ${repo.downloadUrl()}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
