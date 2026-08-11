import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../../../data/models/candidate_document_model.dart';
import '../../controllers/documents_controller.dart';
import '../../controllers/profile_controller.dart';

class ProfileDocumentsStrip extends StatelessWidget {
  const ProfileDocumentsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = Get.isRegistered<DocumentsController>()
        ? Get.find<DocumentsController>()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(
            title: 'Mes documents',
            actionLabel: 'Voir tout',
            onAction: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.profileDocuments);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 106,
          child: docs == null
              ? _list(const [ProfileAddDocCard()])
              : Obx(() {
                  if (docs.isLoading.value && docs.documents.isEmpty) {
                    return _list(const [
                      SkeletonBox(
                          height: 106, width: 124, radius: AppRadius.md),
                      SkeletonBox(
                          height: 106, width: 124, radius: AppRadius.md),
                      SkeletonBox(
                          height: 106, width: 124, radius: AppRadius.md),
                    ]);
                  }
                  if (docs.errorMessage.value != null &&
                      docs.documents.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: ErrorStateView(
                        message: docs.errorMessage.value!,
                        compact: true,
                        onRetry: docs.load,
                      ),
                    );
                  }
                  final items = docs.documents;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, i) {
                      if (i >= items.length) return const ProfileAddDocCard();
                      final doc = items[i];
                      return ProfileDocCard(
                        doc: doc,
                        onTap: () {
                          AppHaptics.tap();
                          docs.open(doc);
                        },
                      );
                    },
                  );
                }),
        ),
      ],
    );
  }

  Widget _list(List<Widget> children) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => children[i],
      );
}

class ProfileDocCard extends StatelessWidget {
  const ProfileDocCard({super.key, required this.doc, required this.onTap});

  final CandidateDocument doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.cardRadius,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              shape: AppShapes.cardBordered(
                AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                  ),
                  child: Icon(
                    doc.isImage ? AppIcons.image : AppIcons.document,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  doc.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.title.isEmpty ? doc.originalFilename : doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileAddDocCard extends StatelessWidget {
  const ProfileAddDocCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.profileDocuments);
      },
      child: SizedBox(
        width: 124,
        child: Container(
          decoration: ShapeDecoration(
            color: AppColors.surfaceLow,
            shape: AppShapes.cardBordered(
              AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.add, color: AppColors.primaryAccent, size: 26),
              const SizedBox(height: 6),
              Text(
                'Ajouter',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileCertificatesStrip extends StatelessWidget {
  const ProfileCertificatesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) return const SizedBox.shrink();
    final controller = Get.find<ProfileController>();
    return Obx(() {
      final items = controller.trainingCertificates;
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(title: 'Certificats'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => ProfileCertificateCard(item: items[i]),
            ),
          ),
        ],
      );
    });
  }
}

class ProfileCertificateCard extends StatelessWidget {
  const ProfileCertificateCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title = (item['training_title'] ??
            item['title'] ??
            item['name'] ??
            'Certificat')
        .toString();
    final issued = (item['issued_at'] ?? item['created_at'] ?? '').toString();
    return SizedBox(
      width: 176,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(
            AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
          shadows: AppColors.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.successAccent,
                size: 21,
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.titleColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (issued.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                issued,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
