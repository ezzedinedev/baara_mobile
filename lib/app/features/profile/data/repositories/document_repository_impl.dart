import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';

import '../../domain/repositories/i_document_repository.dart';
import '../models/candidate_document_model.dart';

class DocumentRepositoryImpl implements IDocumentRepository {
  DocumentRepositoryImpl({required ApiProvider apiProvider})
      : _api = apiProvider;

  final ApiProvider _api;

  @override
  Future<List<CandidateDocument>> list() async {
    final response = await _api.getJson(ApiConstants.profileDocuments);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos documents.');
    return ApiResponse.extractList(response['data'])
        .whereType<Map<String, dynamic>>()
        .map(CandidateDocument.fromJson)
        .toList();
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Échec de l\'envoi du document.');
    return CandidateDocument.fromJson(ApiResponse.dataMap(response));
  }

  @override
  Future<void> delete(String id) async {
    final response = await _api.deleteJson(ApiConstants.profileDocument(id));
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de supprimer ce document.');
  }

  @override
  Future<Uint8List> download(String id) {
    return _api.getBytes(
      ApiConstants.profileDocumentDownload(id),
      // Tous les documents ne sont pas des PDF (photos de diplômes, images) :
      // on n'impose pas `Accept: application/pdf` comme pour le CV.
      headers: const {'Accept': '*/*'},
    );
  }
}
