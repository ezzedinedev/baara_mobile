import 'package:get/get.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  // Stubs for compatibility with FcmService
  final activeConversationId = RxnString();
  void loadConversations() {}
  void loadConversationThread(String id) {}

  void changeTab(int index) {
    currentTabIndex.value = index;
  }
}
