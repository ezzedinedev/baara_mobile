import 'dart:typed_data';

import '../../data/models/candidate_document_model.dart';

abstract class IDocumentRepository {
  Future<List<CandidateDocument>> list();
  Future<CandidateDocument> upload({
    required String type,
    required String title,
    required String filename,
    required List<int> bytes,
  });
  Future<void> delete(String id);

  /// Télécharge le fichier d'un document (GET /profile/documents/{id}/download).
  /// La route est protégée par Sanctum : on récupère les octets avec le Bearer
  /// plutôt que d'ouvrir `download_url` dans un navigateur (qui renverrait 401).
  Future<Uint8List> download(String id);
}
