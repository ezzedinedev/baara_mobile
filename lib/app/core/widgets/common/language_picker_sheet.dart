import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import '../auth/auth_cta_button.dart';

/// Langues proposées en premier : celles du Burkina et de la sous-région,
/// puis les langues internationales les plus demandées par les recruteurs.
const kCommonLanguages = <String>[
  'Français',
  'Anglais',
  'Mooré',
  'Dioula',
  'Fulfuldé',
  'Gourmantché',
  'Bissa',
  'Dagara',
  'Lobiri',
  'Bambara',
  'Haoussa',
  'Arabe',
  'Espagnol',
  'Allemand',
  'Portugais',
  'Chinois',
];

/// Niveaux en mots simples : les codes A1 à C2 ne parlent pas à tout le
/// monde, et ne s'appliquent pas aux langues nationales.
const kLanguageLevels = <String>[
  'Débutant',
  'Intermédiaire',
  'Courant',
  'Bilingue',
  'Langue maternelle',
];

/// Choix d'une langue et de son niveau, par sélection. « Autre langue »
/// permet de saisir une langue absente de la liste.
Future<({String name, String level})?> showLanguagePickerSheet({
  required BuildContext context,
  Iterable<String> exclude = const [],
}) {
  final taken = exclude.map((e) => e.trim().toLowerCase()).toSet();
  final options =
      kCommonLanguages.where((l) => !taken.contains(l.toLowerCase())).toList();

  return showModalBottomSheet<({String name, String level})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => _LanguagePickerBody(options: options),
  );
}

class _LanguagePickerBody extends StatefulWidget {
  const _LanguagePickerBody({required this.options});
  final List<String> options;

  @override
  State<_LanguagePickerBody> createState() => _LanguagePickerBodyState();
}

class _LanguagePickerBodyState extends State<_LanguagePickerBody> {
  static const _other = '__other__';
  final _otherCtrl = TextEditingController();
  String? _language;
  String? _level;

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  String get _name =>
      _language == _other ? _otherCtrl.text.trim() : (_language ?? '');

  bool get _canSubmit => _name.isNotEmpty && _level != null;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: SingleChildScrollView(
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
              Text(
                'Ajouter une langue',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _Label('Langue'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in widget.options)
                    _Choice(
                      label: l,
                      selected: _language == l,
                      onTap: () => setState(() => _language = l),
                    ),
                  _Choice(
                    label: 'Autre langue',
                    selected: _language == _other,
                    onTap: () => setState(() => _language = _other),
                  ),
                ],
              ),
              if (_language == _other) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otherCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Nom de la langue',
                    hintStyle: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.hintColor),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _Label('Niveau'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final lv in kLanguageLevels)
                    _Choice(
                      label: lv,
                      selected: _level == lv,
                      onTap: () => setState(() => _level = lv),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              AuthCtaButton(
                label: 'Ajouter',
                onPressed: _canSubmit
                    ? () {
                        AppHaptics.success();
                        Navigator.of(context)
                            .pop((name: _name, level: _level!));
                      }
                    : null,
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLg.copyWith(color: AppColors.bodyColor),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.titleColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
