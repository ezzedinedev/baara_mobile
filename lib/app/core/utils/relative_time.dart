/// Renvoie un libellé "il y a X" en français.
/// Renvoie chaîne vide si `dateTime` est null.
/// Exemples : "À l'instant", "il y a 5 min", "il y a 2 h", "il y a 3 j",
/// "il y a 2 sem", "il y a 5 mois", "il y a 1 an".
String relativeTimeFr(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
  if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
  return 'il y a ${(diff.inDays / 365).floor()} an${(diff.inDays / 365).floor() > 1 ? 's' : ''}';
}
