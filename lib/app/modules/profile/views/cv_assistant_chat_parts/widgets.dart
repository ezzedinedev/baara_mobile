part of '../cv_assistant_chat_screen.dart';

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = controller.progressPct.value;
      final expected = controller.expectedField.value;
      final fieldLabel =
          expected != null ? _fieldLabel(expected) : 'Section suivante';

      return Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceIconSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PROGRESSION',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.hintColor,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pct %',
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    expected != null
                        ? 'Prochaine info : $fieldLabel'
                        : 'Section principales complétées',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _fieldLabel(String field) => _kFieldLabels[field] ?? field;
}

/// Mapping unique champ backend → libellé FR. Source de vérité pour
/// `_ProgressHeader`, `_FieldStrip`, etc.
const Map<String, String> _kFieldLabels = {
  'first_name': 'prénom',
  'last_name': 'nom',
  'desired_role': 'poste visé',
  'email': 'email',
  'phone': 'téléphone',
  'country_residence': 'pays',
  'location': 'ville',
  'nationality': 'nationalité',
  'date_of_birth': 'date de naissance',
  'linkedin_url': 'LinkedIn',
  'portfolio_url': 'portfolio',
  'github_url': 'GitHub',
  'bio': 'présentation',
  'objective': 'objectif',
  'hard_skills': 'compétences',
  'soft_skills': 'soft skills',
  'languages': 'langues',
  'experiences': 'expériences',
  'educations': 'formations',
  'certifications': 'certifications',
  'projects': 'projets',
};

/// Ordre des champs guidés — doit refléter `CV_CORE_GUIDED_FIELDS` côté
/// backend. Sert à afficher la grille de progression dans le bon ordre.
const List<String> _kFieldOrder = [
  'first_name',
  'last_name',
  'desired_role',
  'email',
  'phone',
  'country_residence',
  'location',
  'nationality',
  'date_of_birth',
  'linkedin_url',
  'portfolio_url',
  'github_url',
  'bio',
  'objective',
  'hard_skills',
  'soft_skills',
  'languages',
  'experiences',
  'educations',
  'certifications',
  'projects',
];

/// Grille horizontale scrollable des champs CV avec statut visuel.
/// ✓ vert = rempli (dans `confirmedFields`)
/// • orange = prochain à remplir (`expectedField`)
/// ○ gris = pas encore traité
class _FieldStrip extends StatelessWidget {
  const _FieldStrip({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final confirmed = controller.confirmedFields.toSet();
      final expected = controller.expectedField.value;

      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: AppColors.surfaceCard,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _kFieldOrder.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final field = _kFieldOrder[i];
            final isDone = confirmed.contains(field);
            final isNext = !isDone && field == expected;
            return _FieldChip(
              label: _kFieldLabels[field] ?? field,
              isDone: isDone,
              isNext: isNext,
            );
          },
        ),
      );
    });
  }
}

class _FieldChip extends StatelessWidget {
  const _FieldChip({
    required this.label,
    required this.isDone,
    required this.isNext,
  });

