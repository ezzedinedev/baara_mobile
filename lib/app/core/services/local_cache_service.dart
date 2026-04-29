import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache disque generique pour le pattern stale-while-revalidate.
///
/// Stocke des payloads JSON (Map ou List) par cle, avec un timestamp
/// indiquant la fraicheur. Les controllers s'en servent pour hydrater
/// les ecrans **immediatement** au mount avec la derniere version connue,
/// puis revalident en background — feel WhatsApp/Instagram, pas de
/// spinner sur les ecrans deja visites.
///
/// Pas de TTL strict : on garde le cache jusqu'a ce qu'une nouvelle
/// reponse backend le remplace, ou que l'utilisateur logout (`clearAll`).
/// Les donnees obsoletes sont preferables a un ecran blanc.
class LocalCacheService {
  LocalCacheService._();

  static final LocalCacheService instance = LocalCacheService._();

  static const _prefix = 'cache_';
  static const _timestampSuffix = '_ts';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Lit un payload JSON deja parse (Map ou List). Retourne null si la
  /// cle n'existe pas ou si le JSON est corrompu (logge le warning).
  Future<dynamic> readJson(String key) async {
    final prefs = await _ensure();
    final raw = prefs.getString(_prefix + key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('[Cache] decode failed key=$key: $e');
      // Cache corrompu : on le purge pour eviter les retries en boucle.
      await prefs.remove(_prefix + key);
      return null;
    }
  }

  /// Convenience pour les payloads de type liste (offers, notifs, etc.).
  Future<List<dynamic>?> readList(String key) async {
    final value = await readJson(key);
    return value is List ? value : null;
  }

  /// Convenience pour les payloads de type map (profil, single resource).
  Future<Map<String, dynamic>?> readMap(String key) async {
    final value = await readJson(key);
    return value is Map<String, dynamic> ? value : null;
  }

  /// Ecrit un payload JSON-encodable. Best-effort : si SharedPreferences
  /// est plein ou plante, on log et on continue (l'app tourne sans cache).
  Future<void> writeJson(String key, Object value) async {
    try {
      final prefs = await _ensure();
      await prefs.setString(_prefix + key, jsonEncode(value));
      await prefs.setInt(
        _prefix + key + _timestampSuffix,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Cache] write failed key=$key: $e');
    }
  }

  /// Age du cache en duree. `null` si la cle n'existe pas.
  Future<Duration?> ageOf(String key) async {
    final prefs = await _ensure();
    final ts = prefs.getInt(_prefix + key + _timestampSuffix);
    if (ts == null) return null;
    return Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - ts);
  }

  /// Purge une cle precise.
  Future<void> clear(String key) async {
    final prefs = await _ensure();
    await prefs.remove(_prefix + key);
    await prefs.remove(_prefix + key + _timestampSuffix);
  }

  /// Purge tout le cache de l'app. A appeler au logout pour eviter qu'un
  /// nouvel utilisateur voit les donnees du precedent.
  Future<void> clearAll() async {
    final prefs = await _ensure();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_prefix)).toList(growable: false);
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

/// Cles de cache centralisees pour eviter les typos dispersees dans le
/// code. Chaque cle correspond a un payload backend specifique (la liste
/// ou le map qu'un controller attend).
class CacheKeys {
  CacheKeys._();

  // Offers module.
  static const offersList = 'offers_list_v1';
  static const featuredOffers = 'offers_featured_v1';
  static const savedOffers = 'offers_saved_v1';
  static const myApplications = 'applications_mine_v1';

  // Home / messaging / notifs.
  static const conversations = 'conversations_v1';
  static const notifications = 'notifications_v1';

  // Profile.
  static const userProfile = 'user_profile_v1';
}
