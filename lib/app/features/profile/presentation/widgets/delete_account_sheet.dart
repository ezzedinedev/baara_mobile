import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';

/// Ouvre la confirmation de suppression définitive du compte.
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

/// Action destructive et irréversible : on dit précisément ce qui disparaît,
/// on exige une confirmation saisie (mot de passe, ou « SUPPRIMER » pour un
/// compte créé avec Google) et le bouton reste rouge, distinct de toute
/// action de marque.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _input.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Saisissez votre mot de passe (ou SUPPRIMER).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    AppHaptics.confirm();
    final error = await Get.find<ProfileController>().deleteAccount(value);
    if (!mounted) return;
    if (error == null) {
      AppToast.success('Compte supprimé', 'Vos données personnelles ont été effacées.');
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: AppShapes.squircleRadius(14),
                  ),
                  child: Icon(AppIcons.delete,
                      color: AppColors.errorAccent, size: 24),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(
                    'Supprimer mon compte ?',
                    style: AppTextStyles.headlineMd
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette action est définitive. Seront effacés : votre profil, '
                  'vos CV et documents, vos candidatures, vos messages, vos '
                  'publications et vos formations suivies.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mot de passe',
                  style: AppTextStyles.titleMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _input,
                  obscureText: true,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Votre mot de passe',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compte créé avec Google ? Saisissez SUPPRIMER.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.hintColor),
                ),
                const SizedBox(height: 22),
                AuthCtaButton(
                  label: 'Supprimer définitivement',
                  trailing: null,
                  backgroundColor: AppColors.errorStrong,
                  isLoading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.bodyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
