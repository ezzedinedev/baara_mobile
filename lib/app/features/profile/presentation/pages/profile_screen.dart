import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile/profile_body.dart';
import '../widgets/profile/profile_states.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final profile = controller.profile.value;
        final isLoading = controller.isLoading.value;
        final errorMessage = controller.errorMessage.value;

        if (isLoading && profile == null) {
          return const ProfileSkeleton();
        }

        if (profile == null) {
          return ProfileErrorState(errorMessage: errorMessage ?? '');
        }

        return ProfileLoadedView(
          profile: profile,
          onRefresh: controller.fetchProfile,
        );
      }),
    );
  }
}
