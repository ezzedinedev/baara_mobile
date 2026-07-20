import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/widgets/common/brand_avatar.dart';

import '../../domain/repositories/i_community_repository.dart';
import '../controllers/community_controller.dart';

/// Autocomplétion @mentions réutilisable pour les composers de story (texte et
/// média avec légende). Mutualise la logique d'overlay de `compose_post_screen`
/// (détection du token @… sous le curseur, recherche débouncée via
/// `CommunityController.fetchMentionables`, insertion `@Nom`).
///
/// À mixer dans un `State`. Appeler [attachMentionField] au build sur le champ
/// légende ; lire [mentionIds] à la publication pour envoyer les IDs au backend.
mixin StoryMentionAutocomplete<T extends StatefulWidget> on State<T> {
  /// Le contrôleur du champ légende observé (fourni par l'écran).
  TextEditingController get captionController;

  /// Clé du champ pour positionner l'overlay sous lui.
  final GlobalKey mentionFieldKey = GlobalKey();

  OverlayEntry? _overlay;
  Timer? _debounce;
  List<Mentionable> _results = const [];
  bool _loading = false;
  int _start = -1;
  int _end = -1;

  // Nom -> id des membres sélectionnés (best-effort : on filtre ensuite sur le
  // texte effectivement présent au moment de la publication).
  final Map<String, String> _picked = <String, String>{};

  CommunityController? get _community =>
      Get.isRegistered<CommunityController>() ? Get.find<CommunityController>() : null;

  /// IDs des membres mentionnés encore présents (`@Nom`) dans la légende.
  List<String> get mentionIds {
    final text = captionController.text;
    final ids = <String>{};
    _picked.forEach((name, id) {
      if (text.contains('@$name')) ids.add(id);
    });
    return ids.toList();
  }

  /// À brancher dans [State.initState].
  void initMentionAutocomplete() {
    captionController.addListener(_onTextChanged);
  }

  /// À brancher dans [State.dispose] (avant `super.dispose()`).
  void disposeMentionAutocomplete() {
    _debounce?.cancel();
    _removeOverlay();
    captionController.removeListener(_onTextChanged);
  }

  void _onTextChanged() {
    final sel = captionController.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      _close();
      return;
    }
    final caret = sel.baseOffset;
    final text = captionController.text;
    var i = caret - 1;
    while (i >= 0) {
      final ch = text[i];
      if (ch == '@') break;
      if (ch == ' ' || ch == '\n' || ch == '\t') {
        i = -1;
        break;
      }
      i--;
    }
    if (i < 0) {
      _close();
      return;
    }
    if (i > 0) {
      final before = text[i - 1];
      if (before != ' ' && before != '\n' && before != '\t') {
        _close();
        return;
      }
    }
    final query = text.substring(i + 1, caret);
    _start = i;
    _end = caret;
    _scheduleSearch(query);
  }

  void _scheduleSearch(String query) {
    final community = _community;
    if (community == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      _showOverlay();
      final results = await community.fetchMentionables(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
      _overlay?.markNeedsBuild();
    });
  }

  void _close() {
    _debounce?.cancel();
    _start = -1;
    _end = -1;
    _results = const [];
    _removeOverlay();
  }

  /// À appeler avant publication (ferme proprement l'overlay et le clavier).
  void closeMentions() => _close();

  void _select(Mentionable m) {
    if (_start < 0 || _end < 0) return;
    final text = captionController.text;
    final insert = '@${m.name} ';
    final newText = text.replaceRange(_start, _end, insert);
    _picked[m.name] = m.id;
    captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _start + insert.length),
    );
    _close();
    setState(() {});
  }

  void _showOverlay() {
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.of(context);
    final box =
        mentionFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final width = box.size.width;
    // Overlay au-dessus du champ (les composers ancrent leur légende en bas).
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy - 8,
        width: width,
        child: FractionalTranslation(
          translation: const Offset(0, -1),
          child: _list(),
        ),
      ),
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Widget _list() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.lightShadow,
        ),
        child: _loading && _results.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              )
            : _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Aucun membre',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final m = _results[i];
                      return ListTile(
                        dense: true,
                        leading: BrandAvatar(
                          seed: m.id,
                          label: m.name,
                          size: 32,
                          imageUrl: m.avatarUrl,
                        ),
                        title: Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLg
                              .copyWith(color: AppColors.titleColor),
                        ),
                        subtitle: (m.headline ?? '').isEmpty
                            ? null
                            : Text(
                                m.headline!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.hintColor),
                              ),
                        onTap: () => _select(m),
                      );
                    },
                  ),
      ),
    );
  }
}
