import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/map_navigation.dart';
import 'package:opportune_bf/app/core/services/offline_apply_queue.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';

import '../../data/models/application_model.dart';
import '../../data/models/interview_detail_model.dart';
import '../../data/models/job_proposal_model.dart';
import '../../data/models/upcoming_interview_model.dart';
import '../controllers/applications_controller.dart';
import 'applications_pipeline_view.dart';

/// Liste des candidatures du candidat : statut, offre visée, score de
/// matching et entretien éventuel. Données via [ApplicationsController].
///
/// Deux modes de visualisation locaux : liste verticale (par défaut) ou
/// pipeline kanban en colonnes par statut, basculables via le toggle du
/// header.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final ApplicationsController controller = Get.find<ApplicationsController>();

  /// false = liste verticale ; true = pipeline kanban. État purement local
  /// (aucune route dédiée).
  bool _pipelineMode = false;

  void _setMode(bool pipeline) {
    if (_pipelineMode == pipeline) return;
    AppHaptics.tap();
    setState(() => _pipelineMode = pipeline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Mes candidatures',
            subtitle: 'Suivez l\'avancement de vos postulations',
            height: 230,
            gradient: AppColors.heroOffersGradient,
            onLeadingTap: () => Get.back(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ViewModeToggle(
                pipeline: _pipelineMode,
                onChanged: _setMode,
              ),
            ),
          ),
          Expanded(
            child: _pipelineMode
                ? const ApplicationsPipelineView()
                : _ApplicationsListView(controller: controller),
          ),
        ],
      ),
    );
  }
}

/// Toggle Liste ↔ Pipeline (deux segments d'icônes).
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.pipeline, required this.onChanged});
  final bool pipeline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            icon: IconlyLight.document,
            selected: !pipeline,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 4),
          _ToggleSegment(
            icon: Icons.view_column_rounded,
            selected: pipeline,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        // Bascule de segment en ressort (langage motion 2026).
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.onPrimary : AppColors.hintColor,
        ),
      ),
    );
  }
}

/// Contenu en mode liste verticale (comportement historique de l'écran).
class _ApplicationsListView extends StatelessWidget {
  const _ApplicationsListView({required this.controller});
  final ApplicationsController controller;

