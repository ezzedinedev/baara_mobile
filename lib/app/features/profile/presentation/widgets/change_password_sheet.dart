import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/profile_controller.dart';

/// Changement de mot de passe sans code : mot de passe actuel puis nouveau.
/// « Mot de passe oublié ? » reste proposé à qui ne connaît plus l'actuel.
Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _localCheck() {
    if (_current.text.isEmpty) return 'Saisissez votre mot de passe actuel.';
    if (_password.text.length < 8) {
      return 'Le nouveau mot de passe doit contenir au moins 8 caractères.';
    }
    if (_password.text != _confirmation.text) {
      return 'Les deux nouveaux mots de passe ne correspondent pas.';
    }
    return null;
  }

  Future<void> _submit() async {
    final local = _localCheck();
    if (local != null) {
      AppHaptics.error();
      setState(() => _error = local);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await Get.find<ProfileController>().changePassword(
      current: _current.text,
      password: _password.text,
      confirmation: _confirmation.text,
    );
    if (!mounted) return;
    if (error == null) {
      AppHaptics.success();
      Navigator.of(context).pop();
      AppToast.success(
        'Mot de passe modifié',
        'Vos autres appareils ont été déconnectés.',
      );
      return;
    }
    AppHaptics.error();
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  void _forgot() {
    final email = Get.find<ProfileController>().profile.value?.email ?? '';
    Navigator.of(context).pop();
    Get.toNamed(
      AppRoutes.forgotPassword,
      arguments: email.isEmpty ? null : {'email': email},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: AppShapes.pill,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMedium.withValues(alpha: 0.14),
                      borderRadius: AppShapes.squircleRadius(14),
                    ),
                    child: const Icon(AppIcons.password,
                        color: AppColors.primaryMedium, size: 24),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(
                    'Changer le mot de passe',
                    style: AppTextStyles.headlineMd
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vos autres appareils seront déconnectés par sécurité.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.bodyColor, height: 1.45),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Mot de passe actuel',
                  icon: AppIcons.lock,
                  controller: _current,
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _forgot,
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.primaryMedium),
                    ),
                  ),
                ),
                AuthTextField(
                  label: 'Nouveau mot de passe',
                  hint: 'Au moins 8 caractères',
                  icon: AppIcons.password,
                  controller: _password,
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'Confirmer le nouveau mot de passe',
                  icon: AppIcons.password,
                  controller: _confirmation,
                  obscureText: true,
                ),
                AuthErrorBanner(message: _error ?? ''),
                const SizedBox(height: 22),
                AuthCtaButton(
                  label: 'Enregistrer',
                  isLoading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
