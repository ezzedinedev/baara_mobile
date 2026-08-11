import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/widgets/widgets.dart';
import '../../controllers/profile_controller.dart';

class ProfileErrorState extends StatelessWidget {
  const ProfileErrorState({super.key, required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: Get.find<ProfileController>().fetchProfile,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: errorMessage.isNotEmpty
                ? ErrorStateView(
                    message: errorMessage,
                    illustration: const ErrorIllustration(),
                    onRetry: Get.find<ProfileController>().fetchProfile)
                : const EmptyState(
                    illustration: EmptyPeopleIllustration(),
                    title: 'Profil indisponible',
                    subtitle:
                        'Impossible de charger votre profil pour le moment.',
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        SkeletonBox(height: 250, width: double.infinity),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonBox(height: 180, radius: 24),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonBox(height: 200, radius: 24),
        ),
      ],
    );
  }
}
