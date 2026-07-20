import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

import '../../../domain/entities/cv_template.dart';
import '../../controllers/cv_preview_controller.dart';

/// Aperçu du CV : catalogue complet des modèles (le même que le web), rendu PDF
/// réel, et téléchargement. Les modèles premium s'aperçoivent librement — avec
/// un filigrane — et se débloquent par mobile money avant téléchargement.
class CvPreviewScreen extends GetView<CvPreviewController> {
  const CvPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Aperçu du CV',
            subtitle: 'Choisissez un modèle, partagez ou téléchargez',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                );
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              return Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const _TemplateBar(),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: _PdfArea()),
                  const _DownloadBar(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Modèle courant + accès au catalogue. Une rangée de chips ne tient plus :
/// la plateforme propose 21 modèles, on passe donc par une feuille dédiée.
class _TemplateBar extends StatelessWidget {
  const _TemplateBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvPreviewController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Obx(() {
        final current = controller.current;
        return PressScale(
          curve: AppMotion.spring,
          onTap: () {
            AppHaptics.tap();
            _openTemplateSheet(controller);
          },
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: AppColors.surfaceLow,
              shape: AppShapes.cardBordered(AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(IconlyLight.category,
                      size: 18, color: AppColors.primaryAccent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current?.label ?? 'Choisir un modèle',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (current != null && current.tone.isNotEmpty)
                          Text(
                            current.tone,
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColors.hintColor),
                          ),
                      ],
                    ),
                  ),
                  if (current != null && current.isLocked)
                    _PremiumBadge(priceFcfa: current.priceFcfa),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(IconlyLight.arrow_down_2,
                      size: 18, color: AppColors.hintColor),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.priceFcfa});

  final int priceFcfa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconlyBold.lock, size: 12, color: AppColors.warningAccent),
          const SizedBox(width: 4),
          Text(
            '$priceFcfa F',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.warningAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

void _openTemplateSheet(CvPreviewController controller) {
  const sections = <({String tier, String title})>[
    (tier: 'base', title: 'Essentiels'),
    (tier: 'enhanced', title: 'Avancés'),
    (tier: 'premium', title: 'Premium · ATS'),
  ];

  Get.bottomSheet<void>(
    SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            Text(
              'Modèles de CV',
              style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: Obx(
                () => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final section in sections) ...[
                      SectionLabel(section.title),
                      const SizedBox(height: AppSpacing.xs),
                      for (final t in controller.templates
                          .where((t) => t.tier == section.tier))
                        _TemplateTile(
                          template: t,
                          selected: t.id == controller.selectedTemplate.value,
                          onTap: () {
                            AppHaptics.tap();
                            controller.changeTemplate(t.id);
                            Get.back<void>();
                          },
                        ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final CvTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        onTap: onTap,
        curve: AppMotion.spring,
        child: AnimatedContainer(
          duration: AppMotion.short,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.surfaceSelected : AppColors.surfaceLow,
            borderRadius: AppShapes.squircleRadius(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.surfaceLow,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.titleColor,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (template.tone.isNotEmpty)
                      Text(
                        template.tone,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.hintColor),
                      ),
                  ],
                ),
              ),
              if (template.isLocked)
                _PremiumBadge(priceFcfa: template.priceFcfa)
              else if (template.isPremium)
                Icon(IconlyBold.tick_square,
                    size: 16, color: AppColors.primaryAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvPreviewController>();
    // Fit-to-HEIGHT : par défaut PdfPreview ajuste la page à la largeur, ce qui
    // rend une A4 plus haute que la zone visible → il fallait scroller pour voir
    // le bas du CV. On contraint plutôt la largeur pour que la page entière tienne
    // dans la hauteur disponible (ratio A4 = 210/297). L'utilisateur peut toujours
    // zoomer au doigt pour lire les détails.
    return LayoutBuilder(
      builder: (context, constraints) {
        // On réserve ~56 px pour la barre d'actions interne + les marges de page.
        final available = constraints.maxHeight - 72;
        final fitWidth = available > 0 ? available * (210 / 297) : 260.0;

        return Obx(
          // La clé force PdfPreview à régénérer l'aperçu quand le modèle change —
          // et après un achat, pour faire tomber le filigrane.
          () => PdfPreview(
            key: ValueKey(
              '${controller.selectedTemplate.value}-${controller.isCurrentLocked}',
            ),
            build: (PdfPageFormat format) => controller.pdfBytes(),
            maxPageWidth: fitWidth,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            // Sur un modèle verrouillé, l'aperçu est filigrané côté serveur :
            // imprimer ou partager ne contourne donc pas le paiement.
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'CV-JobAway.pdf',
            loadingWidget: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            // Marge resserrée : chaque pixel gagné agrandit le CV visible.
            previewPageMargin: const EdgeInsets.all(AppSpacing.sm),
            scrollViewDecoration: BoxDecoration(color: AppColors.surfaceLow),
            // La barre d'actions par défaut était un gros bandeau vert (couleur
            // primaire) qui écrasait l'aperçu. On la rend discrète : fond clair,
            // icônes vertes, hauteur maîtrisée.
            actionBarTheme: PdfActionBarTheme(
              backgroundColor: AppColors.surfaceLow,
              iconColor: AppColors.primaryAccent,
              height: 44,
              elevation: 0,
            ),
          ),
        );
      },
    );
  }
}

/// Téléchargement du PDF propre — ou déblocage, si le modèle est premium.
class _DownloadBar extends StatelessWidget {
  const _DownloadBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvPreviewController>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: Obx(() {
          final locked = controller.isCurrentLocked;
          final busy =
              controller.isDownloading.value || controller.isPurchasing.value;
          return GradientButton(
            label: locked
                ? 'DÉBLOQUER À ${controller.currentPriceFcfa} F'
                : 'TÉLÉCHARGER LE PDF',
            isLoading: busy,
            textColor: AppColors.onPrimary,
            height: 52,
            borderRadius: 14,
            onPressed: busy
                ? null
                : () => locked
                    ? _openPurchaseSheet(controller)
                    : _download(controller),
          );
        }),
      ),
    );
  }
}

