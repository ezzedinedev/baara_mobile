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
}
