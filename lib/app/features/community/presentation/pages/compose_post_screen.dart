import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/profile_controller.dart';
import '../controllers/community_controller.dart';

/// Composer de publication plein écran (style Threads/Instagram) : texte,
/// images (galerie multi), document PDF, emojis, catégorie et visibilité.
/// S'appuie sur le support média déjà présent (`publish(mediaPaths:)`).
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _controller = Get.find<CommunityController>();
  final _text = TextEditingController();
  final _focus = FocusNode();

  final _images = <XFile>[];
  String? _pdfPath;
  String? _pdfName;

  String _category = 'general';
  String _visibility = 'public';
  bool _showEmojis = false;

  static const _maxImages = 10;
  static const _emojis = [
    '😀', '😂', '😍', '🥰', '👍', '🙏', '🔥', '🎉', '❤️', '😎',
    '🤝', '💪', '✨', '😊', '🙌', '👏', '💯', '🚀', '📢', '✅',
  ];
  static const _categories = {
    'general': 'Général',
    'emploi': 'Offre',
    'formation': 'Formation',
    'article': 'Article',
    'evenement': 'Événement',
  };

  bool get _canPublish =>
      _text.text.trim().isNotEmpty || _images.isNotEmpty || _pdfPath != null;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    AppHaptics.tap();
    try {
      final imgs = await ImagePicker()
          .pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (imgs.isEmpty) return;
      setState(() {
        for (final img in imgs) {
          if (_images.length >= _maxImages) break;
          _images.add(img);
        }
        _pdfPath = null; // image et PDF mutuellement exclusifs côté affichage
        _pdfName = null;
      });
    } catch (_) {
      AppToast.error('Galerie inaccessible', 'Vérifiez les autorisations.');
    }
  }

  Future<void> _pickPdf() async {
    AppHaptics.tap();
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (_) {
      AppToast.error('Sélecteur indisponible', 'Vérifiez les autorisations.');
      return;
    }
    final path = result?.files.firstOrNull?.path;
    if (path == null) return;
    setState(() {
      _pdfPath = path;
      _pdfName = result?.files.first.name ?? 'Document.pdf';
      _images.clear();
    });
  }

  void _insertEmoji(String emoji) {
    final value = _text.value;
    final sel = value.selection;
    final start = sel.start >= 0 ? sel.start : value.text.length;
    final end = sel.end >= 0 ? sel.end : value.text.length;
    final newText = value.text.replaceRange(start, end, emoji);
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    setState(() {});
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    AppHaptics.tap();
    final paths = <String>[
      ..._images.map((x) => x.path),
      if (_pdfPath != null) _pdfPath!,
    ];
    final ok = await _controller.publish(
      body: _text.text.trim(),
      category: _category,
      visibility: _visibility,
      mediaPaths: paths,
    );
    if (ok) {
      AppToast.success('Publié', 'Votre publication est en ligne.');
      if (mounted) Get.back<void>();
    } else {
      AppToast.error('Échec', 'La publication n\'a pas pu être envoyée.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>().profile.value
        : null;
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName
        : 'Vous';
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.titleColor),
          onPressed: () => Get.back<void>(),
        ),
        title: Text('Nouvelle publication',
            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Obx(() => TextButton(
                    onPressed: (_canPublish && !_controller.isPublishing.value)
                        ? _publish
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: _canPublish
                          ? AppColors.primary
                          : AppColors.surfaceLow,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: _controller.isPublishing.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Publier',
                            style: AppTextStyles.labelLg.copyWith(
                              color: _canPublish
                                  ? AppColors.onPrimary
                                  : AppColors.hintColor,
                              fontWeight: FontWeight.w800,
                            )),
                  )),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              children: [
                // Auteur
                Row(
                  children: [
                    BrandAvatar(
                        seed: profile?.email ?? name,
                        label: name,
                        size: 44,
                        imageUrl: profile?.avatarUrl),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMd
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _chipsRow(),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _text,
                  focusNode: _focus,
                  autofocus: true,
                  minLines: 4,
                  maxLines: null,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyLg
                      .copyWith(color: AppColors.titleColor, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Quoi de neuf ?',
                    hintStyle: AppTextStyles.bodyLg
                        .copyWith(color: AppColors.hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_images.isNotEmpty) _imagePreviews(),
                if (_pdfName != null) _pdfPreview(),
              ],
            ),
          ),
          if (_showEmojis) _emojiBar(),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _chipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _selectChip(
            icon: _visibility == 'public'
                ? Icons.public_rounded
                : Icons.people_alt_rounded,
            label: _visibility == 'public' ? 'Public' : 'Mes relations',
            onTap: () => setState(() => _visibility =
                _visibility == 'public' ? 'connections' : 'public'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _selectChip(
            icon: Icons.sell_outlined,
            label: _categories[_category] ?? 'Général',
            onTap: _pickCategory,
          ),
        ],
      ),
    );
  }

  void _pickCategory() {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            for (final entry in _categories.entries)
              ListTile(
                title: Text(entry.value, style: AppTextStyles.titleMd),
                trailing: _category == entry.key
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _category = entry.key);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectChip(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.titleColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _imagePreviews() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.file(
                  File(_images[i].path),
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(i)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close_rounded,
                        size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pdfPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(_pdfName ?? 'Document.pdf',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg
                      .copyWith(color: AppColors.titleColor)),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _pdfPath = null;
                _pdfName = null;
              }),
              child: Icon(Icons.close_rounded, color: AppColors.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiBar() {
    return Container(
      height: 54,
      color: AppColors.surfaceLow,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _emojis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Center(
          child: GestureDetector(
            onTap: () => _insertEmoji(_emojis[i]),
            child: Text(_emojis[i], style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          children: [
            _toolBtn(Icons.image_outlined, 'Galerie', _pickImages),
            _toolBtn(Icons.attach_file_rounded, 'Document', _pickPdf),
            _toolBtn(
              Icons.emoji_emotions_outlined,
              'Emoji',
              () => setState(() => _showEmojis = !_showEmojis),
              active: _showEmojis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap,
      {bool active = false}) {
    final color = active ? AppColors.primary : AppColors.bodyColor;
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color),
        label: Text(label,
            style: AppTextStyles.labelMd.copyWith(color: color)),
      ),
    );
  }
}
