import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/common/glass_surface.dart';
import 'package:jobaway/app/core/widgets/common/press_scale.dart';
import 'package:jobaway/app/core/widgets/common/sheet_handle.dart';
import 'package:jobaway/app/core/widgets/skeletons/skeleton_box.dart';
import '../controllers/community_controller.dart';

/// Langues proposées pour la traduction IA (FR/EN au minimum).
const _kTranslateLangs = <String, String>{
  'fr': 'Français',
  'en': 'Anglais',
  'mos': 'Mooré',
  'ar': 'Arabe',
};

/// Ouvre une feuille élégante avec le résumé IA d'une publication (lecture
/// seule). Affiche un état de chargement premium (shimmer) puis le texte.
Future<void> showPostSummarySheet(BuildContext context, String postId) {
  AppHaptics.tap();
  final controller = Get.find<CommunityController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: ContinuousRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xxl * 1.7)),
    ),
    builder: (_) => _AiResultSheet(
      icon: IconlyLight.document,
      title: 'Résumé IA',
      loader: () => controller.summarizePost(postId),
    ),
  );
}

/// Ouvre une feuille de traduction IA : choix rapide de langue puis traduction.
Future<void> showPostTranslateSheet(BuildContext context, String postId) {
  AppHaptics.tap();
  final controller = Get.find<CommunityController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: ContinuousRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xxl * 1.7)),
    ),
    builder: (_) => _TranslateSheet(
      onTranslate: (lang) => controller.translatePost(postId, lang),
    ),
  );
}

/// Feuille générique « résultat IA » : exécute [loader], shimmer pendant le
/// chargement, puis affiche le texte (ou un message d'indisponibilité doux).
class _AiResultSheet extends StatefulWidget {
  const _AiResultSheet({
    required this.icon,
    required this.title,
    required this.loader,
  });

  final IconData icon;
  final String title;
  final Future<String?> Function() loader;

  @override
  State<_AiResultSheet> createState() => _AiResultSheetState();
}

class _AiResultSheetState extends State<_AiResultSheet> {
  bool _loading = true;
  String? _result;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    final res = await widget.loader();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetRadius =
        BorderRadius.vertical(top: Radius.circular(AppRadius.xxl * 1.7));
    return GlassSurface(
      borderRadius: sheetRadius,
      enableBlur: true,
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            _AiHeader(icon: widget.icon, title: widget.title),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _loading
                  ? const _AiTextSkeleton()
                  : _AiResultBody(
                      result: _result,
                      onRetry: _run,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Corps : texte du résultat dans une carte douce, ou état d'indisponibilité.
class _AiResultBody extends StatelessWidget {
  const _AiResultBody({required this.result, required this.onRetry});

  final String? result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assistant indisponible pour le moment.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: Icon(IconlyLight.arrow_right_circle,
                size: 18, color: AppColors.primaryAccent),
            label: Text(
              'Réessayer',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        result!,
        style: AppTextStyles.bodyMd
            .copyWith(color: AppColors.titleColor, height: 1.55),
      ),
    );
  }
}

/// En-tête de feuille IA : pastille colorée + titre + sous-titre.
class _AiHeader extends StatelessWidget {
  const _AiHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: AppColors.primaryAccent, size: 22),
            ),
            // Étincelle IA — identité visuelle commune.
            Positioned(
              right: -2,
              top: -2,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.primaryAccent),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Généré par l\'assistant IA',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton shimmer : quelques lignes de texte en cours de génération.
class _AiTextSkeleton extends StatelessWidget {
  const _AiTextSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(height: 14, width: double.infinity),
        SizedBox(height: 10),
        SkeletonBox(height: 14, width: double.infinity),
        SizedBox(height: 10),
        SkeletonBox(height: 14, width: 220),
      ],
    );
  }
}

/// Feuille de traduction : sélection de langue (chips) puis résultat IA.
class _TranslateSheet extends StatefulWidget {
  const _TranslateSheet({required this.onTranslate});

  final Future<String?> Function(String lang) onTranslate;

  @override
  State<_TranslateSheet> createState() => _TranslateSheetState();
}

class _TranslateSheetState extends State<_TranslateSheet> {
  String? _lang;
  bool _loading = false;
  String? _result;

  Future<void> _pick(String lang) async {
    AppHaptics.tap();
    setState(() {
      _lang = lang;
      _loading = true;
      _result = null;
    });
    final res = await widget.onTranslate(lang);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetRadius =
        BorderRadius.vertical(top: Radius.circular(AppRadius.xxl * 1.7));
    return GlassSurface(
      borderRadius: sheetRadius,
      enableBlur: true,
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            const _AiHeader(icon: IconlyLight.swap, title: 'Traduire (IA)'),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _kTranslateLangs.entries.map((e) {
                final selected = _lang == e.key;
                return PressScale(
                  onTap: _loading ? null : () => _pick(e.key),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryAccent.withValues(alpha: 0.12)
                          : AppColors.surfaceLow,
                      borderRadius: AppShapes.pill,
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: AppTextStyles.labelMd.copyWith(
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _lang == null
                  ? Text(
                      'Choisissez une langue pour traduire cette publication.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    )
                  : _loading
                      ? const _AiTextSkeleton()
                      : _AiResultBody(
                          result: _result,
                          onRetry: () => _pick(_lang!),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
