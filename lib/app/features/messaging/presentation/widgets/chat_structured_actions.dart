import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:intl/intl.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/widgets.dart';

import '../../domain/entities/message.dart';

/// Boutons d'action sous une bulle reçue portant un `meta_json` (invitation
/// d'entretien, contre-proposition de date, offre d'emploi). Parité avec les
/// boutons du web : mêmes actions, mêmes couleurs sémantiques.
///
/// N'affiche rien si le message n'a pas d'action — le backend retire `actions`
/// dès que l'entretien est clos, ce qui suffit à faire disparaître les boutons.
class ChatStructuredActions extends StatelessWidget {
  const ChatStructuredActions({
    super.key,
    required this.message,
    required this.onAction,
    required this.isBusy,
  });

  final Message message;
  final ValueChanged<MessageAction> onAction;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final meta = message.meta;
    if (meta == null || !message.hasActions) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.proposedDate != null) ...[
          const SizedBox(height: 10),
          _ProposedDateBanner(date: meta.proposedDate!),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final action in meta.actions)
              _ActionButton(
                action: action,
                enabled: !isBusy,
                onTap: () => onAction(action),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProposedDateBanner extends StatelessWidget {
  const _ProposedDateBanner({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Format numérique : `intl` n'a pas de données de locale chargées dans
    // l'app (aucun `initializeDateFormatting`), un motif `EEEE`/`MMMM` lèverait
    // une LocaleDataException. Même rendu que le web (`toLocaleDateString('fr-FR')`).
    final label = DateFormat("dd/MM/yyyy 'à' HH:mm").format(date.toLocal());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.calendar, size: 14, color: AppColors.primaryAccent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Date proposée : $label',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.enabled,
    required this.onTap,
  });

  final MessageAction action;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _style(action);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: PressScale(
        scale: 0.94,
        onTap: enabled ? onTap : () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: color.withValues(alpha: 0.38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (String, IconData, Color) _style(MessageAction action) {
    return switch (action) {
      MessageAction.accept => (
          'Accepter',
          AppIcons.tickSquare,
          AppColors.successAccent
        ),
      MessageAction.acceptNewDate => (
          'Accepter la date',
          AppIcons.tickSquare,
          AppColors.successAccent
        ),
      MessageAction.decline => (
          'Décliner',
          Icons.close_rounded,
          AppColors.errorAccent
        ),
      MessageAction.refuse => (
          'Refuser',
          Icons.close_rounded,
          AppColors.errorAccent
        ),
      MessageAction.reschedule => (
          'Reprogrammer',
          AppIcons.time,
          AppColors.warningAccent
        ),
      MessageAction.proposeOther => (
          'Proposer une autre date',
          AppIcons.time,
          AppColors.warningAccent
        ),
      MessageAction.negotiate => (
          'Négocier',
          AppIcons.chat,
          AppColors.primaryAccent
        ),
    };
  }
}
