/// Offre recommandée par le moteur de matching IA (`GET /ai/match/feed`).
/// Sous-ensemble léger d'une offre + score de compatibilité (0–100) et
/// explication. Le tap ouvre le détail complet via l'id.
class MatchedOffer {
  final String id;
  final String title;
  final String company;
  final String location;

  /// Score de compatibilité normalisé sur 0–100.
  final int score;

  /// Courte explication IA du match (peut être vide).
  final String explanation;

  const MatchedOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.score,
    this.explanation = '',
  });
}
