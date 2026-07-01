import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

class AppThemeController extends GetxController with WidgetsBindingObserver {
  static const _themeKey = 'app_theme_mode'; // legacy : 'dark' | 'light'
  static const _themeSourceKey =
      'app_theme_source'; // 'system' | 'light' | 'dark'
  static const _amoledKey = 'app_theme_amoled';
  static const _accentKey = 'app_theme_accent';

  /// Brightness résolue effectivement appliquée (lue par les getters AppColors).
  final isDarkMode = false.obs;

  /// Source du thème choisie par l'utilisateur :
  /// - `system` → suit la luminosité de l'OS (réactif aux changements) ;
  /// - `light` / `dark` → forcé par l'utilisateur.
  final themeSource = 'light'.obs;

  /// Noir intense (AMOLED) : ne s'applique qu'en mode sombre. Assombrit les
  /// surfaces de fond jusqu'au vrai noir pour les écrans OLED.
  final amoled = false.obs;

  /// Couleur d'accent de PREMIER-PLAN choisie par l'utilisateur (nav active,
  /// liens, icônes, bordures…). Stockée en ARGB int. Défaut = vert de marque.
  final accentSeed = AppColors.primary.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// Luminosité courante de l'OS (pour le mode « Système »).
  bool get _platformIsDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  @override
  void onInit() {
    super.onInit();
    // Écoute les changements de thème système (n'agit qu'en mode « Système »).
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Déclenché par l'OS quand l'utilisateur bascule clair/sombre au niveau
  /// système. En mode « Système », on réaligne l'app en direct.
  @override
  void didChangePlatformBrightness() {
    if (themeSource.value != 'system') return;
    final dark = _platformIsDark;
    if (dark == isDarkMode.value) return;
    isDarkMode.value = dark;
    Get.changeThemeMode(themeMode);
    Get.forceAppUpdate();
    _applySystemOverlay();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Source : nouvelle clé, avec repli sur l'ancienne ('dark'/'light').
    final source = prefs.getString(_themeSourceKey) ??
        (prefs.getString(_themeKey) == 'dark' ? 'dark' : 'light');
    themeSource.value = source;
    isDarkMode.value = source == 'system' ? _platformIsDark : source == 'dark';
    amoled.value = prefs.getBool(_amoledKey) ?? false;
    final storedAccent = prefs.getInt(_accentKey);
    if (storedAccent != null) accentSeed.value = Color(storedAccent);
    _applySystemOverlay();
  }

  Future<void> toggle() => setDarkMode(!isDarkMode.value);

  /// Aligne le thème sur la préférence renvoyée par le serveur (`GET /profile`)
  /// pour une synchro multi-appareils. No-op si déjà aligné, ou si l'utilisateur
  /// a explicitement choisi « Système » (on respecte alors l'OS).
  Future<void> syncFromServer(String? themePref) async {
    if (themePref == null || themeSource.value == 'system') return;
    final serverDark = themePref.toLowerCase() == 'dark';
    if (serverDark == isDarkMode.value) return;
    await setDarkMode(serverDark);
  }

  /// Bascule binaire clair/sombre (toggles rapides). Force la source explicite.
  Future<void> setDarkMode(bool value) =>
      setThemeSource(value ? 'dark' : 'light');

  /// Définit la source du thème : 'system' | 'light' | 'dark'. En 'system', la
  /// luminosité suit l'OS (et reste réactive via [didChangePlatformBrightness]).
  Future<void> setThemeSource(String source) async {
    if (source != 'system' && source != 'light' && source != 'dark') {
      source = 'light';
    }
    themeSource.value = source;
    isDarkMode.value = source == 'system' ? _platformIsDark : source == 'dark';
    Get.changeThemeMode(themeMode);
    // CRITIQUE : les couleurs viennent de getters `AppColors` relus AU BUILD
    // (pas de `Theme.of(context)`). `changeThemeMode` n'anime que le ThemeData ;
    // les écrans gardés en cache (onglets IndexedStack, routes empilées) ne se
    // reconstruisent pas → thème incohérent. `forceAppUpdate` marque TOUS les
    // éléments dirty → bascule instantanée et cohérente partout.
    Get.forceAppUpdate();
    _applySystemOverlay();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeSourceKey, source);
    await prefs.setString(_themeKey, isDarkMode.value ? 'dark' : 'light');
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
