import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../data/models/candidate_document_model.dart';
import '../controllers/documents_controller.dart';

/// Mes documents — liste synchronisée avec le backend (`/profile/documents`),
/// avec ouverture, suppression et upload (PDF/image) depuis le téléphone.
class DocumentsScreen extends GetView<DocumentsController> {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Get.back<void>()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mes documents',
                            style: AppTextStyles.titleLg
                                .copyWith(fontWeight: FontWeight.w800)),
                        Text('Diplômes, certificats, lettres…',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.hintColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.documents.isEmpty) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const SkeletonBox(height: 76, radius: 16),
                );
              }
              if (controller.errorMessage.value != null &&
                  controller.documents.isEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  onRetry: controller.load,
                );
              }
              if (controller.documents.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: IconlyLight.document,
                        title: 'Aucun document',
                        subtitle:
                            'Ajoutez vos diplômes, certificats et lettres. Ils sont '
                            'synchronisés avec votre espace et visibles partout.',
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = controller.documents[index];
                    return _DocumentCard(
                      doc: doc,
                      onOpen: () {
                        AppHaptics.tap();
                        controller.open(doc);
                      },
                      onDelete: () => _confirmDelete(context, doc),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Obx(() => GradientButton(
                label: 'AJOUTER UN DOCUMENT',
                isLoading: controller.isUploading.value,
                textColor: AppColors.onPrimary,
                height: 52,
                borderRadius: 14,
                onPressed: controller.isUploading.value
                    ? null
                    : () => _pickType(context),
              )),
        ),
      ),
    );
  }

  Future<void> _pickType(BuildContext context) async {
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Type de document',
                    style: AppTextStyles.titleLg
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            ...DocumentType.all.map(
              (t) => ListTile(
                leading: Icon(_iconFor(t.key), color: AppColors.primary),
                title: Text(t.label, style: AppTextStyles.titleMd),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.outlineVariant),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickAndUpload(t.key);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CandidateDocument doc) async {
    final ok = await showConfirmSheet(
      context: context,
      icon: IconlyLight.delete,
      iconColor: AppColors.error,
      title: 'Supprimer ce document ?',
      message: '« ${doc.title} » sera retiré de votre espace.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
    if (ok == true) {
      AppHaptics.confirm();
      controller.delete(doc);
    }
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'diploma':
      return IconlyBold.star;
    case 'certificate':
      return IconlyBold.shield_done;
    case 'cover_letter':
    case 'reference':
      return IconlyBold.document;
    default:
      return IconlyBold.paper;
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.onOpen,
    required this.onDelete,
  });

  final CandidateDocument doc;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  doc.isImage ? IconlyBold.image : IconlyBold.document,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title.isEmpty ? doc.originalFilename : doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        doc.typeLabel,
                        if (doc.sizeLabel.isNotEmpty) doc.sizeLabel,
                      ].join(' · '),
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(IconlyLight.delete, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
