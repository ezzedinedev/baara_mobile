import 'package:http/http.dart' as http;

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

import '../../domain/repositories/i_document_repository.dart';
import '../models/candidate_document_model.dart';

class DocumentRepositoryImpl implements IDocumentRepository {
  DocumentRepositoryImpl({required ApiProvider apiProvider})
      : _api = apiProvider;

  final ApiProvider _api;

  @override
  Future<List<CandidateDocument>> list() async {
    final response = await _api.getJson(ApiConstants.profileDocuments);
    if (response['success'] == true) {
      final data = response['data'];
      final List<dynamic> items = data is List ? data : (data?['data'] ?? []);
      return items
          .whereType<Map<String, dynamic>>()
          .map(CandidateDocument.fromJson)
          .toList();
    }
    return [];
  }

  @override
  Future<CandidateDocument> upload({
    required String type,
    required String title,
    required String filename,
    required List<int> bytes,
  }) async {
    final response = await _api.multipartPost(
      ApiConstants.profileDocuments,
      fields: {
        'type': type,
        if (title.trim().isNotEmpty) 'title': title.trim(),
      },
      files: [
        http.MultipartFile.fromBytes('document', bytes, filename: filename),
      ],
    );
    if (response['success'] == true && response['data'] != null) {
      return CandidateDocument.fromJson(
          response['data'] as Map<String, dynamic>);
    }
    throw Exception(response['message'] ?? "Échec de l'envoi du document.");
  }

  @override
  Future<void> delete(String id) async {
    final response = await _api.deleteJson(ApiConstants.profileDocument(id));
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Suppression impossible.');
    }
  }
}
