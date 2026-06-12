import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/common/press_scale.dart';
import 'package:opportune_bf/app/core/widgets/effects/burst_effect.dart';
import '../../domain/entities/post.dart';

/// Bouton de réaction du fil :
/// - **tap** → `onReact('like')` (bascule rapide du J'aime) ;
/// - **appui long** → bulle animée (scale + fade) des 4 emojis ; le choix
///   déclenche `onReact(type)`.
///
/// Quand une réaction est active, le bouton affiche son emoji + libellé en
/// [AppColors.primaryAccent] ; sinon un état neutre « J'aime ».
class ReactionButton extends StatefulWidget {
  const ReactionButton({
    super.key,
    required this.myReaction,
    required this.onReact,
  });

  /// Type de la réaction courante (like | love | bravo | instructif) ou null.
  final String? myReaction;
  final void Function(String type) onReact;

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with TickerProviderStateMixin {
  final _anchorKey = GlobalKey();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );
  // Pop d'icône (overshoot springEmphasized) joué à l'AJOUT d'une réaction.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: AppMotion.short,
  );
  OverlayEntry? _picker;

  @override
  void dispose() {
    _removePicker(immediate: true);
    _anim.dispose();
    _pop.dispose();
    super.dispose();
  }

  /// Joue le pop d'icône (toujours, même en reduce-motion : c'est léger et non
  /// particulaire). Le burst de particules, lui, est conditionné par showBurst.
  void _playPop() {
    _pop.forward(from: 0).then((_) {
      if (mounted) _pop.reverse();
    });
  }

  /// Burst de particules au centre du bouton — seulement à l'AJOUT.
  void _burstAtAnchor() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    showBurst(context, center, emoji: '★');
  }

  void _onTap() {
    AppHaptics.tap();
    // Tap rapide = J'aime si neutre (AJOUT), sinon retire la réaction (toggle).
    final adding = widget.myReaction == null;
    widget.onReact(widget.myReaction ?? 'like');
    if (adding) {
      _playPop();
      _burstAtAnchor();
    }
  }

  void _showPicker() {
    if (_picker != null) return;
    AppHaptics.confirm();
    final overlay = Overlay.of(context);
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero);
    final size = box.size;

    _picker = OverlayEntry(
      builder: (ctx) {
        final media = MediaQuery.of(ctx).size;
        const bubbleWidth = 4 * 52.0 + 16;
        var left = anchor.dx + size.width / 2 - bubbleWidth / 2;
        left = left.clamp(12.0, media.width - bubbleWidth - 12.0);
        final top = anchor.dy - 64;

        return Stack(
          children: [
            // Capte le tap extérieur pour fermer.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removePicker,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: ScaleTransition(
                scale:
                    CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _anim,
                  child: _bubble(),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_picker!);
    _anim.forward(from: 0);
  }

  Future<void> _removePicker({bool immediate = false}) async {
    final entry = _picker;
    if (entry == null) return;
    _picker = null;
    if (immediate) {
      entry.remove();
      return;
    }
    await _anim.reverse();
    entry.remove();
  }

  Future<void> _pick(String type) async {
    AppHaptics.tap();
    // Sélection via la bulle : on AJOUTE/CHANGE une réaction → burst (sauf si
    // c'est exactement la même réaction, qui la retire en toggle).
    final adding = widget.myReaction != type;
    final emoji = kReactionEmojis[type];
    await _removePicker();
    widget.onReact(type);
    if (adding && mounted) {
      _playPop();
      final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.localToGlobal(box.size.center(Offset.zero));
        showBurst(context, center, emoji: emoji);
      }
    }
  }

  Widget _bubble() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.pill,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.lightShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in kReactionTypes)
              _emojiTile(type, kReactionEmojis[type] ?? ''),
          ],
        ),
      ),
    );
  }

  /// Retourne une icône colorée correspondant au type de réaction.
  /// Remplace les emojis Unicode pour garantir un rendu identique iOS/Android.
  Widget _reactionIcon(String type, {double size = 26}) {
    switch (type) {
      case 'like':
        return Icon(Icons.thumb_up_rounded, size: size, color: const Color(0xFF2563EB));
      case 'love':
        return Icon(Icons.favorite_rounded, size: size, color: const Color(0xFFE11D48));
      case 'bravo':
        return Icon(Icons.emoji_events_rounded, size: size, color: const Color(0xFFD97706));
      case 'instructif':
        return Icon(Icons.lightbulb_rounded, size: size, color: const Color(0xFF7C3AED));
      default:
        return Icon(Icons.thumb_up_rounded, size: size, color: const Color(0xFF2563EB));
    }
  }

  Widget _emojiTile(String type, String _) {
    final selected = widget.myReaction == type;
    return GestureDetector(
      onTap: () => _pick(type),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.14)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: _reactionIcon(type, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.myReaction != null;
    final emoji = active ? (kReactionEmojis[widget.myReaction] ?? '') : '';
    final label =
        active ? (kReactionLabels[widget.myReaction] ?? "J'aime") : "J'aime";
    final color = active ? AppColors.primaryAccent : AppColors.hintColor;

    return PressScale(
      key: _anchorKey,
      onTap: _onTap,
      onLongPress: _showPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              // Overshoot expressif (springEmphasized) au moment du pop.
              scale: Tween<double>(begin: 1.0, end: 1.32).animate(
                CurvedAnimation(
                    parent: _pop, curve: AppMotion.springEmphasized),
              ),
              child: active
                  ? _reactionIcon(widget.myReaction!, size: 17)
                  : Icon(IconlyLight.heart, size: 18, color: color),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
