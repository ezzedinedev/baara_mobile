import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';

/// Date proposée par le candidat pour reprogrammer un entretien, accompagnée
/// d'un message optionnel au recruteur.
class ProposedDate {
  const ProposedDate({required this.date, this.message});

  final DateTime date;
  final String? message;
}

/// Feuille de proposition de date : calendrier + heure + message. Remplace
/// l'enchaînement `showDatePicker` → `showTimePicker` → dialogue de message,
/// qui imposait trois écrans successifs pour une seule décision.
///
/// Retourne `null` si l'utilisateur ferme sans valider. Le backend exige une
/// date strictement future (`proposed_date` → `after:now`), d'où le refus des
/// créneaux passés.
Future<ProposedDate?> showProposeDateSheet({
  required BuildContext context,
  required String title,
}) {
  return showModalBottomSheet<ProposedDate>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ProposeDateSheet(title: title),
  );
}

class _ProposeDateSheet extends StatefulWidget {
  const _ProposeDateSheet({required this.title});
  final String title;

  @override
  State<_ProposeDateSheet> createState() => _ProposeDateSheetState();
}

class _ProposeDateSheetState extends State<_ProposeDateSheet> {
  late DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  DateTime get _combined =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  bool get _isFuture => _combined.isAfter(DateTime.now());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(topPadding: 0, bottomPadding: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('dd/MM/yyyy').format(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.schedule_rounded,
                  label: _time.format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          if (!_isFuture) ...[
            const SizedBox(height: 10),
            Text(
              'Choisissez un créneau à venir.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            maxLength: 1000,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Message au recruteur (optionnel)',
              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Annuler',
                      style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.bodyColor,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isFuture
                      ? () {
                          AppHaptics.tap();
                          Navigator.of(context).pop(ProposedDate(
                            date: _combined,
                            message: _messageCtrl.text.trim().isEmpty
                                ? null
                                : _messageCtrl.text.trim(),
                          ));
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Envoyer',
                      style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
