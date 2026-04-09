import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/opportune_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const OpportuneLogo(iconSize: 16, fontSize: 18),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.bodyColor,
              size: 20,
            ),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.lightShadow,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.onPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Connexion réussie !',
                style: AppTextStyles.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Votre tableau de bord arrive bientôt.',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    await prefs.remove('auth_token');
    await prefs.remove('user_type');
    await secureStorage.delete(key: 'auth_token');
    Get.offAllNamed(AppRoutes.profileSelection);
  }
}
