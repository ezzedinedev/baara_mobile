import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/cv_builder_controller.dart';

/// Aperçu du CV en A4 réel : on charge les bytes PDF générés côté serveur
/// (`cv-builder.pdf.blade.php`) et on les affiche via Syncfusion PDF Viewer.
/// L'utilisateur peut basculer entre les 3 templates (classique, moderne,
/// minimaliste) via un PageView et télécharger le template courant.
class CvPreviewScreen extends StatefulWidget {
  const CvPreviewScreen({super.key});

  @override
  State<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends State<CvPreviewScreen> {
  static const List<({String id, String label})> _templates = [
    (id: 'classic', label: 'Classique'),
    (id: 'modern', label: 'Moderne'),
    (id: 'minimal', label: 'Minimaliste'),
  ];

  late final PageController _pageCtrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // On positionne le PageView sur le template deja choisi par l'utilisateur
    // (s'il en a deja choisi un). Comme ca, en rouvrant l'apercu, il retombe
    // directement sur "son" CV au lieu de toujours partir sur "classic".
    final controller = Get.find<CvBuilderController>();
    final initial = _indexForTemplate(controller.selectedTemplate.value);
    _currentIndex = initial;
    _pageCtrl = PageController(initialPage: initial);
  }

  int _indexForTemplate(String template) {
    final i = _templates.indexWhere((t) => t.id == template);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  CvBuilderController get controller => Get.find<CvBuilderController>();

  String get _currentTemplate => _templates[_currentIndex].id;
  String get _currentLabel => _templates[_currentIndex].label;

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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _TemplateHeader(
              currentIndex: _currentIndex,
              currentLabel: _currentLabel,
              total: _templates.length,
              onSelectIndex: _goToTemplate,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _templates.length,
                onPageChanged: (i) {
                  AppHaptics.tap();
                  setState(() => _currentIndex = i);
                },
                itemBuilder: (_, i) => _PdfTemplatePage(
                  key: ValueKey(_templates[i].id),
                  template: _templates[i].id,
                  controller: controller,
                ),
              ),
            ),
            _ActionBar(
              controller: controller,
              template: _currentTemplate,
              templateLabel: _currentLabel,
            ),
          ],
        ),
      ),
    );
  }

  void _goToTemplate(int index) {
    AppHaptics.tap();
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

/// En-tête : nom du template courant + dots indicateur + chips cliquables
/// pour sauter directement à un template sans avoir à swiper.
class _TemplateHeader extends StatelessWidget {
  const _TemplateHeader({
    required this.currentIndex,
    required this.currentLabel,
    required this.total,
    required this.onSelectIndex,
  });

  final int currentIndex;
  final String currentLabel;
  final int total;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      color: AppColors.background,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Template ${currentIndex + 1}/$total',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.bodyColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.bodyColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentLabel,
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () => onSelectIndex(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Page individuelle du PageView : charge les bytes PDF d'un template à
/// son apparition, les conserve dans le cache du controller, et affiche
/// via SfPdfViewer.memory (zoom + scroll natifs).
class _PdfTemplatePage extends StatefulWidget {
  const _PdfTemplatePage({
    super.key,
    required this.template,
    required this.controller,
  });

  final String template;
  final CvBuilderController controller;

  @override
  State<_PdfTemplatePage> createState() => _PdfTemplatePageState();
}

class _PdfTemplatePageState extends State<_PdfTemplatePage> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final bytes = await widget.controller.fetchCvPdfBytes(
      template: widget.template,
    );

    if (!mounted) return;

    if (bytes == null) {
      setState(() {
        _loading = false;
        _error = widget.controller.errorMessage.value.isNotEmpty
            ? widget.controller.errorMessage.value
            : 'Impossible de charger le PDF.';
      });
      return;
    }

    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.6,
        ),
      );
    }

    if (_error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: _load,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SfPdfViewer.memory(
            _bytes!,
            canShowScrollHead: false,
            canShowPaginationDialog: false,
            canShowScrollStatus: false,
          ),
        ),
      ),
    );
  }
}

/// Barre du bas avec deux actions : "Enregistrer comme mon CV" (marque le
/// template courant comme principal cote backend) et "Télécharger" (sheet
/// systeme de partage). Le premier passe en etat "✓ Mon CV" quand le
/// template courant est deja celui selectionne.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.controller,
    required this.template,
    required this.templateLabel,
  });

  final CvBuilderController controller;
  final String template;
  final String templateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Obx(() {
        final isSelected =
            controller.selectedTemplate.value == template;
        final isSelecting = controller.isSelectingTemplate.value;
        final isDownloading = controller.isDownloadingCv.value;

        return Row(
          children: [
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                onPressed: (isSelected || isSelecting)
                    ? null
                    : () => _onSelectTap(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  backgroundColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isSelecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    : Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.bookmark_add_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                label: Text(
                  isSelected ? 'Mon CV' : 'Enregistrer',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: FilledButton.icon(
                onPressed: isDownloading ? null : () => _onDownloadTap(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.55),
                  disabledForegroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.onPrimary),
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  isDownloading ? 'Préparation…' : 'Télécharger',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _onSelectTap(BuildContext context) async {
    AppHaptics.tap();
    final ok = await controller.selectTemplate(template);
    if (!context.mounted) return;
    if (ok) {
      AppHaptics.confirm();
      Get.snackbar(
        'Enregistré',
        'Le template « $templateLabel » est désormais votre CV principal.',
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 3),
      );
    } else {
      AppHaptics.error();
      Get.snackbar(
        'Erreur',
        controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : "Impossible d'enregistrer le template.",
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    AppHaptics.tap();
    final ok = await controller.downloadCvPdf(template: template);
    if (!context.mounted) return;
    if (!ok) {
      AppHaptics.error();
      Get.snackbar(
        'Téléchargement',
        controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : 'Échec du téléchargement.',
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }
}
