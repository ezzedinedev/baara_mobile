import '../constants/api_constants.dart';


/// initials, etc.) si l'URL renvoie 404.
String resolveAssetUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return ApiConstants.resolveMediaUrl(trimmed) ?? trimmed;
  }
  final host = ApiConstants.resolvedHost;
  if (trimmed.startsWith('/')) {
    return '$host$trimmed';
  }
  return '$host/storage/$trimmed';
}
