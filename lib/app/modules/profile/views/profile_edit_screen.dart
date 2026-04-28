import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/controllers/home_profile_manager.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final HomeProfileManager _manager;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _skillsCtrl;

  @override
  void initState() {
    super.initState();
    _manager = Get.find<HomeController>().profileManager;
    final p = _manager.profile.value;
    _firstNameCtrl = TextEditingController(text: p.firstName);
    _lastNameCtrl = TextEditingController(text: p.lastName);
    _emailCtrl = TextEditingController(text: p.email);
    _phoneCtrl = TextEditingController(text: p.phone);
    _cityCtrl = TextEditingController(text: p.city);
    _regionCtrl = TextEditingController(text: p.region);
    _headlineCtrl = TextEditingController(text: p.headline);
    _summaryCtrl = TextEditingController(text: p.summary);
    _skillsCtrl = TextEditingController(text: p.skills.join(', '));
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    _headlineCtrl.dispose();
    _summaryCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  List<String> _splitSkills(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      AppHaptics.error();
      return;
    }

    try {
      await _manager.saveProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        region: _regionCtrl.text.trim(),
        headline: _headlineCtrl.text.trim(),
        summary: _summaryCtrl.text.trim(),
        skills: _splitSkills(_skillsCtrl.text),
      );
      if (!mounted) return;
      Get.back();
      AppToast.success(
        'Profil mis a jour',
        'Vos informations ont ete enregistrees.',
      );
    } on Exception catch (error) {
      AppToast.error(
        'Erreur',
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WavyAuthHeader(
              height: 200,
              showLeading: true,
              onLeadingTap: () => Get.back(),
              foregroundIcon: Icons.edit_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier mon profil',
                      style: AppTextStyles.displayMd.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 48,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mettez a jour vos informations personnelles et professionnelles.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(label: 'Identite'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            label: 'Prenom',
                            icon: Icons.person_outline_rounded,
                            controller: _firstNameCtrl,
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuthTextField(
                            label: 'Nom',
                            icon: Icons.person_outline_rounded,
                            controller: _lastNameCtrl,
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(label: 'Coordonnees'),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Telephone',
                      icon: Icons.phone_outlined,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: _required,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            label: 'Ville',
                            icon: Icons.location_city_outlined,
                            controller: _cityCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuthTextField(
                            label: 'Region',
                            icon: Icons.map_outlined,
                            controller: _regionCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(label: 'Profil professionnel'),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Accroche',
                      icon: Icons.flash_on_outlined,
                      controller: _headlineCtrl,
                      hint: 'Developpeur Flutter passionne...',
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Resume',
                      icon: Icons.short_text_rounded,
                      controller: _summaryCtrl,
                      hint: 'Quelques lignes pour vous presenter',
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Competences',
                      icon: Icons.bolt_outlined,
                      controller: _skillsCtrl,
                      hint: 'Flutter, Dart, Firebase, ...',
                      helper: 'Separez les competences par une virgule.',
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () => AuthCtaButton(
                        label: _manager.isSavingProfile.value
                            ? 'ENREGISTREMENT...'
                            : 'ENREGISTRER',
                        isLoading: _manager.isSavingProfile.value,
                        onPressed:
                            _manager.isSavingProfile.value ? null : _onSave,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Annuler',
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.bodyColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
