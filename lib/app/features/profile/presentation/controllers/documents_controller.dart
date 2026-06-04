import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';

import '../../data/models/candidate_document_model.dart';
import '../../domain/repositories/i_document_repository.dart';

/// Gère la liste des documents du candidat (synchro backend), l'upload et la
/// suppression. Synchronisé avec `/profile/documents`.
class DocumentsController extends GetxController {
  DocumentsController(this._repository);

  final IDocumentRepository _repository;

  final documents = <CandidateDocument>[].obs;
  final isLoading = true.obs;
  final isUploading = false.obs;
  final deletingId = RxnString();
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      documents.assignAll(await _repository.list());
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Sélectionne un fichier (PDF/image) et l'envoie avec le [type] choisi.
  Future<void> pickAndUpload(String type) async {
    if (isUploading.value) return;

    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
    } catch (_) {
      AppToast.error('Sélecteur indisponible', 'Vérifiez les autorisations.');
      return;
    }
    if (result == null || result.files.isEmpty) return; // annulé

    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) {
      AppToast.error('Fichier illisible', 'Réessayez avec un autre fichier.');
      return;
    }

    isUploading.value = true;
    try {
      final doc = await _repository.upload(
        type: type,
        title: '',
        filename: picked.name,
        bytes: bytes,
      );
      documents.insert(0, doc);
      AppToast.success('Document ajouté', picked.name);
    } catch (e) {
      AppToast.error('Envoi impossible', userFacingError(e));
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> delete(CandidateDocument doc) async {
    if (deletingId.value != null) return;
    final index = documents.indexWhere((d) => d.id == doc.id);
    if (index == -1) return;

    // Optimiste : retrait immédiat, réinsertion si l'appel échoue.
    deletingId.value = doc.id;
    documents.removeAt(index);
    try {
      await _repository.delete(doc.id);
    } catch (e) {
      documents.insert(index > documents.length ? documents.length : index, doc);
      AppToast.error('Suppression échouée', userFacingError(e));
    } finally {
      deletingId.value = null;
    }
  }

  /// Ouvre le document (téléchargement backend) dans une appli externe.
  Future<void> open(CandidateDocument doc) async {
    final url = doc.downloadUrl.trim();
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null) {
      AppToast.error('Lien indisponible', 'Impossible d\'ouvrir ce document.');
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      AppToast.error('Ouverture impossible', 'Aucune appli ne peut l\'ouvrir.');
    }
  }
}