  final String label;
  final bool isDone;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    if (isDone) {
      bg = AppColors.successSoft;
      fg = AppColors.successDark;
      icon = Icons.check_rounded;
    } else if (isNext) {
      bg = AppColors.primary.withValues(alpha: 0.14);
      fg = AppColors.primary;
      icon = Icons.adjust_rounded;
    } else {
      bg = AppColors.surfaceLow;
      fg = AppColors.hintColor;
      icon = Icons.circle_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: fg,
              fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Suggestions rapides au-dessus du composer : actions one-tap qui
/// dépendent du contexte courant (champ attendu, mode édition, etc.).
class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final freeMode = controller.freeEditMode.value;
      final expected = controller.expectedField.value;
      final isComplete = controller.isComplete.value;

      // Type de chip : on distingue les actions message (qui envoient un texte
      // au bot) des actions navigation (qui changent d'ecran).
      final List<({String label, IconData icon, String? message, VoidCallback? onTap})> items = [];

      if (freeMode) {
        items.add((
          label: 'Reprendre le parcours',
          message: 'Reprenons les questions guidées.',
          icon: Icons.assistant_rounded,
          onTap: null,
        ));
      } else if (isComplete) {
        // CV complet : on remplace les chips de progression par les actions
        // de finalisation. "Voir mon CV" ouvre l'apercu (depuis lequel le PDF
        // peut etre telecharge).
        items.add((
          label: 'Voir mon CV',
          icon: Icons.visibility_rounded,
          message: null,
          onTap: () {
            AppHaptics.tap();
            Get.toNamed(AppRoutes.profileCvPreview);
          },
        ));
        items.add((
          label: 'Améliorer mon CV',
          message: "Peux-tu me suggérer comment améliorer mon CV ?",
          icon: Icons.auto_awesome_rounded,
          onTap: null,
        ));
      } else if (expected != null) {
        items.add((
          label: 'Passer ce champ',
          message: "Je préfère passer ce champ pour le moment.",
          icon: Icons.skip_next_rounded,
          onTap: null,
        ));
        items.add((
          label: 'Édition libre',
          message: "Je veux modifier librement mon CV.",
          icon: Icons.edit_note_rounded,
          onTap: null,
        ));
      } else {
        items.add((
          label: 'Améliorer mon CV',
          message: "Peux-tu me suggérer comment améliorer mon CV ?",
          icon: Icons.auto_awesome_rounded,
          onTap: null,
        ));
      }

      if (items.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: AppColors.background,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = items[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  // Deux types de chips : action de navigation (onTap fourni)
                  // ou message envoye au bot (message fourni). Les chips
                  // navigation gerent leur propre haptic.
                  if (s.onTap != null) {
                    s.onTap!();
                    return;
                  }
                  AppHaptics.tap();
                  if (s.message != null) {
                    controller.sendAssistantMessage(s.message!);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        s.label,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.titleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

/// Welcome state — chaque ligne fade-in en cascade pour un onboarding doux.
class _Welcome extends StatefulWidget {
  const _Welcome();

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Crée une animation fade+slide qui démarre à `start` et finit à `end`
  /// (valeurs entre 0..1 sur la timeline globale du contrôleur).
  Animation<double> _staggered(double start, double end) {
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Reveal(
              animation: _staggered(0.0, 0.45),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _ctrl,
                    curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
                  ),
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceIconSoft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Reveal(
              animation: _staggered(0.20, 0.65),
              child: Text(
                'Bonjour ! 👋',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd,
              ),
            ),
            const SizedBox(height: 8),
            _Reveal(
              animation: _staggered(0.30, 0.75),
              child: Text(
                'Je vais te poser quelques questions pour construire ton CV. '
                'Réponds comme tu parles — je m\'occupe du formatage.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.bodyColor,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Reveal(
              animation: _staggered(0.45, 0.85),
              child: Text(
                'Essaie par exemple :',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.hintColor,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Reveal(
              animation: _staggered(0.55, 0.92),
              child: const _SuggestedBubble('Je m\'appelle Jean Dupont'),
            ),
            const SizedBox(height: 8),
            _Reveal(
              animation: _staggered(0.65, 1.0),
              child: const _SuggestedBubble(
                'Je cherche un poste de développeur Flutter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper de fade + slide vertical contrôlé par une [Animation].
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        final dy = (1 - animation.value) * 12;
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(offset: Offset(0, dy), child: c),
        );
      },
      child: child,
    );
  }
}

class _SuggestedBubble extends StatelessWidget {
  const _SuggestedBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '« $text »',
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.bodyColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ChatList extends StatefulWidget {
  const _ChatList({required this.controller});
  final CvBuilderController controller;

  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll on new messages.
    ever(widget.controller.chatHistory, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = widget.controller.chatHistory;
      final isSending = widget.controller.isSending.value;

      return ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        itemCount: messages.length + (isSending ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == messages.length && isSending) {
            return const _TypingIndicator();
          }
          final message = messages[index];
          return _Bubble(message: message);
        },
      );
    });
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final CvChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.bodyMd.copyWith(
                color: isUser ? AppColors.onPrimary : AppColors.titleColor,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceIconSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(delay: 0),
              SizedBox(width: 4),
              _TypingDot(delay: 180),
              SizedBox(width: 4),
              _TypingDot(delay: 360),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});
  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.bodyColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ComposerDivider extends StatelessWidget {
  const _ComposerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.outlineVariant.withValues(alpha: 0.2),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller});
  final CvBuilderController controller;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus a l'entree du chat : le bot pose une question, l'utilisateur
    // doit pouvoir repondre directement sans avoir a tapoter le champ. On
    // attend la fin du premier frame pour que le clavier soit positionne
    // correctement par rapport au layout final.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    AppHaptics.tap();
    _textCtrl.clear();
    final ok = await widget.controller.sendAssistantMessage(text);

    if (!mounted) return;
    if (!ok) {
      // Rollback : remettre le texte dans le champ pour édition
      _textCtrl.text = text;
      _textCtrl.selection = TextSelection.collapsed(offset: text.length);
      AppHaptics.error();
      Get.snackbar(
        'Erreur',
        widget.controller.errorMessage.value.isNotEmpty
            ? widget.controller.errorMessage.value
            : "Impossible d'envoyer le message.",
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          top: 10,
          bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Réponds à la question…',
                    hintStyle: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.hintColor,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final disabled = widget.controller.isSending.value;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: disabled ? null : _send,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: disabled
                          ? AppColors.surfaceContainer
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: disabled
                          ? AppColors.hintColor
                          : AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
