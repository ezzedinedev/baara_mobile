part of '../cv_import_screen.dart';

class _FileChip extends StatelessWidget {
  const _FileChip({required this.filename});
  final String filename;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filename.isEmpty ? 'CV importé' : filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.hintColor,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value != null ? '$value' : '—',
                style: AppTextStyles.displayMd.copyWith(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/100',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.titleLg)),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.data});
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (data is! Map) return const SizedBox.shrink();
    final m = Map<String, dynamic>.from(data);
    final severity = m['severity']?.toString() ?? '';
    final excerpt = m['excerpt']?.toString() ?? '';
    final suggestion = m['suggestion']?.toString() ?? '';

    final sevColor = switch (severity) {
      'critique' => AppColors.errorStrong,
      'important' => AppColors.warning,
      _ => AppColors.bodyColor,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: sevColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (excerpt.isNotEmpty)
                  Text(
                    '« $excerpt »',
                    style: AppTextStyles.bodySm.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.bodyColor,
                    ),
                  ),
                if (suggestion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    suggestion,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.titleColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontSize: 10,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? '';
    final company = data['company']?.toString() ?? '';
    final period = data['period']?.toString() ?? '';
    final bullets = (data['bullets'] as List?)?.whereType<String>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? '(poste)' : title,
            style: AppTextStyles.titleMd,
          ),
          if (company.isNotEmpty || period.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [company, period].where((s) => s.isNotEmpty).join(' · '),
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.bodyColor,
              ),
            ),
          ],
          const SizedBox(height: 6),
          ...bullets.take(3).map(_BulletLine.new),
        ],
      ),
    );
  }
}
