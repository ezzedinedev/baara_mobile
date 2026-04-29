import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_cache_service.dart';

class AuthTokenStore {
  const AuthTokenStore({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : _secureStorage = secureStorage;

  static const _tokenKey = 'auth_token';
  static const _userTypeKey = 'user_type';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveSession({
    required String token,
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.setString(_userTypeKey, userType);
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String> readToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey)?.trim() ?? '';
    if (legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
      return legacyToken;
    }

    throw Exception('Session introuvable. Veuillez vous reconnecter.');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userTypeKey);
    await _secureStorage.delete(key: _tokenKey);
    // Purge le cache disque pour eviter qu'un nouvel utilisateur sur ce
    // device voie les donnees (offres, candidatures, conversations) de
    // l'utilisateur precedent au prochain login.
    await LocalCacheService.instance.clearAll();
  }
}
