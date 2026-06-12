import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

class AppThemeController extends GetxController {
  static const _themeKey = 'app_theme_mode';
  static const _amoledKey = 'app_theme_amoled';
  static const _accentKey = 'app_theme_accent';

  final isDarkMode = false.obs;

  /// Noir intense (AMOLED) : ne s'applique qu'en mode sombre. Assombrit les
  /// surfaces de fond jusqu'au vrai noir pour les écrans OLED.
  final amoled = false.obs;

  /// Couleur d'accent de PREMIER-PLAN choisie par l'utilisateur (nav active,
  /// liens, icônes, bordures…). Stockée en ARGB int. Défaut = vert de marque.
  final accentSeed = AppColors.primary.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getString(_themeKey) == 'dark';
    amoled.value = prefs.getBool(_amoledKey) ?? false;
    final storedAccent = prefs.getInt(_accentKey);
    if (storedAccent != null) accentSeed.value = Color(storedAccent);
    _applySystemOverlay();
  }

  Future<void> toggle() => setDarkMode(!isDarkMode.value);

  /// Aligne le thème sur la préférence renvoyée par le serveur (`GET /profile`)
  /// pour une synchro multi-appareils. No-op si déjà aligné — évite tout
  /// clignotement quand la pref locale et le serveur coïncident (cas courant).
  Future<void> syncFromServer(String? themePref) async {
    if (themePref == null) return;
    final serverDark = themePref.toLowerCase() == 'dark';
    if (serverDark == isDarkMode.value) return;
    await setDarkMode(serverDark);
  }

  Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    Get.changeThemeMode(themeMode);
    // CRITIQUE : les couleurs viennent de getters `AppColors` relus AU BUILD
    // (pas de `Theme.of(context)`). `changeThemeMode` n'anime que le ThemeData ;
    // les écrans gardés en cache (onglets IndexedStack, routes empilées) ne se
    // reconstruisent pas → thème incohérent (« pas tout en même temps »).
    // `forceAppUpdate` marque TOUS les éléments dirty (même les sous-arbres
    // const) → bascule clair/sombre instantanée et cohérente partout.
    Get.forceAppUpdate();
    _applySystemOverlay();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value ? 'dark' : 'light');
  }

  /// Active/désactive le noir intense (AMOLED). N'a d'effet visuel qu'en dark,
  /// mais la préférence est mémorisée quel que soit le mode courant.
  Future<void> setAmoled(bool value) async {
    if (amoled.value == value) return;
    amoled.value = value;
    // Les tokens de surface (AppColors) sont relus au build ; on force un
    // rebuild global comme pour le changement de thème (le ThemeMode lui ne
    // change pas ici). Le main Obx observe `amoled` → reconstruit l'app.
    Get.forceAppUpdate();
    _applySystemOverlay();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, value);
  }

  /// Change l'accent de premier-plan de l'app. Persiste la valeur ARGB et
  /// rafraîchit l'UI en direct (mêmes getters dark-aware relus au build).
  Future<void> setAccent(Color value) async {
    if (accentSeed.value.toARGB32() == value.toARGB32()) return;
    accentSeed.value = value;
    Get.forceAppUpdate();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, value.toARGB32());
  }

  void _applySystemOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode.value ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDarkMode.value ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
