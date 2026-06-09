import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';
import '../controllers/training_detail_controller.dart';

/// Moyen de paiement mobile money disponible.
class _PayOperator {
  const _PayOperator({
    required this.key,
    required this.label,
    required this.asset,
  });
  final String key; // valeur envoyée au backend (provider)
  final String label;
  final String asset;
}

/// Écran de paiement d'une formation payante : choix de l'opérateur mobile
/// money (Orange / Moov / Wave), saisie du numéro, puis appel
/// `POST /trainings/{id}/pay`. Le paiement backend est synchrone : en cas de
/// succès l'inscription est créée (payment_status = paid).
class TrainingPaymentScreen extends StatefulWidget {
  const TrainingPaymentScreen({super.key, required this.training});

  final Training training;

  @override
  State<TrainingPaymentScreen> createState() => _TrainingPaymentScreenState();
}

class _TrainingPaymentScreenState extends State<TrainingPaymentScreen> {
  static const _operators = <_PayOperator>[
    _PayOperator(
      key: 'orange',
      label: 'Orange Money',
      asset: 'assets/images/operators/orange_money.jpg',
    ),
    _PayOperator(
      key: 'moov',
      label: 'Moov Money',
      asset: 'assets/images/operators/moov_money.jpg',
    ),
    _PayOperator(
      key: 'wave',
      label: 'Wave',
      asset: 'assets/images/operators/wave.jpg',
    ),
  ];

  final _phoneCtrl = TextEditingController();
  final _repository = Get.find<ITrainingRepository>();

  String? _provider;
  bool _isPaying = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final provider = _provider;
    final phone = _phoneCtrl.text.trim();
    if (provider == null) {
      setState(() => _error = 'Choisissez un moyen de paiement.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Entrez le numéro associé à votre compte.');
      return;
    }

    AppHaptics.tap();
    setState(() {
      _isPaying = true;
      _error = null;
    });
    final result = await _repository.payTraining(
      widget.training.id,
      provider: provider,
      phone: phone,
    );
    if (!mounted) return;
    setState(() => _isPaying = false);

    if (result.success) {
      AppHaptics.confirm();
      // Débloque l'accès au parcours sur l'écran de détail resté en arrière.
      if (Get.isRegistered<TrainingDetailController>()) {
        Get.find<TrainingDetailController>().justEnrolled.value = true;
      }
      Get.back<void>();
      AppToast.success(
        'Paiement confirmé',
        'Vous êtes inscrit à "${widget.training.title}".',
      );
    } else {
      setState(() => _error =
          result.message ?? 'Paiement impossible. Réessayez dans un instant.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.training;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.titleColor,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBackButton(onTap: () => Get.back<void>()),
        ),
        leadingWidth: 60,
        title: Text('Paiement', style: AppTextStyles.titleLg),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _SummaryCard(title: t.title, priceLabel: t.priceLabel),
            const SizedBox(height: 24),
            Text(
              'Moyen de paiement',
              style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ..._operators.map(
              (op) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OperatorTile(
                  operator: op,
                  selected: _provider == op.key,
                  onTap: () {
                    AppHaptics.tap();
                    setState(() {
                      _provider = op.key;
                      _error = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Numéro de téléphone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              icon: IconlyLight.call,
              hint: 'Ex : 70 00 00 00',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(IconlyLight.shield_done,
                      size: 15, color: AppColors.hintColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Vous recevrez une demande de confirmation sur votre téléphone.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: GradientButton(
            label: 'PAYER ${t.priceLabel}',
            isLoading: _isPaying,
            textColor: AppColors.onPrimary,
            height: 52,
            borderRadius: 14,
            onPressed: _isPaying ? null : _pay,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.priceLabel});
  final String title;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FORMATION',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLg.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Montant à payer',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              Text(
                priceLabel,
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  const _OperatorTile({
    required this.operator,
    required this.selected,
    required this.onTap,
  });

  final _PayOperator operator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? AppColors.lightShadow : null,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  operator.asset,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: AppColors.surfaceLow,
                    child: const Icon(IconlyBold.wallet,
                        color: AppColors.primary, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  operator.label,
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
          width: 2,
        ),
        color: selected ? AppColors.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check_rounded,
              size: 14, color: AppColors.onPrimary)
          : null,
    );
  }
}
