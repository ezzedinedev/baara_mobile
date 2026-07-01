import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/common/app_animations.dart';
import 'package:opportune_bf/app/core/widgets/common/sank_sheet_scaffold.dart';
import 'package:opportune_bf/app/core/widgets/effects/gyro_tilt.dart';
import 'package:opportune_bf/app/core/widgets/effects/sheen_sweep.dart';

import '../controllers/streak_controller.dart';

/// Écran « Ma série » — la gamification de rétention inspirée d'Edomatch :
/// une grosse flamme + le compteur de jours, le calendrier de la semaine
/// (Lun→Dim avec pastilles flamme/× cochées), deux cartes de stats (série
/// actuelle / meilleure série) et un bandeau de réussite en pied.
///
/// 100 % branché sur le design system : aucune couleur brute, dark mode natif,
/// cartes squircle + ombres en couches comme [SuiviScreen].
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  /// Libellés courts des jours, alignés sur [StreakController.weekDays]
  /// (index 0 = lundi … 6 = dimanche).
  static const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final streak = Get.find<StreakController>();

    return SankSheetScaffold(
      title: 'Ma série',
      titleIcon: Icons.local_fire_department_rounded,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.xl,
          AppSpacing.pageH,
          AppSpacing.xxl,
        ),
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: AppMotion.medium,
              childAnimationBuilder: (w) => SlideAnimation(
                verticalOffset: AppMotion.listSlideOffset,
                curve: AppMotion.emphasizedDecelerate,
                child: FadeInAnimation(child: w),
              ),
              children: [
                _StreakHero(streak: streak),
                const SizedBox(height: AppSpacing.xxl),
                _WeekCalendar(streak: streak, dayLabels: _dayLabels),
                const SizedBox(height: AppSpacing.xl),
                _StatsRow(streak: streak),
                const SizedBox(height: AppSpacing.xl),
                _TodayBanner(streak: streak),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Héros : flamme + « X jour(s) de suite »
// ─────────────────────────────────────────────────────────────────────────────
class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak});
  final StreakController streak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pastille flamme : apparition en ressort (scale + léger overshoot).
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppMotion.long,
          curve: AppMotion.springEmphasized,
          builder: (context, t, child) =>
              Transform.scale(scale: t.clamp(0.0, 1.2), child: child),
          // Inclinaison 3D selon le téléphone + reflet spéculaire qui balaie la
          // pastille (verre/métal qui capte la lumière), clippé au squircle.
          child: GyroTilt(
            maxTilt: 0.14,
            child: SheenSweep(
              borderRadius: AppShapes.squircleRadius(AppRadius.xxl),
              intensity: 0.30,
              child: Container(
                width: 104,
                height: 104,
                decoration: ShapeDecoration(
                  color: AppColors.warningSoft,
                  shape: AppShapes.squircle(AppRadius.xxl),
                  shadows: AppColors.lightShadow,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 58,
                  color: AppColors.categoryOrange,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(() {
          final n = streak.currentStreak.value;
          return Column(
            children: [
              // Compteur animé (count-up) : la série « monte » à l'ouverture.
              AnimatedCount(
                value: n,
                duration: AppMotion.long,
                builder: (ctx, v) => Text(
                  '$v',
                  style: AppTextStyles.displayHero.copyWith(
                    color: AppColors.categoryOrange,
                    fontSize: 48,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                n <= 1 ? 'jour de suite' : 'jours de suite',
                style: AppTextStyles.titleLg.copyWith(
                  color: AppColors.bodyColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendrier hebdo : Lun → Dim, pastille flamme (cochée) ou × (manquée).
// ─────────────────────────────────────────────────────────────────────────────
class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({required this.streak, required this.dayLabels});
  final StreakController streak;
  final List<String> dayLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.squircleRadius(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.lightShadow,
      ),
      child: Obx(() {
        final checked = streak.weekDays;
        final dates = streak.weekDates;
        final today = DateTime.now();
        // Apparition en cascade (scale + fade) des 7 pastilles, gauche → droite.
        return AnimationLimiter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AnimationConfiguration.toStaggeredList(
              duration: AppMotion.medium,
              childAnimationBuilder: (w) => ScaleAnimation(
                scale: 0.6,
                curve: AppMotion.springEmphasized,
                child: FadeInAnimation(child: w),
              ),
              children: [
                for (var i = 0; i < 7; i++)
                  _DayPill(
                    label: dayLabels[i],
                    dayNumber: dates[i].day,
                    checked: checked[i],
                    isToday: dates[i].year == today.year &&
                        dates[i].month == today.month &&
                        dates[i].day == today.day,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.dayNumber,
    required this.checked,
    required this.isToday,
  });

  final String label;
  final int dayNumber;
  final bool checked;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isToday ? AppColors.warningAccent : AppColors.hintColor,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: checked ? AppColors.categoryOrange : AppColors.surfaceLow,
            shape: BoxShape.circle,
            border: isToday && !checked
                ? Border.all(color: AppColors.warningAccent, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            checked ? Icons.local_fire_department_rounded : Icons.close_rounded,
            size: checked ? 19 : 16,
            color: checked ? AppColors.onPrimary : AppColors.hintColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$dayNumber',
          style: AppTextStyles.labelSm.copyWith(
            color: checked ? AppColors.titleColor : AppColors.hintColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats : « Série actuelle » (orange) + « Meilleure série » (vert, trophée).
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.streak});
  final StreakController streak;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight : borne la hauteur du Row pour que `stretch` égalise les
    // deux cartes sans demander une hauteur infinie (on est dans un scroll).
    return Obx(() {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: '${streak.currentStreak.value}',
                label: 'Série actuelle',
                accent: AppColors.categoryOrange,
                tint: AppColors.warningSoft,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                value: '${streak.bestStreak.value}',
                label: 'Meilleure série',
                accent: AppColors.successAccent,
                tint: AppColors.successSoft,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: AppShapes.squircleRadius(AppRadius.lg),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.heroNumber.copyWith(color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.bodyColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bandeau de pied : « C'est fait pour aujourd'hui ! À demain ».
// ─────────────────────────────────────────────────────────────────────────────
class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.streak});
  final StreakController streak;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final done = streak.checkedInToday;
      // Branché sur l'état réel : si on a coché aujourd'hui, message de réussite
      // (vert) ; sinon, invite à revenir (warning).
      final accent = done ? AppColors.successAccent : AppColors.warningAccent;
      final tint = done ? AppColors.successSoft : AppColors.warningSoft;
      final icon = done ? Icons.check_circle_rounded : Icons.bolt_rounded;
      final message = done
          ? "C'est fait pour aujourd'hui ! À demain."
          : "Reviens chaque jour pour garder ta série en vie.";

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.titleMd.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
