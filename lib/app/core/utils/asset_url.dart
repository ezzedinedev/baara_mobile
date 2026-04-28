import '../constants/api_constants.dart';


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
