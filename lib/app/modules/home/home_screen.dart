import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/utils/haptics.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/widgets.dart';
import 'home_controller.dart';
import 'home_formation_detail_page.dart';
import 'home_profile_tab.dart';

part 'home_screen_parts/accueil_tab.dart';
part 'home_screen_parts/header_nav.dart';
part 'home_screen_parts/tabs.dart';
part 'home_screen_parts/messaging.dart';
part 'home_screen_parts/offer_match_overlay.dart';
part 'home_screen_parts/offer_tinder_deck.dart';
part 'home_screen_parts/offer_deck_card.dart';
part 'home_screen_parts/formation_cards.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();

    return Obx(
      () {
        themeController.isDarkMode.value;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Obx(
                  () => IndexedStack(
                    index: controller.currentTabIndex.value,
                    children: [
                      _AccueilTab(controller: controller),
                      _MessagerieTab(controller: controller),
                      _OffresTab(controller: controller),
                      _FormationsTab(controller: controller),
                      HomeProfileTab(controller: controller),
                    ],
                  ),
                ),
                _OfferMatchOverlay(controller: controller),
                _MessagingOverlay(controller: controller),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Obx(
                () => _HomeBottomNav(
                  items: controller.navItems,
                  currentIndex: controller.currentTabIndex.value,
                  onTap: (index) {
                    AppHaptics.tap();
                    controller.changeTab(index);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