Future<void> _download(CvPreviewController controller) async {
  AppHaptics.tap();
  try {
    final path = await controller.downloadToDevice();
    if (path == null) return; // L'utilisateur a annulé la boîte de dialogue.
    AppHaptics.confirm();
    AppToast.success('CV enregistré', 'Votre CV a été téléchargé.');
  } catch (e) {
    AppToast.error('Téléchargement impossible', userFacingError(e));
  }
}

void _openPurchaseSheet(CvPreviewController controller) {
  AppHaptics.tap();
  Get.bottomSheet<void>(
    _PurchaseSheet(controller: controller),
    isScrollControlled: true,
  );
}

/// Déblocage d'un modèle premium : opérateur mobile money + numéro.
class _PurchaseSheet extends StatefulWidget {
  const _PurchaseSheet({required this.controller});

  final CvPreviewController controller;

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  final _phoneCtrl = TextEditingController();
  String? _provider;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final provider = _provider;
    final phone = _phoneCtrl.text.trim();
    if (provider == null) {
      setState(() => _error = 'Choisissez un moyen de paiement.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Entrez le numéro associé à votre compte.');
      return;
    }
    setState(() => _error = null);
    AppHaptics.tap();

    try {
      await widget.controller.purchaseCurrent(provider: provider, phone: phone);
      if (!mounted) return;
      Get.back<void>();
      AppHaptics.confirm();
      AppToast.success(
        'Modèle débloqué',
        'Vous pouvez maintenant télécharger votre CV.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userFacingError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.controller.current;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Text(
                'Débloquer « ${template?.label ?? 'ce modèle'} »',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Paiement unique de ${widget.controller.currentPriceFcfa} FCFA. '
                'Le modèle reste débloqué, sur mobile comme sur le web.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final p in CvPreviewController.paymentProviders)
                    _ProviderChip(
                      label: p.label,
                      selected: _provider == p.id,
                      onTap: () {
                        AppHaptics.tap();
                        setState(() => _provider = p.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledInput(
                label: 'Numéro mobile money',
                placeholder: '70 00 00 00',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => GradientButton(
                  label: 'PAYER ${widget.controller.currentPriceFcfa} F',
                  isLoading: widget.controller.isPurchasing.value,
                  textColor: AppColors.onPrimary,
                  height: 52,
                  borderRadius: 14,
                  onPressed:
                      widget.controller.isPurchasing.value ? null : _pay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      curve: AppMotion.spring,
      child: AnimatedContainer(
        duration: AppMotion.short,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSelected : AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.surfaceLow,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.primaryAccent : AppColors.bodyColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
