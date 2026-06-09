import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/utils/validators.dart';

class RecruiterLoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final isLoading = false.obs;

  void login() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    isLoading.value = false;
    Get.snackbar('Recruteur', 'Redirection vers la plateforme web...');
  }

  String? validateEmail(String? v) => Validators.email(v);
}
