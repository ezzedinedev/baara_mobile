/// Formatage monétaire pour la zone UEMOA.
///
/// Le backend renvoie des décimaux Laravel (`350000.00`) : les afficher bruts
/// donne « 350000.00 - 600000.00 XOF », illisible et trop long pour les cartes
/// d'info. On arrondit à l'unité — le franc CFA n'a pas de subdivision en
/// usage — et on groupe les milliers.
library;

/// Espace insécable (U+00A0) : évite qu'un montant se coupe en fin de ligne
/// (« 350 » / « 000 ») dans les cartes étroites.
///
/// Échappé volontairement : un insécable littéral est invisible à la relecture
/// et se fait silencieusement « corriger » en espace normal par un éditeur.
const String nbsp = '\u00A0';

/// Nom d'usage de la devise. `XOF` est le code ISO, mais personne n'écrit
/// « 350 000 XOF » en Afrique de l'Ouest.
String currencyLabel(String? code) {
  final c = (code ?? '').trim().toUpperCase();
  if (c.isEmpty || c == 'XOF' || c == 'CFA') return 'FCFA';
  return c;
}

/// `350000.00` → `350 000`. Rend null si la valeur n'est pas un nombre.
String? formatAmount(dynamic value) {
  final amount = _toNum(value);
  if (amount == null) return null;
  final whole = amount.round().abs().toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}$nbsp',
  );
  return amount < 0 ? '-$grouped' : grouped;
}

/// `350000.00` → `350 000 FCFA`.
String? formatMoney(dynamic value, {String? currency}) {
  final amount = formatAmount(value);
  if (amount == null) return null;
  return '$amount$nbsp${currencyLabel(currency)}';
}

/// Fourchette compacte : la devise n'est écrite qu'une fois.
/// `350000.00`, `600000.00` → `350 000 – 600 000 FCFA`.
String? formatMoneyRange(dynamic min, dynamic max, {String? currency}) {
  final lo = formatAmount(min);
  final hi = formatAmount(max);
  final unit = currencyLabel(currency);
  if (lo != null && hi != null) {
    // Fourchette dégénérée (min == max) : un seul montant, pas « X – X ».
    if (lo == hi) return '$lo$nbsp$unit';
    return '$lo – $hi$nbsp$unit';
  }
  if (lo != null) return 'À partir de $lo$nbsp$unit';
  if (hi != null) return 'Jusqu\'à $hi$nbsp$unit';
  return null;
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString().trim());
}
