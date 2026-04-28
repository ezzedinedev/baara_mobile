part of '../home_formation_detail_page.dart';

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surfaceCard,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              AppHaptics.tap();
              Navigator.of(context).maybePop();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.titleColor,
                size: 24,
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          title.isEmpty ? 'Formation' : title,
          style: AppTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Material(
          color: AppColors.surfaceCard,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => AppHaptics.tap(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.titleColor,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Banner hero du cours — gradient violet, badge titre cours en haut a gauche,
/// bouton play central, icones format en bas, le tout decoratif.
class _CourseHeroBanner extends StatelessWidget {
  const _CourseHeroBanner({required this.formation});
  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    final hasCover = formation.coverUrl.trim().isNotEmpty;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.categoryPurple,
              AppColors.categoryPurpleDeep,
              AppColors.categoryCyan,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.categoryPurpleDeep.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (hasCover)
              Positioned.fill(
                child: Image.network(
                  formation.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (hasCover)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.categoryPurple.withValues(alpha: 0.55),
                        AppColors.categoryPurpleDeep.withValues(alpha: 0.50),
                        AppColors.categoryCyan.withValues(alpha: 0.40),
                      ],
                    ),
                  ),
                ),
              ),
            const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
            // Decor cercles flottants.
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Bouton play central decoratif.
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.20),
                  border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.36),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.onPrimary,
                  size: 38,
                ),
              ),
            ),
            // Bandeau titre cours.
            Positioned(
              top: 16,
              left: 16,
              right: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bannerTitle.toUpperCase(),
                    style: AppTextStyles.titleLg.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      height: 1.15,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Programme professionnel',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            // Pastilles format en bas.
            const Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  _HeroFormatPill(
                    icon: Icons.signal_wifi_off_rounded,
                    label: 'OFFLINE',
                  ),
                  SizedBox(width: 8),
                  _HeroFormatPill(
                    icon: Icons.devices_other_rounded,
                    label: 'HYBRIDE',
                  ),
                  SizedBox(width: 8),
                  _HeroFormatPill(
                    icon: Icons.public_rounded,
                    label: 'ONLINE',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _bannerTitle {
    final raw = formation.title.trim();
    if (raw.isEmpty) return 'Formation';
    final firstLine = raw.split('\n').first;
    return firstLine.length > 28
        ? firstLine.substring(0, 28).trimRight()
        : firstLine;
  }
}

class _HeroFormatPill extends StatelessWidget {
  const _HeroFormatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.onPrimary, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.current, required this.onChanged});
  final _DetailTab current;
  final ValueChanged<_DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Videos',
            selected: current == _DetailTab.videos,
            onTap: () => onChanged(_DetailTab.videos),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TabButton(
            label: 'Description',
            selected: current == _DetailTab.description,
            onTap: () => onChanged(_DetailTab.description),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.categoryPurple,
                      AppColors.categoryPurpleDeep,
                    ],
                  )
                : null,
            color: selected ? null : AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.categoryPurpleDeep
                          .withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.titleMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.bodyColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({
    super.key,
    required this.formation,
    required this.controller,
  });

  final HomeFormationPreview formation;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    if (formation.modules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(
          icon: Icons.video_library_outlined,
          title: 'Aucune lecon disponible',
          subtitle:
              'Cette formation ne contient pas encore de modules. Revenez plus tard.',
        ),
      );
    }

    final showProgress = formation.isEnrolled;
    final completed =
        formation.modules.where((m) => m.isCompleted).length;
    final total = formation.modules.length;

    return Column(
      children: [
        if (showProgress) ...[
          _ProgressBar(
            percent: formation.progressPercent,
            ratio: formation.progressRatio.clamp(0.0, 1.0),
            completed: completed,
            total: total,
          ),
          const SizedBox(height: 14),
        ],
        ...List.generate(formation.modules.length, (index) {
          final lesson = formation.modules[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == formation.modules.length - 1 ? 0 : 12,
            ),
            child: _LessonRow(
              index: index + 1,
              lesson: lesson,
              isLocked: !formation.isEnrolled,
              onTap: () {
                AppHaptics.tap();
                if (!formation.isEnrolled) {
                  AppToast.info(
                    'Inscription requise',
                    'Inscrivez-vous a la formation pour acceder aux lecons.',
                  );
                  return;
                }
                openFormationLesson(controller, formation, index);
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.percent,
    required this.ratio,
    required this.completed,
    required this.total,
  });

  final int percent;
  final double ratio;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progression',
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed sur $total lecon(s) terminee(s)',
            style: AppTextStyles.bodySm,
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.isLocked,
    required this.onTap,
  });

  final int index;
  final HomeTrainingLesson lesson;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.categoryPurple;
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  lesson.isCompleted
                      ? Icons.check_rounded
                      : isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.play_arrow_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title.isEmpty
                          ? 'Lecon ${index.toString().padLeft(2, '0')}'
                          : lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.durationLabel.isEmpty
                          ? lesson.typeLabel
                          : lesson.durationLabel,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.bodyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Termine',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.successStrong,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({super.key, required this.formation});

  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusChipsRow(formation: formation),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Description',
          icon: Icons.notes_rounded,
          color: AppColors.categoryBlue,
          child: Text(
            formation.description.isEmpty
                ? 'Description non fournie.'
                : formation.description,
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.5,
              color: AppColors.bodyColor,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MetaGrid(formation: formation),
        const SizedBox(height: 14),
        _BulletSection(
          title: 'Objectifs',
          icon: Icons.flag_outlined,
          color: AppColors.successDark,
          items: formation.objectives.isEmpty
              ? const ['Objectifs non precises.']
              : formation.objectives,
        ),
        const SizedBox(height: 14),
        _BulletSection(
          title: 'Prerequis',
          icon: Icons.rule_rounded,
          color: AppColors.categoryPurple,
          items: formation.requirements.isEmpty
              ? const ['Prerequis non precises.']
              : formation.requirements,
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Contact',
          icon: Icons.business_outlined,
          color: AppColors.categoryPink,
          child: Text(
            formation.providerName.isEmpty ? '—' : formation.providerName,
            style: AppTextStyles.titleMd.copyWith(
              color: AppColors.titleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChipsRow extends StatelessWidget {
  const _StatusChipsRow({required this.formation});

  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          text: formation.status,
          background: AppColors.successSoft,
          textColor: AppColors.primary,
        ),
        _StatusChip(
          text: formation.level,
          background: AppColors.categoryBlueSoft,
          textColor: AppColors.categoryBlue,
        ),
        _StatusChip(
          text: formation.formatLabel,
          background: AppColors.warningSoft,
          textColor: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: textColor,
          letterSpacing: 0.2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.formation});

  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    final items = <_MetaEntry>[
      _MetaEntry(
        icon: Icons.location_on_outlined,
        color: AppColors.categoryBlue,
        title: 'Lieu',
        value: formation.location,
      ),
      _MetaEntry(
        icon: Icons.access_time_rounded,
        color: AppColors.categoryPink,
        title: 'Duree',
        value: formation.durationLabel,
      ),
      _MetaEntry(
        icon: Icons.calendar_month_outlined,
        color: AppColors.categoryPurple,
        title: 'Debut',
        value: formation.startDateLabel,
      ),
      _MetaEntry(
        icon: Icons.event_busy_outlined,
        color: AppColors.warning,
        title: 'Limite',
        value: formation.deadlineLabel,
      ),
      _MetaEntry(
        icon: Icons.payments_outlined,
        color: AppColors.categoryOrange,
        title: 'Prix',
        value: formation.priceLabel,
      ),
      _MetaEntry(
        icon: Icons.menu_book_rounded,
        color: AppColors.categoryCyan,
        title: 'Modules',
        value: '${formation.modules.length} module(s)',
      ),
      _MetaEntry(
        icon: Icons.verified_outlined,
        color: AppColors.successDark,
        title: 'Certificat',
        value: formation.certificationLabel,
      ),
      _MetaEntry(
        icon: Icons.language_rounded,
        color: AppColors.categoryGray,
        title: 'Langue',
        value: formation.languageLabel,
      ),
      _MetaEntry(
        icon: Icons.groups_rounded,
        color: AppColors.primaryMedium,
        title: 'Inscrits',
        value: '${formation.enrolledCount}',
      ),
      _MetaEntry(
        icon: Icons.star_rounded,
        color: AppColors.warning,
        title: 'Note',
        value: formation.rating.toStringAsFixed(1),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 96,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _MetaTile(entry: items[index]),
    );
  }
}

class _MetaEntry {
  const _MetaEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.entry});

  final _MetaEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon, color: entry.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.title.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.titleColor,
                    fontSize: 13,
                    height: 1.2,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.titleLg),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      icon: icon,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodyMd.copyWith(
                          height: 1.45,
                          color: AppColors.bodyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _EnrollCta extends StatelessWidget {
  const _EnrollCta({required this.formation, required this.controller});

  final HomeFormationPreview formation;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentFormation =
          controller.formationById(formation.id) ?? formation;
      final isEnrolling =
          controller.enrollingFormationId.value == formation.id;
      final isEnrolled = currentFormation.isEnrolled;
      final hasModules = currentFormation.modules.isNotEmpty;
      final completedAll = hasModules &&
          currentFormation.modules.every((m) => m.isCompleted);

      final buttonLabel = isEnrolled
          ? (!hasModules
              ? 'AUCUNE LECON DISPONIBLE'
              : completedAll
                  ? 'REVOIR LA FORMATION'
                  : 'COMMENCER MAINTENANT')
          : currentFormation.isPaid
              ? 'PASSER AU PAIEMENT'
              : 'SUIVRE LA FORMATION';

      final disabled = isEnrolling || (isEnrolled && !hasModules);

      return GradientButton(
        label: buttonLabel,
        isLoading: isEnrolling,
        textColor: AppColors.onPrimary,
        height: 52,
        borderRadius: 14,
        onPressed: disabled
            ? null
            : () => _onPressed(context, currentFormation, isEnrolled),
      );
    });
  }

  Future<void> _onPressed(
    BuildContext context,
    HomeFormationPreview currentFormation,
    bool isEnrolled,
  ) async {
    AppHaptics.success();
    final navigator = Navigator.of(context);

    if (isEnrolled) {
      // Reprend la 1re lecon non terminee, sinon la premiere.
      final nextIndex = currentFormation.modules
          .indexWhere((module) => !module.isCompleted);
      final targetIndex = nextIndex < 0 ? 0 : nextIndex;
      openFormationLesson(controller, currentFormation, targetIndex);
      return;
    }

    if (currentFormation.isPaid) {
      navigator.pop();
      openFormationPayment(controller, currentFormation);
      return;
    }

    final enrolled = await controller.enrollInFormation(currentFormation);
    if (!navigator.mounted || !enrolled) {
      return;
    }
    // Reste sur la page detail : la barre de progression et la liste de
    // lecons deviennent debloquees automatiquement (Obx + isEnrolled=true).
  }
}
