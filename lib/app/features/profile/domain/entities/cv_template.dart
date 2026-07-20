/// Un modèle de CV du catalogue serveur (`GET /profile/cv-builder/templates`).
///
/// Le catalogue n'est volontairement pas codé en dur côté mobile : il vit dans
/// `App\Support\CvTemplateCatalog` côté backend et sert aussi le web. C'est ce
/// qui garantit que les deux plateformes proposent les mêmes modèles.
class CvTemplate {
  const CvTemplate({
    required this.id,
    required this.label,
    required this.tone,
    required this.tier,
    required this.isPremium,
    required this.priceFcfa,
    required this.owned,
  });

  factory CvTemplate.fromJson(Map<String, dynamic> json) {
    return CvTemplate(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      tone: json['tone']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'base',
      isPremium: json['is_premium'] == true,
      priceFcfa: _asInt(json['price_fcfa']),
      owned: json['owned'] == true,
    );
  }

  final String id;
  final String label;
  final String tone;

  /// `base` | `enhanced` | `premium`.
  final String tier;
  final bool isPremium;
  final int priceFcfa;

  /// Vrai pour tout modèle gratuit, ou pour un premium déjà acheté.
  final bool owned;

  /// Le modèle est visible en aperçu mais son PDF est verrouillé.
  bool get isLocked => isPremium && !owned;

  CvTemplate copyWith({bool? owned}) => CvTemplate(
        id: id,
        label: label,
        tone: tone,
        tier: tier,
        isPremium: isPremium,
        priceFcfa: priceFcfa,
        owned: owned ?? this.owned,
      );

  static int _asInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
