import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_provider.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../domain/entities/portfolio_item.dart';
import 'portfolio_controller.dart';

/// Ajout / édition d'un projet de portfolio. Reçoit un [PortfolioItem] via
/// `Get.arguments` pour le mode édition, sinon création.
class PortfolioEditController extends GetxController {
  PortfolioEditController(this._repository);

  final PortfolioRepository _repository;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final resultsCtrl = TextEditingController();
  final urlCtrl = TextEditingController();

  final type = PortfolioItemType.project.obs;
  final techStack = <String>[].obs;
  final pickedImages = <XFile>[].obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  String? _editingId;
  List<String> _existingMediaUrls = const [];
  bool get isEditing => _editingId != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is PortfolioItem) {
      _editingId = arg.id;
      type.value = arg.type;
      titleCtrl.text = arg.title;
      descCtrl.text = arg.description ?? '';
      resultsCtrl.text = arg.results ?? '';
      urlCtrl.text = arg.externalUrl ?? '';
      techStack.assignAll(arg.techStack);
      _existingMediaUrls = arg.mediaUrls;
    }
  }

  Future<void> pickImages() async {
    try {
      final imgs = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (imgs.isNotEmpty) pickedImages.addAll(imgs);
    } catch (_) {
      errorMessage.value = 'Galerie inaccessible. Vérifiez les autorisations.';
    }
  }

  void removePickedImage(int index) {
    if (index >= 0 && index < pickedImages.length) pickedImages.removeAt(index);
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    resultsCtrl.dispose();
    urlCtrl.dispose();
    super.onClose();
  }

  void addTech(String v) {
    final t = v.trim();
    if (t.isEmpty || techStack.contains(t)) return;
    techStack.add(t);
  }

  void removeTech(String v) => techStack.remove(v);

  /// Valide et sauvegarde (create ou update). Rafraîchit la liste si présente.
  Future<bool> save() async {
    if (isSaving.value) return false;
    if (titleCtrl.text.trim().isEmpty) {
      errorMessage.value = 'Le titre est obligatoire.';
      return false;
    }
    isSaving.value = true;
    errorMessage.value = null;

    final payload = <String, dynamic>{
      'item_type': type.value.apiValue,
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'results': resultsCtrl.text.trim(),
      if (urlCtrl.text.trim().isNotEmpty) 'external_url': urlCtrl.text.trim(),
      'tech_stack': techStack.toList(),
      // Préserve les images déjà attachées lors d'une édition.
      'media_urls': _existingMediaUrls,
    };

    try {
      final files = <ApiMultipartFile>[];
      for (final x in pickedImages) {
        files.add(ApiMultipartFile(
          field: 'media_uploads[]',
          bytes: await x.readAsBytes(),
          filename: x.name,
        ));
      }

      if (isEditing) {
        await _repository.update(_editingId!, payload, images: files);
      } else {
        await _repository.create(payload, images: files);
      }
      if (Get.isRegistered<PortfolioController>()) {
        await Get.find<PortfolioController>().load();
      }
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
