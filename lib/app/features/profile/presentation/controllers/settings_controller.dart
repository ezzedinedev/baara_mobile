import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:opportune_bf/app/core/theme/app_theme_controller.dart';
import 'package:opportune_bf/app/translations/app_translations.dart';

import '../../domain/entities/profile.dart';
import 'profile_controller.dart';

/// Pilote l'écran Paramètres. Centralise les préférences utilisateur de façon
/// **réactive** et **persistée** :
/// - état hydraté depuis [SharedPreferences] à l'ouverture (les bascules
///   reflètent donc le dernier choix réel, plus de valeurs codées en dur) ;
/// - chaque changement est écrit en local immédiatement puis poussé au backend
///   (PUT /profile/preferences) ; en cas d'échec serveur, on revient en arrière.
///
/// Le thème et la langue gardent leurs sources réactives dédiées
/// ([AppThemeController] / `Get.locale`) pour l'affichage ; ce controller ne
/// fait que router leurs mutations pour rester l'unique point d'entrée.
class SettingsController extends GetxController {
  SettingsController(this._profile);

  final ProfileController _profile;

  static const _kNotifEnabled = 'pref_notifications_enabled';
  static const _kNetworkActivity = 'pref_network_activity';
  static const _kProfileVisibility = 'pref_profile_visibility';
  static const _channelKeyPrefix = 'pref_channel_';

  /// Canaux de notification granulaires (clés = clés backend).
  static const notifChannels = <String>[
    'offer_updates',
    'application_updates',
    'match_alerts',
    'message_alerts',
    'training_updates',
  ];

  final notificationsEnabled = true.obs;
  final networkActivity = false.obs;

  /// Visibilité du profil communauté : 'public' | 'connections'.
  final profileVisibility = 'public'.obs;
  final notifPrefs = <String, bool>{
    for (final k in notifChannels) k: true,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    // 1) Cache local : affichage instantané, fonctionne hors-ligne.
    _hydrateFromCache();
    // 2) Serveur = source de vérité : applique le profil dès qu'il est chargé
    //    (déjà présent ou via fetchProfile), puis à chaque rafraîchissement.
    _applyFromProfile(_profile.profile.value);
    ever<Profile?>(_profile.profile, _applyFromProfile);
  }

  Future<void> _hydrateFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled.value = prefs.getBool(_kNotifEnabled) ?? true;
    networkActivity.value = prefs.getBool(_kNetworkActivity) ?? false;
    profileVisibility.value = prefs.getString(_kProfileVisibility) ?? 'public';
    for (final k in notifChannels) {
      notifPrefs[k] = prefs.getBool('$_channelKeyPrefix$k') ?? true;
    }
    notifPrefs.refresh();
  }

  /// Applique les préférences renvoyées par le serveur (`GET /profile`) et
  /// rafraîchit le cache local pour qu'il reste aligné.
  void _applyFromProfile(Profile? profile) {
    if (profile == null) return;
    notificationsEnabled.value = profile.notificationsEnabled;
    networkActivity.value = profile.teamActivity;
    profileVisibility.value = profile.profileVisibility;
    for (final k in notifChannels) {
      notifPrefs[k] = profile.notificationChannels[k] ?? notifPrefs[k] ?? true;
    }
    notifPrefs.refresh();

    _setLocal(_kNotifEnabled, notificationsEnabled.value);
    _setLocal(_kNetworkActivity, networkActivity.value);
    _setLocalString(_kProfileVisibility, profileVisibility.value);
    for (final k in notifChannels) {
      _setLocal('$_channelKeyPrefix$k', notifPrefs[k] ?? true);
    }
  }

  Future<void> _setLocal(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setLocalString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Bascule maître des notifications.
  Future<void> setNotificationsEnabled(bool value) async {
    final previous = notificationsEnabled.value;
    notificationsEnabled.value = value;
    await _setLocal(_kNotifEnabled, value);
    final ok =
        await _profile.updatePreferences({'notifications_enabled': value});
    if (!ok) {
      notificationsEnabled.value = previous;
      await _setLocal(_kNotifEnabled, previous);
    }
  }

  /// Bascule d'un canal de notification précis.
  Future<void> setChannel(String key, bool value) async {
    final previous = notifPrefs[key] ?? true;
    notifPrefs[key] = value;
    await _setLocal('$_channelKeyPrefix$key', value);
    final ok = await _profile.updatePreferences({key: value});
    if (!ok) {
      notifPrefs[key] = previous;
      await _setLocal('$_channelKeyPrefix$key', previous);
    }
  }

  /// Activité du réseau (abonnés, mentions, publications).
  Future<void> setNetworkActivity(bool value) async {
    final previous = networkActivity.value;
    networkActivity.value = value;
    await _setLocal(_kNetworkActivity, value);
    final ok = await _profile.updatePreferences({'team_activity': value});
    if (!ok) {
      networkActivity.value = previous;
      await _setLocal(_kNetworkActivity, previous);
    }
  }

  /// Visibilité du profil communauté ('public' | 'connections'). Optimiste +
  /// rollback : on bascule localement, on persiste via PUT /profile, et on
  /// revient en arrière si le serveur échoue.
  Future<void> setProfileVisibility(String value) async {
    final previous = profileVisibility.value;
    if (previous == value) return;
    profileVisibility.value = value;
    await _setLocalString(_kProfileVisibility, value);
    final ok = await _profile.setProfileVisibility(value);
    if (!ok) {
      profileVisibility.value = previous;
      await _setLocalString(_kProfileVisibility, previous);
    }
  }

  /// Thème clair/sombre — délègue la persistance locale + l'application au
  /// [AppThemeController], et pousse la préférence au backend (best-effort).
  Future<void> setDarkMode(bool value) async {
    final theme = Get.find<AppThemeController>();
    await theme.setDarkMode(value);
    await _profile.updatePreferences({'theme': value ? 'dark' : 'light'});
  }

  /// Noir intense (AMOLED) — délègue au [AppThemeController] (persistance
  /// locale + rebuild live). Préférence purement locale (pas de champ backend).
  Future<void> setAmoled(bool value) async {
    await Get.find<AppThemeController>().setAmoled(value);
  }

  /// Accent de premier-plan de l'app — délègue au [AppThemeController]
  /// (persistance locale ARGB + rebuild live). Préférence locale.
  Future<void> setAccent(Color value) async {
    await Get.find<AppThemeController>().setAccent(value);
  }

  /// Langue de l'application — applique la locale et pousse au backend.
  Future<void> setLanguage(String code) async {
    applyAppLocale(code);
    await _profile.updatePreferences({'language': code});
  }
}
