import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../controllers/home_controller.dart';
import 'home_training_flow.dart';

part 'home_formation_detail_parts/widgets.dart';

enum _DetailTab { videos, description }

/// Page de detail d'une formation — refonte inspiree du mockup MasterClass :
/// hero banner purple + segmented tabs Videos/Description + liste de lecons.
class FormationDetailPage extends StatefulWidget {
  const FormationDetailPage({
    super.key,
    required this.formation,
    required this.controller,
  });

  final HomeFormationPreview formation;
  final HomeController controller;

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  _DetailTab _tab = _DetailTab.videos;

  @override
  Widget build(BuildContext context) {
    final formation = widget.formation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 320),
              childAnimationBuilder: (child) => SlideAnimation(
                verticalOffset: 18,
                child: FadeInAnimation(child: child),
              ),
              children: [
                _DetailTopBar(title: formation.formatLabel),
                const SizedBox(height: 12),
                _CourseHeroBanner(formation: formation),
                const SizedBox(height: 18),
                Text(
                  formation.title,
                  style: AppTextStyles.headlineLg.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cree par ${formation.providerName.isEmpty ? "—" : formation.providerName}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formation.modules.length} videos',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.hintColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _TabSwitcher(
                  current: _tab,
                  onChanged: (next) {
                    AppHaptics.tap();
                    setState(() => _tab = next);
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _tab == _DetailTab.videos
                      ? _VideosTab(
                          key: const ValueKey('videos'),
                          formation: formation,
                          controller: widget.controller,
                        )
                      : _DescriptionTab(
                          key: const ValueKey('description'),
                          formation: formation,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: _EnrollCta(
            formation: formation,
            controller: widget.controller,
          ),
        ),
      ),
    );
  }
}

/// Point d'entree utilise depuis les listes de formations — encapsule la nav.
void openFormationDetail(
  BuildContext context,
  HomeController controller,
  HomeFormationPreview formation,
) {
  AppHaptics.tap();
  Get.to<void>(
    () => FormationDetailPage(formation: formation, controller: controller),
    transition: Transition.rightToLeft,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );
}
