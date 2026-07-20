/// Pays + indicatif téléphonique pour le sélecteur de numéro.
///
/// Marché cible = zone UEMOA (Afrique de l'Ouest, franc CFA) : on liste les
/// 8 États membres. Le drapeau est un emoji (aucun asset à charger), et
/// [dialCode] alimente le préfixe international du champ téléphone.
class PhoneCountry {
  const PhoneCountry({
    required this.isoCode,
    required this.flag,
    required this.name,
    required this.dialCode,
  });

  /// Code ISO 3166-1 alpha-2 (ex. `BF`).
  final String isoCode;

  /// Drapeau emoji (ex. 🇧🇫).
  final String flag;

  /// Nom localisé (fr) du pays.
  final String name;

  /// Indicatif international avec `+` (ex. `+226`).
  final String dialCode;

  /// Les 8 États membres de l'UEMOA, triés par nom.
  static const List<PhoneCountry> uemoa = <PhoneCountry>[
    PhoneCountry(isoCode: 'BJ', flag: '🇧🇯', name: 'Bénin', dialCode: '+229'),
    PhoneCountry(
        isoCode: 'BF', flag: '🇧🇫', name: 'Burkina Faso', dialCode: '+226'),
    PhoneCountry(
        isoCode: 'CI', flag: '🇨🇮', name: "Côte d'Ivoire", dialCode: '+225'),
    PhoneCountry(
        isoCode: 'GW', flag: '🇬🇼', name: 'Guinée-Bissau', dialCode: '+245'),
    PhoneCountry(isoCode: 'ML', flag: '🇲🇱', name: 'Mali', dialCode: '+223'),
    PhoneCountry(isoCode: 'NE', flag: '🇳🇪', name: 'Niger', dialCode: '+227'),
    PhoneCountry(isoCode: 'SN', flag: '🇸🇳', name: 'Sénégal', dialCode: '+221'),
    PhoneCountry(isoCode: 'TG', flag: '🇹🇬', name: 'Togo', dialCode: '+228'),
  ];

  /// Pays par défaut (Burkina Faso) — utilisé quand aucun choix n'est fait.
  static const PhoneCountry fallback = PhoneCountry(
      isoCode: 'BF', flag: '🇧🇫', name: 'Burkina Faso', dialCode: '+226');

  /// Retrouve un pays par son [isoCode], ou [fallback] si absent.
  static PhoneCountry byIso(String isoCode) {
    for (final c in uemoa) {
      if (c.isoCode == isoCode) return c;
    }
    return fallback;
  }
}
