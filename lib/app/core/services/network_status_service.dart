import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// État réseau global observable (connectivité appareil).
class NetworkStatusService extends GetxService {
  final isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    unawaited(_refresh());
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = results.any((r) => r != ConnectivityResult.none);
    });
  }

  Future<void> _refresh() async {
    try {
      final results = await Connectivity().checkConnectivity();
      isOnline.value = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      isOnline.value = true;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
