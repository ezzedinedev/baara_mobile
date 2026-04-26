part of '../cv_manual_editor_screen.dart';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: AppTextStyles.labelLg.copyWith(
              color: AppColors.titleColor,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ scalaire avec save au `onChanged` debounced.
class _ScalarField extends StatefulWidget {
  const _ScalarField({
    required this.controller,
    required this.field,
    required this.initialValue,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.isProfileField = false,
  });

  final CvBuilderController controller;
  final String field;
  final String initialValue;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  /// first_name / last_name sont stockés sur le User, pas le UserCv — mais
  /// l'API `update` ne les expose pas ici. Pour simplifier on les désactive
  /// côté éditeur manuel, et on guide l'utilisateur vers l'assistant IA.
  final bool isProfileField;

  @override
  State<_ScalarField> createState() => _ScalarFieldState();
}

class _ScalarFieldState extends State<_ScalarField> {
  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _lastSavedValue = widget.initialValue;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveIfChanged();
      }
    });
  }

  @override
  void dispose() {
    _saveIfChanged();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveIfChanged() async {
    if (widget.isProfileField) return;
    final current = _textCtrl.text.trim();
    if (current == _lastSavedValue.trim()) return;

    _lastSavedValue = current;
    final ok = await widget.controller.updateField(widget.field, current);
    if (!mounted) return;
    if (ok) {
      AppHaptics.success();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _textCtrl,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        enabled: !widget.isProfileField,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, color: AppColors.primary, size: 20),
          suffixIcon: widget.isProfileField
              ? Tooltip(
                  message:
                      'Modifiable depuis l\'assistant IA ou les paramètres du profil.',
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.hintColor,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.inputFill,
          labelStyle:
              AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

/// Champ pour éditer une liste de strings (skills, certifications…).
/// UI : chips ajoutables / supprimables + input pour ajouter.
class _TagListField extends StatefulWidget {
  const _TagListField({
    required this.controller,
    required this.field,
    required this.initialValues,
    required this.label,
    required this.hint,
    required this.color,
  });

  final CvBuilderController controller;
  final String field;
  final List<String> initialValues;
  final String label;
  final String hint;
  final Color color;

  @override
  State<_TagListField> createState() => _TagListFieldState();
}

class _TagListFieldState extends State<_TagListField> {
  late List<String> _values;
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _values = List.of(widget.initialValues);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    final ok = await widget.controller.updateField(widget.field, _values);
    if (!mounted) return;
    if (ok) AppHaptics.success();
  }

  void _add() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _values.contains(text)) return;
    setState(() {
      _values.add(text);
      _inputCtrl.clear();
    });
    _persist();
  }

  void _remove(String value) {
    setState(() => _values.remove(value));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppTextStyles.titleMd.copyWith(
              fontSize: 13,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          if (_values.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _values
                    .map((v) => Container(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 4,
                            top: 4,
                            bottom: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                v,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: widget.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  AppHaptics.tap();
                                  _remove(v);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.color.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: widget.color,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  onSubmitted: (_) => _add(),
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.bodySm.copyWith(
                      color: AppColors.hintColor,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Ajouter',
                onPressed: _add,
                icon: const Icon(Icons.add_circle_rounded),
                color: widget.color,
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplexSectionsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expériences, formations, projets, langues',
                  style: AppTextStyles.titleMd.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ces sections sont plus faciles à remplir avec l\'assistant IA — '
                  'il te pose une question à la fois et structure automatiquement.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
