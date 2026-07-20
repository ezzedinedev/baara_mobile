/// Le candidat tente de postuler sans aucune compétence déclarée.
///
/// Ce n'est pas une erreur technique mais une décision produit : les
/// compétences pèsent 43 % du score de correspondance, donc sans elles la
/// candidature passe sous le seuil d'auto-filtre et se fait rejeter
/// automatiquement, sans qu'un recruteur ne la lise jamais. Autant l'arrêter
/// avant l'envoi et l'emmener compléter son CV.
class MissingSkillsException implements Exception {
  const MissingSkillsException(this.message);

  final String message;

  @override
  String toString() => message;
}
