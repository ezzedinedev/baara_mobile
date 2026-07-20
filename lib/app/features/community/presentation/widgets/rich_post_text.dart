import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import '../pages/community_search_screen.dart';
import '../pages/hashtag_feed_screen.dart';

/// Rend un texte de publication / commentaire en mettant en évidence les
/// `@mentions` et `#hashtags` (couleur [AppColors.primaryAccent], cliquables).
///
/// - `#tag` → ouvre [HashtagFeedScreen].
/// - `@nom` → ouvre la recherche de membres préremplie (le corps du post ne
///   contient pas d'identifiant exploitable, on bascule donc sur la recherche).
class RichPostText extends StatefulWidget {
  const RichPostText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<RichPostText> createState() => _RichPostTextState();
}

class _RichPostTextState extends State<RichPostText> {
  // @mention (lettres/chiffres/_/.), #hashtag (lettres/chiffres/_).
  static final _pattern = RegExp(
    r'(@[\w.]+|#[\wÀ-ÿ]+)',
    unicode: true,
  );

  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _openHashtag(String tag) {
    AppHaptics.tap();
    Get.to<void>(() => HashtagFeedScreen(tag: tag));
  }

  void _openMention(String name) {
    AppHaptics.tap();
    Get.to<void>(() => CommunitySearchScreen(initialQuery: name));
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ??
        AppTextStyles.bodyMd.copyWith(
          height: 1.55,
          color: AppColors.titleColor,
        );
    final accent = base.copyWith(
      color: AppColors.primaryAccent,
      fontWeight: FontWeight.w700,
    );

    // On reconstruit les recognizers à chaque build (texte court, négligeable).
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    final text = widget.text;
    var last = 0;
    for (final match in _pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final token = match.group(0)!;
      final isHashtag = token.startsWith('#');
      final value = token.substring(1);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => isHashtag ? _openHashtag(value) : _openMention(value);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: token, style: accent, recognizer: recognizer));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: widget.textAlign,
    );
  }
}
