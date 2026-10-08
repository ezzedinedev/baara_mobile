import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/services/biometric_service.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';

import 'auth/auth_cta_button.dart';
import 'baara_mark.dart';

/// Écran plein affiché tant que l'app est verrouillée. Lance la demande
/// d'empreinte dès l'ouverture ; ne se ferme qu'avec `true` (déverrouillé)
/// ou `false` (l'utilisateur préfère se déconnecter).
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !Get.isRegistered<BiometricService>()) return;
    setState(() => _busy = true);
    final ok = await Get.find<BiometricService>().authenticate();
    if (!mounted) return;
    if (ok) {
      AppHaptics.success();
      Get.back(result: true);
      return;
    }
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: BaaraMark.brandForest,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Container(
                    width: 112,
                    height: 112,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: BaaraMark.brandLime.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const BaaraMark(
                      size: 56,
                      color: Colors.white,
                      headColor: BaaraMark.brandLime,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Baara est verrouillé',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMd
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _failed
                        ? 'Déverrouillage annulé ou non reconnu. Réessayez.'
                        : 'Utilisez votre empreinte, votre visage ou le code '
                            'de votre téléphone.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const Spacer(flex: 4),
                  AuthCtaButton(
                    label: 'Déverrouiller',
                    trailing: Icons.fingerprint_rounded,
                    isLoading: _busy,
                    backgroundColor: BaaraMark.brandLime,
                    foregroundColor: BaaraMark.brandForest,
                    onPressed: _unlock,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : () => Get.back(result: false),
                    child: Text(
                      'Se déconnecter',
                      style: AppTextStyles.labelLg.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
