import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

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
  late final TextEditingController bioController;

  /// Le formulaire n'est affiché (et enregistrable) qu'une fois le profil
  /// chargé : ouvert juste après l'inscription, il s'affichait vide alors
  /// que les informations existaient, et l'enregistrer envoyait des champs
  /// vides par-dessus.
  bool _filled = false;
  Worker? _profileWorker;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    jobController = TextEditingController();
    cityController = TextEditingController();
    bioController = TextEditingController();

    if (_controller.profile.value != null) {
      _fill();
    } else {
      _profileWorker = ever(_controller.profile, (_) {
        if (_controller.profile.value != null && mounted && !_filled) {
          setState(_fill);
        }
      });
      if (!_controller.isLoadingProfile.value) {
        _controller.fetchProfile();
      }
    }
  }

  void _fill() {
    final p = _controller.profile.value;
    if (p == null) return;
    firstNameController.text = p.firstName;
    lastNameController.text = p.lastName;
    phoneController.text = p.phone;
    emailController.text = p.email;
    jobController.text = p.headline ?? '';
    cityController.text = p.city;
    bioController.text = p.bio ?? '';
    _filled = true;
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    jobController.dispose();
    cityController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_filled) return;
    AppHaptics.tap();
    final ok = await _controller.updateProfile({
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'headline': jobController.text.trim(),
      'city': cityController.text.trim(),
      'bio': bioController.text.trim(),
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
        titleIcon: AppIcons.profile,
        onBack: Get.back,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (!_filled) {
              return Obx(() => _controller.errorMessage.value != null &&
                      !_controller.isLoadingProfile.value
                  ? ErrorStateView(
                      message: _controller.errorMessage.value!,
                      illustration: const ErrorIllustration(),
                      onRetry: _controller.fetchProfile,
                    )
                  : const Center(child: AppLoader()));
            }
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
                        icon: AppIcons.profile,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Nom',
                        controller: lastNameController,
                        icon: AppIcons.profile,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Numéro de téléphone',
                        controller: phoneController,
                        icon: AppIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Email',
                        controller: emailController,
                        icon: AppIcons.message,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Profession',
                        controller: jobController,
                        icon: AppIcons.work,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Ville',
                        controller: cityController,
                        icon: AppIcons.location,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Bio / À propos',
                        hint: 'Présentez-vous en quelques mots…',
                        controller: bioController,
                        icon: AppIcons.document,
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ParcoursTile(
                        onTap: () {
                          AppHaptics.tap();
                          Get.toNamed(AppRoutes.profileParcours);
                        },
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

/// Avatar initiales avec anneau halo doux, ombres en couches, squircle pill.
/// Conserve la logique d'initiales — visuel uniquement amélioré.
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo diffus (anneau doux, pas de blur)
        Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryAccent.withValues(alpha: 0.10),
          ),
        ),
        // Avatar principal avec ombres en couches
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              ...AppColors.lightShadow,
              ...AppColors.ambientShadow,
            ],
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.25),
              width: 2,
            ),
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
        ),
      ],
    );
  }
}

/// Entrée vers l'éditeur de parcours (expériences & formations).
/// Conteneur en squircle, Material requis pour l'InkWell, PressScale spring.
class _ParcoursTile extends StatelessWidget {
  const _ParcoursTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Material(
        color: AppColors.surfaceCard,
        // Squircle xl (rayon perçu 24) — cohérent avec les cartes du design 2026
        borderRadius: AppShapes.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.cardRadius,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              shape: AppShapes.cardBordered(
                AppColors.outlineVariant.withValues(alpha: 0.25),
              ),
              shadows: [
                ...AppColors.lightShadow,
                ...AppColors.ambientShadow,
              ],
            ),
            child: Row(
              children: [
                // Vignette squircle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: AppShapes.squircleRadius(AppRadius.md),
                  ),
                  child: Icon(AppIcons.work, color: AppColors.primaryAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expériences & formations',
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ajoutez ou modifiez votre parcours',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.hintColor),
                      ),
                    ],
                  ),
                ),
                const ListNavChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