  @override
  Widget build(BuildContext context) {
    final queue = Get.find<OfflineApplyQueue>();
    return Obx(() {
      if (controller.isLoading.value) {
        return const _ApplicationsSkeleton();
      }
      if (controller.errorMessage.value != null) {
        return ErrorStateView(
          message: controller.errorMessage.value!,
          illustration: const ErrorIllustration(),
          onRetry: controller.load,
        );
      }
      // Candidatures postees hors-ligne, en attente de renvoi (persistent).
      final pending = queue.pending.toList();
      if (controller.applications.isEmpty &&
          pending.isEmpty &&
          controller.interviews.isEmpty &&
          controller.jobProposals.isEmpty &&
          controller.upcomingInterviews.isEmpty) {
        return EmptyState(
          illustration: const EmptyApplicationsIllustration(),
          title: 'Aucune candidature',
          subtitle:
              'Vous n\'avez pas encore postulé. Explorez les offres et tentez votre chance !',
          actionLabel: 'Voir les offres',
          onAction: () => Get.toNamed(AppRoutes.offers),
        );
      }
      final apps = controller.applications;
      return AppRefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: controller.load,
        child: AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              if (pending.isNotEmpty)
                _PendingAppliesSection(items: pending, queue: queue),
              if (controller.interviews.isNotEmpty)
                _InterviewInvitationsSection(
                  items: controller.interviews.toList(),
                  controller: controller,
                ),
              if (controller.jobProposals.isNotEmpty)
                _JobProposalsSection(
                  items: controller.jobProposals.toList(),
                  controller: controller,
                ),
              if (controller.upcomingInterviews.isNotEmpty)
                _UpcomingInterviewsSection(
                    items: controller.upcomingInterviews.toList()),
              for (var i = 0; i < apps.length; i++)
                AnimationConfiguration.staggeredList(
                  position: i,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    verticalOffset: AppMotion.listSlideOffset,
                    curve: AppMotion.emphasizedDecelerate,
                    child: FadeInAnimation(
                      child: _DismissibleApplication(
                        app: apps[i],
                        controller: controller,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _InterviewInvitationsSection extends StatelessWidget {
  const _InterviewInvitationsSection({
    required this.items,
    required this.controller,
  });

  final List<InterviewDetailModel> items;
  final ApplicationsController controller;

  @override
  Widget build(BuildContext context) {
    final actionable = items.where((i) => i.canRespond).toList();
    if (actionable.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: IconlyLight.calendar,
          title: 'Invitations entretien',
        ),
        const SizedBox(height: 10),
        ...actionable.map(
          (interview) => _ResponseCard(
            title: interview.offer?.title ?? 'Entretien',
            subtitle: interview.offer?.companyName ?? interview.statusLabel,
            meta: interview.scheduledAt == null
                ? interview.statusLabel
                : _formatDate(interview.scheduledAt!),
            color: AppColors.warningAccent,
            children: [
              if ((interview.location ?? '').isNotEmpty)
                _MetaLine(
                  icon: IconlyLight.location,
                  label: interview.location!,
                ),
              if ((interview.instructions ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  interview.instructions!,
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
                ),
              ],
              if (interview.hasQr) ...[
                const SizedBox(height: 10),
                _SmallActionButton(
                  label: 'Convocation QR',
                  icon: Icons.qr_code_rounded,
                  color: AppColors.primaryAccent,
                  onTap: () => _showInterviewQr(interview),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (interview.actions.contains(InterviewAction.accept))
                    _SmallActionButton(
                      label: 'Accepter',
                      icon: IconlyLight.tick_square,
                      color: AppColors.successAccent,
                      onTap: () => controller.respondToInterview(
                        interview,
                        InterviewAction.accept,
                      ),
                    ),
                  if (interview.actions.contains(InterviewAction.reschedule))
                    _SmallActionButton(
                      label: 'Reproposer',
                      icon: IconlyLight.time_circle,
                      color: AppColors.primaryAccent,
                      onTap: () => _rescheduleInterview(interview),
                    ),
                  if (interview.actions.contains(InterviewAction.decline))
                    _SmallActionButton(
                      label: 'Refuser',
                      icon: Icons.close_rounded,
                      color: AppColors.errorAccent,
                      onTap: () => _declineInterview(interview),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _showInterviewQr(InterviewDetailModel interview) {
    final rawUrl = interview.qrCodeUrl ?? '';
    final url = ApiConstants.resolveMediaUrl(rawUrl) ?? rawUrl;
    Widget content;
    if (url.isNotEmpty) {
      content = Image.network(
        url,
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _QrFallback(value: url),
      );
    } else {
      final code = interview.qrCode ?? '';
      final base64Payload = code.startsWith('data:image')
          ? code.substring(code.indexOf(',') + 1)
          : code;
      try {
        content = Image.memory(
          base64Decode(base64Payload),
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        );
      } catch (_) {
        content = _QrFallback(value: code);
      }
    }

    Get.dialog<void>(
      AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
        ),
        title: Text(
          'Convocation entretien',
          style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: content),
            const SizedBox(height: 12),
            Text(
              interview.offer?.title ?? 'Entretien',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _declineInterview(InterviewDetailModel interview) async {
    final message = await _askMessage(
      title: 'Refuser l\'entretien',
      hint: 'Message optionnel au recruteur',
      required: false,
    );
    if (message == null) return;
    await controller.respondToInterview(
      interview,
      InterviewAction.decline,
      message: message,
    );
  }

  Future<void> _rescheduleInterview(InterviewDetailModel interview) async {
    final datePickerContext = Get.context;
    if (datePickerContext == null) return;
    final date = await showDatePicker(
      context: datePickerContext,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    final timePickerContext = Get.context;
    if (timePickerContext == null) return;
    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: timePickerContext,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    final message = await _askMessage(
      title: 'Message au recruteur',
      hint: 'Ajoutez une précision si nécessaire',
      required: false,
    );
    if (message == null) return;
    await controller.respondToInterview(
      interview,
      InterviewAction.reschedule,
      message: message,
      proposedDate:
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _QrFallback extends StatelessWidget {
  const _QrFallback({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: AppColors.surfaceLow,
        shape: AppShapes.squircle(AppRadius.md),
      ),
      child: SelectableText(
        value.isEmpty ? 'QR indisponible' : value,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
      ),
    );
  }
}

class _JobProposalsSection extends StatelessWidget {
  const _JobProposalsSection({
    required this.items,
    required this.controller,
  });

  final List<JobProposalModel> items;
  final ApplicationsController controller;

  @override
  Widget build(BuildContext context) {
    final actionable = items.where((p) => p.canRespond).toList();
    if (actionable.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: IconlyLight.work,
          title: 'Propositions d\'emploi',
        ),
        const SizedBox(height: 10),
        ...actionable.map(
          (proposal) => _ResponseCard(
            title: proposal.offer?.title ?? 'Proposition d\'emploi',
            subtitle: proposal.offer?.companyName ?? proposal.statusLabel,
            meta: proposal.salaryFormatted ??
                proposal.contractType ??
                proposal.statusLabel,
            color: AppColors.successAccent,
            children: [
              if (proposal.startDate != null)
                _MetaLine(
                  icon: IconlyLight.calendar,
                  label: 'Début le ${_formatDate(proposal.startDate!)}',
                ),
              if ((proposal.benefits ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  proposal.benefits!,
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (proposal.actions.contains(JobProposalAction.accept))
                    _SmallActionButton(
                      label: 'Accepter',
                      icon: IconlyLight.tick_square,
                      color: AppColors.successAccent,
                      onTap: () => controller.respondToProposal(
                        proposal,
                        JobProposalAction.accept,
                      ),
                    ),
                  if (proposal.actions.contains(JobProposalAction.negotiate))
                    _SmallActionButton(
                      label: 'Négocier',
                      icon: IconlyLight.edit,
                      color: AppColors.primaryAccent,
                      onTap: () => _negotiateProposal(proposal),
                    ),
                  if (proposal.actions.contains(JobProposalAction.refuse))
                    _SmallActionButton(
                      label: 'Refuser',
                      icon: Icons.close_rounded,
                      color: AppColors.errorAccent,
                      onTap: () => _refuseProposal(proposal),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Future<void> _negotiateProposal(JobProposalModel proposal) async {
    final message = await _askMessage(
      title: 'Négocier la proposition',
      hint: 'Expliquez votre contre-proposition',
      required: true,
    );
    if (message == null) return;
    await controller.respondToProposal(
      proposal,
      JobProposalAction.negotiate,
      message: message,
    );
  }

  Future<void> _refuseProposal(JobProposalModel proposal) async {
    final message = await _askMessage(
      title: 'Refuser la proposition',
      hint: 'Message optionnel au recruteur',
      required: false,
    );
    if (message == null) return;
    await controller.respondToProposal(
      proposal,
      JobProposalAction.refuse,
      message: message,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.color,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String meta;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(color.withValues(alpha: 0.22)),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(label: meta, color: color, dense: true),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.hintColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: ShapeDecoration(
          color: color.withValues(alpha: 0.10),
          shape: AppShapes.squircle(AppRadius.sm),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _askMessage({
  required String title,
  required String hint,
  required bool required,
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final result = await Get.dialog<String?>(
    AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.squircleRadius(AppRadius.lg),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(hintText: hint),
          validator: (value) =>
              required && (value == null || value.trim().isEmpty)
                  ? 'Message requis'
                  : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String?>(result: null),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Get.back<String?>(result: controller.text.trim());
          },
          child: const Text('Envoyer'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Section "Prochains entretiens" — alimentée par
/// GET /applications/interviews/upcoming (géoloc + itinéraire + .ics).
class _UpcomingInterviewsSection extends StatelessWidget {
  const _UpcomingInterviewsSection({required this.items});
  final List<UpcomingInterview> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(IconlyLight.calendar,
                size: 18, color: AppColors.warningAccent),
            const SizedBox(width: 8),
            Text('Prochains entretiens',
                style: AppTextStyles.titleMd
                    .copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((i) => _InterviewCard(item: i)),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Section « En attente d'envoi » : candidatures postees hors-ligne, conservees
/// localement et renvoyees automatiquement au retour du reseau. Un bouton
/// « Renvoyer » permet de forcer une tentative immediate.
class _PendingAppliesSection extends StatelessWidget {
  const _PendingAppliesSection({required this.items, required this.queue});
  final List<PendingApply> items;
  final OfflineApplyQueue queue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 18, color: AppColors.warningAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text('En attente d\'envoi',
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
            TextButton.icon(
              onPressed: () {
                AppHaptics.tap();
                queue.flush();
              },
              icon: Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.primaryAccent),
              label: Text('Renvoyer',
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ces candidatures partiront automatiquement dès le retour du réseau.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
        ),
        const SizedBox(height: 10),
        ...items.map((p) => _PendingApplyCard(apply: p)),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _PendingApplyCard extends StatelessWidget {
  const _PendingApplyCard({required this.apply});
  final PendingApply apply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppColors.warningSoft,
        shape: AppShapes.squircle(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppShapes.squircleRadius(AppRadius.sm),
            child: BrandAvatar(
              seed: apply.company.isEmpty ? apply.offerTitle : apply.company,
              label: apply.company.isEmpty ? apply.offerTitle : apply.company,
              imageUrl: apply.logoUrl,
              size: 44,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(apply.offerTitle,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (apply.company.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(apply.company,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: 'En attente',
            color: AppColors.warningAccent,
            icon: Icons.schedule_rounded,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.item});
  final UpcomingInterview item;

  @override
  Widget build(BuildContext context) {
    final iv = item.interview;
    final when =
        iv?.dateHuman ?? (iv?.date != null ? _formatDate(iv!.date!) : null);
    final canRoute =
        (iv?.hasCoordinates ?? false) && iv?.lat != null && iv?.lng != null;
    final canCalendar = (iv?.icsUrl ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColors.warningSoft,
        shape: AppShapes.squircle(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.offerTitle,
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if ((item.companyName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.companyName!,
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor)),
          ],
          if (when != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(IconlyLight.calendar,
                    size: 15, color: AppColors.warningAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(when,
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.warningAccent,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
          if ((iv?.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyLight.location,
                    size: 15, color: AppColors.hintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(iv!.address!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor)),
                ),
              ],
            ),
          ],
          if (canRoute || canCalendar) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canRoute)
                  Expanded(
                    child: _InterviewAction(
                      icon: Icons.directions_rounded,
                      label: 'Itinéraire',
                      onTap: () {
                        AppHaptics.tap();
                        MapNavigationLauncher.openCoordinates(
                            iv!.lat!, iv.lng!);
                      },
                    ),
                  ),
                if (canRoute && canCalendar) const SizedBox(width: 10),
                if (canCalendar)
                  Expanded(
                    child: _InterviewAction(
                      icon: IconlyLight.calendar,
                      label: 'Calendrier',
                      onTap: () {
                        AppHaptics.tap();
                        MapNavigationLauncher.openIcs(iv!.icsUrl!);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InterviewAction extends StatelessWidget {
  const _InterviewAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.squircle(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_StatusStyle _statusStyle(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.newApp:
      return _StatusStyle('Envoyée', AppColors.primaryAccent, IconlyLight.send);
    case ApplicationStatus.shortlisted:
      return _StatusStyle(
          'Présélectionné', AppColors.successAccent, IconlyBold.star);
    case ApplicationStatus.interview:
      return _StatusStyle(
          'Entretien', AppColors.warningAccent, IconlyLight.calendar);
    case ApplicationStatus.rejected:
      return _StatusStyle('Non retenue', AppColors.errorAccent,
          Icons.do_not_disturb_on_rounded);
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Enveloppe une carte de candidature dans un glisser-pour-retirer (DELETE
/// /applications/{id}) avec confirmation. Le retrait est optimiste côté
/// controller (rollback si l'API échoue).
class _DismissibleApplication extends StatelessWidget {
  const _DismissibleApplication({required this.app, required this.controller});
  final ApplicationModel app;
  final ApplicationsController controller;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('app-${app.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        AppHaptics.tap();
        final ok = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            ),
            title: Text(
              'Retirer la candidature',
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
            ),
            content: Text(
              'Confirmez-vous le retrait de votre candidature à « ${app.offer?.title ?? 'cette offre'} » ? Cette action est irréversible.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(
                  'Annuler',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.hintColor),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text(
                  'Retirer',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.errorAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) => controller.withdraw(app.id),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg - 2),
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: ShapeDecoration(
          color: AppColors.errorSoft,
          shape: AppShapes.squircle(AppRadius.lg),
        ),
        child: Icon(IconlyLight.delete, color: AppColors.errorAccent, size: 22),
      ),
      child: _ApplicationCard(app: app),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.app});
  final ApplicationModel app;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(app.status);
    final title = app.offer?.title ?? 'Offre #${app.offerId}';
    final company = app.offer?.company ?? '';
    final location = app.offer?.location ?? '';
    final matchPct =
        (app.aiMatchScore <= 1 ? app.aiMatchScore * 100 : app.aiMatchScore)
            .round();

    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', app.offerId));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg - 2),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          // Profondeur par ombres en couches (langage 2026), sans liseré.
          boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                  child: BrandAvatar(
                    seed: company.isEmpty ? title : company,
                    label: company.isEmpty ? title : company,
                    imageUrl: app.offer?.companyLogo,
                    size: 44,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.titleMd
                              .copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(company,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.primaryAccent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusPill(
                  label: style.label,
                  color: style.color,
                  icon: style.icon,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (location.isNotEmpty) ...[
                  Icon(IconlyLight.location,
                      size: 14, color: AppColors.hintColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(location,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Icon(IconlyLight.calendar,
                    size: 14, color: AppColors.hintColor),
                const SizedBox(width: 4),
                Text(_formatDate(app.appliedAt),
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor)),
                const Spacer(),
                if (matchPct > 0) MatchScorePill(score: matchPct, dense: true),
              ],
            ),
            if (app.isRejected &&
                (app.rejectionReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: ShapeDecoration(
                  color: AppColors.errorSoft,
                  shape: AppShapes.squircle(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(IconlyLight.info_circle,
                        size: 15, color: AppColors.errorAccent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(app.rejectionReason!,
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.errorAccent, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationsSkeleton extends StatelessWidget {
  const _ApplicationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 5; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: SkeletonBox(width: double.infinity, height: 120, radius: 20),
          ),
      ],
    );
  }
}
