import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../controllers/profile_controller.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ProfileController _controller = Get.find<ProfileController>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController jobController;
  late final TextEditingController cityController;

  @override
  void initState() {
    super.initState();
    final p = _controller.profile.value;
    firstNameController = TextEditingController(text: p?.firstName ?? '');
    lastNameController = TextEditingController(text: p?.lastName ?? '');
    phoneController = TextEditingController(text: p?.phone ?? '');
    emailController = TextEditingController(text: p?.email ?? '');
    jobController = TextEditingController(text: p?.headline ?? '');
    cityController = TextEditingController(text: p?.city ?? '');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    jobController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    AppHaptics.tap();
    final ok = await _controller.updateProfile({
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'headline': jobController.text.trim(),
      'city': cityController.text.trim(),
    });
    if (ok) {
      AppToast.success('Profil mis à jour');
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SankSheetScaffold(
        title: 'Modifier le profil',
        titleIcon: IconlyLight.profile,
        onBack: Get.back,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth > 720 ? 640.0 : double.infinity;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 34),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      _ProfileInitials(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AuthTextField(
                        label: 'Prénoms',
                        controller: firstNameController,
                        icon: IconlyLight.profile,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Nom',
                        controller: lastNameController,
                        icon: IconlyLight.profile,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Numéro de téléphone',
                        controller: phoneController,
                        icon: IconlyLight.call,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Email',
                        controller: emailController,
                        icon: IconlyLight.message,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Profession',
                        controller: jobController,
                        icon: IconlyLight.work,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Ville',
                        controller: cityController,
                        icon: IconlyLight.location,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Obx(() => AuthCtaButton(
                            label: 'Mettre à jour mon profil',
                            isLoading: _controller.isSavingProfile.value,
                            onPressed: _save,
                          )),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  String get _initials {
    final f = firstName.trim();
    final l = lastName.trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    final res = '$a$b'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: AppColors.ambientShadow,
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTextStyles.displayLg.copyWith(
            color: AppColors.onPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
