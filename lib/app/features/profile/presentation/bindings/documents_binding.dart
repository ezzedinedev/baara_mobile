import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';

import '../../data/repositories/document_repository_impl.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../controllers/documents_controller.dart';

class DocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IDocumentRepository>(
      () => DocumentRepositoryImpl(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut(() => DocumentsController(Get.find<IDocumentRepository>()));
  }
}
