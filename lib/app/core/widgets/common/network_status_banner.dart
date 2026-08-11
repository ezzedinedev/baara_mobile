import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/network_status_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Bandeau global hors-ligne, affiché sous la barre de statut.
class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NetworkStatusService>()) return child;

    final network = Get.find<NetworkStatusService>();
    return Obx(() {
      final offline = !network.isOnline.value;
      return Stack(
        children: [
          child,
          if (offline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: AppColors.errorAccent,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 18, color: AppColors.onPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hors ligne — certaines actions seront synchronisées plus tard',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
