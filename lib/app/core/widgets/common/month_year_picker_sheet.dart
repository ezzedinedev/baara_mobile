import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import '../auth/auth_cta_button.dart';

const kFrenchMonths = <String>[
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Valeur enregistrée pour un poste ou une formation toujours en cours.
const kPresentLabel = 'Présent';

/// « mars 2022 », ou « 2022 » sans mois. C'est le texte affiché tel quel sur
/// le CV ; le serveur y retrouve l'année pour compter l'expérience.
String formatMonthYear(int? month, int year) =>
    month == null ? '$year' : '${kFrenchMonths[month - 1]} $year';

/// Relit une valeur saisie (« mars 2022 », « 2022 », « 03/2022 »,
/// « Présent »). Les champs non reconnus restent `null`.
({int? month, int? year, bool present}) parseMonthYear(String? raw) {
  final text = (raw ?? '').trim().toLowerCase();
  if (text.isEmpty) return (month: null, year: null, present: false);
  if (const ['présent', 'present', 'en cours', "aujourd'hui", 'actuel']
      .any(text.contains)) {
    return (month: null, year: null, present: true);
  }
  final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(text);
  final year = yearMatch == null ? null : int.parse(yearMatch.group(0)!);
  int? month;
  // Noms complets d'abord, puis abréviations : « jui » seul ne permettrait
  // pas de distinguer juin de juillet.
  const abbreviations = <String>[
    'janv', 'fév', 'mars', 'avr', 'mai', 'juin', //
    'juil', 'aoû', 'sept', 'oct', 'nov', 'déc',
  ];
  const unaccented = <String>[
    'jan', 'fev', 'mar', 'avr', 'mai', 'jun', //
    'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
  ];
  for (final names in [kFrenchMonths, abbreviations, unaccented]) {
    for (var i = 0; i < names.length && month == null; i++) {
      if (text.contains(names[i])) month = i + 1;
    }
    if (month != null) break;
  }
  if (month == null) {
    final numeric = RegExp(r'^(\d{1,2})[/\-.]').firstMatch(text);
    final m = numeric == null ? null : int.tryParse(numeric.group(1)!);
    if (m != null && m >= 1 && m <= 12) month = m;
  }
  return (month: month, year: year, present: false);
}

/// Choix d'une date mois / année. Retourne le texte à enregistrer, `''` si
/// l'utilisateur efface la date, ou `null` s'il ferme sans valider.
Future<String?> showMonthYearPickerSheet({
  required BuildContext context,
  required String title,
  String? initial,
  bool allowPresent = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _MonthYearBody(
      title: title,
      initial: parseMonthYear(initial),
      allowPresent: allowPresent,
    ),
  );
}

class _MonthYearBody extends StatefulWidget {
  const _MonthYearBody({
    required this.title,
    required this.initial,
    required this.allowPresent,
  });

  final String title;
  final ({int? month, int? year, bool present}) initial;
  final bool allowPresent;

  @override
  State<_MonthYearBody> createState() => _MonthYearBodyState();
}

class _MonthYearBodyState extends State<_MonthYearBody> {
  static const _shortMonths = <String>[
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', //
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  late int? _month = widget.initial.month;
  late int? _year = widget.initial.year;
  late bool _present = widget.allowPresent && widget.initial.present;

  final _years = [
    for (var y = DateTime.now().year; y >= 1970; y--) y,
  ];

  bool get _valid => _present || _year != null;

  void _confirm() {
    AppHaptics.success();
    Navigator.of(context)
        .pop(_present ? kPresentLabel : formatMonthYear(_month, _year!));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.titleLg
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    child: Text(
                      'Effacer',
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.hintColor),
                    ),
                  ),
                ],
              ),
              if (widget.allowPresent) ...[
                const SizedBox(height: 8),
                _Chip(
                  label: 'En cours (aujourd\'hui)',
                  selected: _present,
                  onTap: () => setState(() => _present = !_present),
                ),
              ],
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _present ? 0.35 : 1,
                child: IgnorePointer(
                  ignoring: _present,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 18),
                      _Label('Mois (facultatif)'),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.2,
                        children: [
                          for (var m = 1; m <= 12; m++)
                            _Chip(
                              label: _shortMonths[m - 1],
                              selected: _month == m,
                              onTap: () => setState(
                                  () => _month = _month == m ? null : m),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _Label('Année'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 168,
                        child: GridView.count(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.2,
                          children: [
                            for (final y in _years)
                              _Chip(
                                label: '$y',
                                selected: _year == y,
                                onTap: () => setState(() => _year = y),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              AuthCtaButton(
                label: 'Valider',
                onPressed: _valid ? _confirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.labelLg.copyWith(color: AppColors.bodyColor),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceLow,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.labelMd.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.titleColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
