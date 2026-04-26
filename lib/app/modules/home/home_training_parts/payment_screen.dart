part of '../home_training_flow.dart';

class FormationPaymentScreen extends StatefulWidget {
  const FormationPaymentScreen({
    super.key,
    required this.controller,
    required this.formation,
  });

  final HomeController controller;
  final HomeFormationPreview formation;

  @override
  State<FormationPaymentScreen> createState() => _FormationPaymentScreenState();
}

class _FormationPaymentScreenState extends State<FormationPaymentScreen> {
  String _selectedMethod = 'orange_money';

  @override
  Widget build(BuildContext context) {
    final formation = widget.controller.formationById(widget.formation.id) ??
        widget.formation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.titleColor,
        title: Text('Paiement', style: AppTextStyles.titleLg),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Text(
              formation.title,
              style: AppTextStyles.headlineLg.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 8),
            Text(
              'Montant: ${formation.priceLabel}',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            _PaymentMethodCard(
              title: 'Orange Money',
              subtitle: 'Paiement mobile',
              icon: Icons.phone_android_rounded,
              color: AppColors.paymentOrangeMoney,
              selected: _selectedMethod == 'orange_money',
              onTap: () => setState(() => _selectedMethod = 'orange_money'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodCard(
              title: 'Wave',
              subtitle: 'Paiement mobile',
              icon: Icons.waves_rounded,
              color: AppColors.paymentWave,
              selected: _selectedMethod == 'wave',
              onTap: () => setState(() => _selectedMethod = 'wave'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'La formation sera ouverte apres validation du paiement.',
                style: AppTextStyles.bodyMd,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'PAYER MAINTENANT',
              borderRadius: 8,
              textColor: AppColors.onPrimary,
              onPressed: () {
                final methodLabel =
                    _selectedMethod == 'wave' ? 'Wave' : 'Orange Money';
                Get.snackbar(
                  'Paiement',
                  'Paiement $methodLabel en cours de configuration.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? color
                : AppColors.outlineVariant.withValues(alpha: 0.20),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMd),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySm),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? color : AppColors.hintColor,
            ),
          ],
        ),
      ),
    );
  }
}

