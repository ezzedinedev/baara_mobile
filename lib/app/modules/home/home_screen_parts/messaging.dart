part of '../home_screen.dart';

class _MessagerieTab extends StatefulWidget {
  const _MessagerieTab({required this.controller});

  final HomeController controller;

  @override
  State<_MessagerieTab> createState() => _MessagerieTabState();
}

class _MessagerieTabState extends State<_MessagerieTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final RxString _query = ''.obs;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(HomeConversationPreview c) {
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.title.toLowerCase().contains(q) ||
        c.preview.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MessagerieFlatHeader(controller: widget.controller),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: AppSearchBar(
            controller: _searchCtrl,
            hint: 'Rechercher une conversation...',
            onChanged: (v) => _query.value = v,
          ),
        ),
        Expanded(
          child: Obx(() {
            _query.value;
            final isLoading =
                widget.controller.isLoadingConversations.value;
            final loadError =
                widget.controller.conversationsLoadError.value;
            final raw = widget.controller.conversations;
            final conversations =
                raw.where(_matches).toList(growable: false);

            // Loading initial → skeletons.
            if (isLoading && raw.isEmpty) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, __) => const MessageTileSkeleton(),
              );
            }

            // Error : ErrorStateView avec retry.
            if (loadError.isNotEmpty && raw.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: widget.controller.loadConversations,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: ErrorStateView(
                        message: loadError,
                        onRetry: widget.controller.loadConversations,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (conversations.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: widget.controller.loadConversations,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      child: EmptyState(
                        icon: _query.value.isEmpty
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.search_off_rounded,
                        title: _query.value.isEmpty
                            ? 'Aucune conversation'
                            : 'Aucun resultat',
                        subtitle: _query.value.isEmpty
                            ? 'Vos echanges avec les recruteurs apparaitront ici.'
                            : 'Essayez avec un autre mot-cle.',
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: widget.controller.loadConversations,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: conversations.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                      child: Text(
                        'CONVERSATIONS',
                        style: AppTextStyles.labelLg.copyWith(
                          color: AppColors.bodyColor,
                          fontSize: 11,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }
                  final conversation = conversations[index - 1];
                  return _ConversationTile(
                    controller: widget.controller,
                    conversation: conversation,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Header flat green : pastille glass chat + titre + compteur dynamique +
/// bouton theme. Coins inferieurs arrondis, ombre teintee primaryDark.
class _MessagerieFlatHeader extends StatelessWidget {
  const _MessagerieFlatHeader({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final themeController = Get.find<AppThemeController>();
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 16, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: 0.20),
              border: Border.all(
                color: AppColors.onPrimary.withValues(alpha: 0.32),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              IconlyBold.chat,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final unread = controller.unreadCounters.values
                  .fold<int>(0, (sum, n) => sum + n);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Messagerie',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unread > 0
                        ? '$unread non lu${unread > 1 ? 's' : ''}'
                        : 'Tout est a jour',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }),
          ),
          Obx(() {
            final isDark = themeController.isDarkMode.value;
            return InkWell(
              onTap: () async {
                AppHaptics.tap();
                await themeController.toggle();
              },
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.20),
                  border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  const _ConversationTile({
    required this.controller,
    required this.conversation,
  });

  final HomeController controller;
  final HomeConversationPreview conversation;

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final accentEnd = AppColors.avatarGradientForSeed(c.id).last;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () => widget.controller.openConversation(c),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Obx(() {
          final unreadCount = widget.controller.unreadFor(c.id);
          final hasUnread = unreadCount > 0;
          return Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: hasUnread
                  ? AppColors.surfaceSelected
                  : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: hasUnread
                    ? AppColors.primary.withValues(alpha: 0.28)
                    : AppColors.outlineVariant.withValues(alpha: 0.18),
              ),
              boxShadow: AppColors.lightShadow,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentEnd.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BrandAvatar(
                        seed: c.id,
                        label: c.title,
                        size: 50,
                        fontSize: 16,
                      ),
                    ),
                    if (c.online)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            shape: BoxShape.circle,
                          ),
                          child: const PulsingDot(
                            color: AppColors.successDark,
                            size: 12,
                            haloSize: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMd.copyWith(
                                color: AppColors.titleColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.timeLabel,
                            style: AppTextStyles.labelSm.copyWith(
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.hintColor,
                              fontSize: 10,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.preview.isEmpty
                                  ? 'Pas encore de message'
                                  : c.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                color: hasUnread
                                    ? AppColors.titleColor
                                    : AppColors.bodyColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints:
                                  const BoxConstraints(minWidth: 22),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(999)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Conversation interieure inspiree des messageries modernes (Telegram /
/// Messenger). Header plein primary avec avatar+statut+call/video/menu,
/// pills date, bulles vertes (mes messages) / grises (ses messages),
/// banniere chiffrement E2E, input avec + et bouton send circulaire.
class _MessagingOverlay extends StatelessWidget {
  const _MessagingOverlay({required this.controller});

  final HomeController controller;

  String _formatTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _dateSeparator(DateTime d) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aout',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime.now();
    final dDay = DateTime(d.year, d.month, d.day);
    final tDay = DateTime(today.year, today.month, today.day);
    if (dDay == tDay) return "Aujourd'hui";
    if (dDay == tDay.subtract(const Duration(days: 1))) return 'Hier';
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final conversation = controller.activeConversation;
      if (conversation == null) return const SizedBox.shrink();

      final thread = controller.threadFor(conversation.id);

      return Positioned.fill(
        child: Container(
          color: AppColors.secondaryDeep.withValues(alpha: 0.22),
          child: Material(
            color: AppColors.background,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _ConversationHeader(
                    conversation: conversation,
                    onBack: controller.closeConversation,
                    initialsBuilder: _initials,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(14, 16, 14, 12),
                      itemCount: thread.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              if (thread.isNotEmpty)
                                _DateSeparator(
                                  label: _dateSeparator(thread.first.sentAt),
                                ),
                              const _EncryptionNotice(),
                            ],
                          );
                        }
                        final message = thread[index - 1];
                        final prev =
                            index > 1 ? thread[index - 2] : null;
                        final showDate = prev != null &&
                            !_sameDay(prev.sentAt, message.sentAt);
                        return Column(
                          children: [
                            if (showDate)
                              _DateSeparator(
                                label: _dateSeparator(message.sentAt),
                              ),
                            _ChatBubble(
                              text: message.text,
                              time: _formatTime(message.sentAt),
                              isMine: message.isMine,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _ChatInputBar(controller: controller),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.conversation,
    required this.onBack,
    required this.initialsBuilder,
  });

  final HomeConversationPreview conversation;
  final VoidCallback onBack;
  final String Function(String) initialsBuilder;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 10, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: onBack,
            icon: const Icon(
              IconlyLight.arrow_left_2,
              color: AppColors.onPrimary,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: 0.22),
              border: Border.all(
                color: AppColors.onPrimary.withValues(alpha: 0.32),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initialsBuilder(conversation.title),
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    if (conversation.online) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      conversation.online ? 'En ligne' : 'Hors ligne',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Appeler',
            onPressed: () => AppHaptics.tap(),
            icon: const Icon(
              IconlyLight.calling,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
          IconButton(
            tooltip: 'Appel vidéo',
            onPressed: () => AppHaptics.tap(),
            icon: const Icon(
              IconlyLight.video,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
          IconButton(
            tooltip: 'Plus d\'options',
            onPressed: () => AppHaptics.tap(),
            icon: const Icon(
              IconlyLight.more_square,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.bodyColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EncryptionNotice extends StatelessWidget {
  const _EncryptionNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              IconlyBold.lock,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vos echanges sont chiffres de bout en bout. Personne en dehors '
                'de cette conversation, pas meme OpporTune, ne peut les lire.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.warning,
                  height: 1.35,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isMine,
  });

  final String text;
  final String time;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: isMine
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                : null,
            color: isMine ? null : AppColors.surfaceLow,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
            boxShadow: isMine
                ? [
                    BoxShadow(
                      color:
                          AppColors.primaryDark.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: isMine
                ? null
                : Border.all(
                    color:
                        AppColors.outlineVariant.withValues(alpha: 0.18),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isMine
                      ? AppColors.onPrimary
                      : AppColors.titleColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isMine
                          ? AppColors.onPrimary.withValues(alpha: 0.80)
                          : AppColors.hintColor,
                      fontSize: 10,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton + (attachements).
          InkWell(
            onTap: () => AppHaptics.tap(),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLow,
              ),
              child: const Icon(
                IconlyLight.plus,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Input + emoji integre.
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.chatInputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.sendActiveMessage(),
                      maxLines: 4,
                      minLines: 1,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.titleColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ecrire un message...',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.hintColor,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => AppHaptics.tap(),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          IconlyLight.heart,
                          color: AppColors.bodyColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button — circulaire gradient.
          Obx(() {
            return InkWell(
              onTap: controller.isSendingChat.value
                  ? null
                  : controller.sendActiveMessage,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark
                          .withValues(alpha: 0.34),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: controller.isSendingChat.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.onPrimary),
                        ),
                      )
                    : const Icon(
                        IconlyBold.send,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

