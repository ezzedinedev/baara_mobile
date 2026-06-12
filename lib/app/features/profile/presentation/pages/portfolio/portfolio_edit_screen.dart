import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../controllers/portfolio_edit_controller.dart';
import '../../../domain/entities/portfolio_item.dart';

/// Ajout / édition d'un projet de portfolio — câblé à l'API (POST/PUT).
class PortfolioEditScreen extends GetView<PortfolioEditController> {
  const PortfolioEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold fournit l'ancêtre Material pour tous les TextField/InkWell.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title:
                controller.isEditing ? 'Modifier le projet' : 'Nouveau projet',
            subtitle: 'Valorisez une réalisation de votre portfolio',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const _Label('Type'),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PortfolioItemType.values
                          .map((t) => _TypeChip(
                                type: t,
                                selected: controller.type.value == t,
                                onTap: () => controller.type.value = t,
                              ))
                          .toList(),
                    )),
                const SizedBox(height: 18),
                _Field(
                    label: 'Titre *',
                    ctrl: controller.titleCtrl,
                    hint: 'Ex : Application mobile e-commerce'),
                _Field(
                    label: 'Description',
                    ctrl: controller.descCtrl,
                    hint: 'Le projet, votre rôle, le contexte…',
                    maxLines: 5),
                _Field(
                    label: 'Résultats',
                    ctrl: controller.resultsCtrl,
                    hint: 'Impact, chiffres, reconnaissance…',
                    maxLines: 3),
                _Field(
                    label: 'Lien (optionnel)',
                    ctrl: controller.urlCtrl,
                    hint: 'https://…',
                    keyboard: TextInputType.url,
                    isLast: true),
                const SizedBox(height: 18),
                const _Label('Technologies'),
                const SizedBox(height: 8),
                _TechEditor(controller: controller),
                const SizedBox(height: 18),
                const _Label('Photos'),
                const SizedBox(height: 8),
                _PhotosEditor(controller: controller),
                Obx(() {
                  final err = controller.errorMessage.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(err,
                        style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.errorAccent, height: 1.4)),
                  );
                }),
              ],
            ),
          ),
          _SaveBar(controller: controller),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.labelMd.copyWith(
            color: AppColors.titleColor, fontWeight: FontWeight.w700));
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.type, required this.selected, required this.onTap});
  final PortfolioItemType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSelected : AppColors.surfaceLow,
          borderRadius: AppShapes.pill,
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.surfaceLow,
            width: 1.4,
          ),
        ),
        child: Text(type.label,
            style: AppTextStyles.labelMd.copyWith(
              color: selected ? AppColors.primaryAccent : AppColors.bodyColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            )),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboard,
    this.isLast = false,
  });
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboard;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // TextField est dans un Scaffold → Material ancêtre garanti.
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechEditor extends StatefulWidget {
  const _TechEditor({required this.controller});
  final PortfolioEditController controller;
  @override
  State<_TechEditor> createState() => _TechEditorState();
}

class _TechEditorState extends State<_TechEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    AppHaptics.tap();
    widget.controller.addTech(v);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => widget.controller.techStack.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.controller.techStack
                      .map((t) => Container(
                            padding: const EdgeInsets.only(
                                left: 12, right: 6, top: 6, bottom: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppShapes.pill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t,
                                    style: AppTextStyles.labelMd.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    AppHaptics.tap();
                                    widget.controller.removeTech(t);
                                  },
                                  child: Icon(IconlyLight.close_square,
                                      size: 16, color: AppColors.onPrimary),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              )),
        Row(
          children: [
            Expanded(
              // TextField dans Scaffold → Material ancêtre présent.
              child: TextField(
                controller: _ctrl,
                style: AppTextStyles.bodyMd,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: 'Ajouter une techno…',
                  hintStyle:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PressScale(
              onTap: _add,
              child: Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: AppColors.primary,
                  shape: AppShapes.squircle(AppRadius.sm),
                ),
                child: const Icon(IconlyLight.plus, color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotosEditor extends StatelessWidget {
  const _PhotosEditor({required this.controller});
  final PortfolioEditController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final imgs = controller.pickedImages;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < imgs.length; i++)
            _Thumb(
              path: imgs[i].path,
              onRemove: () {
                AppHaptics.tap();
                controller.removePickedImage(i);
              },
            ),
          PressScale(
            onTap: () {
              AppHaptics.tap();
              controller.pickImages();
            },
            child: Container(
              width: 84,
              height: 84,
              decoration: ShapeDecoration(
                color: AppColors.surfaceLow,
                shape: AppShapes.squircle(AppRadius.sm,
                    side: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.camera,
                      color: AppColors.primaryAccent, size: 22),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.onRemove});
  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppShapes.squircleRadius(AppRadius.sm),
          child: Image.file(
            File(path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.onDark.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(IconlyLight.close_square,
                  size: 14, color: AppColors.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.controller});
  final PortfolioEditController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: AppColors.lightShadow,
      ),
      child: SafeArea(
        top: false,
        child: Obx(() => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final ok = await controller.save();
                        if (ok) {
                          AppToast.success(controller.isEditing
                              ? 'Projet mis à jour'
                              : 'Projet ajouté');
                          Get.back<void>();
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.onPrimary),
                        ),
                      )
                    : Text('Enregistrer',
                        style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800)),
              ),
            )),
      ),
    );
  }
}
