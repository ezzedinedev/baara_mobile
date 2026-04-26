import '../constants/api_constants.dart';

/// Resoud un chemin d'asset renvoye par le backend en URL absolue.
///
/// Cas geres :
///   1. URL deja absolue (`http://...`, `https://...`) → retour tel quel
///   2. Chemin commencant par `/` (deja prefixe `/storage/...`) → host + path
///   3. Chemin nu Laravel `Storage::disk('public')` (ex: `formations/abc.jpg`)
///      → host + `/storage/` + path. C'est le format par defaut renvoye par
///      les colonnes `*_path` (image_path, avatar_url, certificate_logo_path).
///
/// Renvoie chaine vide si `value` est vide. Ne valide PAS l'existence du
/// fichier — c'est au site d'appel de gerer un fallback (placeholder image,
/// initials, etc.) si l'URL renvoie 404.
String resolveAssetUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final host = ApiConstants.resolvedHost;
  if (trimmed.startsWith('/')) {
    return '$host$trimmed';
  }
  // Chemin nu = stockage public Laravel. Prefixer avec /storage/ pour matcher
  // l'URL servie par Nginx via le symlink storage:link.
  return '$host/storage/$trimmed';
}
