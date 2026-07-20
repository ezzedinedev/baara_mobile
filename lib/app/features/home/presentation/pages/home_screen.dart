import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/features/community/presentation/pages/community_feed_screen.dart';
import 'package:jobaway/app/features/profile/presentation/pages/profile_screen.dart';
import 'package:jobaway/app/features/suivi/presentation/pages/suivi_screen.dart';
import '../controllers/home_controller.dart';
import 'opportunites_screen.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_dashboard_tab.dart';
import '../widgets/home_lazy_tab_stack.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Le contenu passe SOUS la barre glass (effet verre).
      extendBody: true,
      body: Obx(
        () => HomeLazyTabStack(
          index: controller.currentTabIndex.value,
          children: const [
            HomeDashboardTab(),
            OpportunitesScreen(),
            CommunityFeedScreen(),
            SuiviScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: const HomeBottomNav(),
    );
  }
}
