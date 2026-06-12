import '../entities/post.dart';
import '../entities/community_comment.dart';
import '../entities/network_user.dart';
import '../entities/connection_request.dart';
import '../entities/story.dart';
import '../entities/skill.dart';
import '../entities/profile_viewer.dart';

/// Résultat paginé du fil.
class FeedPage {
  final List<Post> items;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  const FeedPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });
}

/// Hashtag tendance (bandeau « Tendances »).
class TrendingHashtag {
  final String tag;
  final int count;

  const TrendingHashtag({required this.tag, required this.count});
}

/// Brouillon de sondage transmis à la création d'une publication.
class PollDraft {
  final String? question;
  final List<String> options; // 2..6
  final bool multiple;
  final DateTime? closesAt;

  const PollDraft({
    this.question,
    required this.options,
    this.multiple = false,
    this.closesAt,
  });
}

/// Résultat de l'assistant IA de rédaction (`POST /community/ai/compose`).
///
/// Selon l'action demandée, le backend renvoie soit un texte unique
/// (improve / rephrase / shorten / expand) via [text], soit une liste de
/// suggestions (hashtags / ideas) via [suggestions]. Exactement l'un des deux
/// est renseigné.
class AiComposeResult {
  final String? text;
  final List<String>? suggestions;

  const AiComposeResult({this.text, this.suggestions});

  bool get hasText => text != null && text!.trim().isNotEmpty;
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;
}

/// Membre suggéré pour une @mention (autocomplétion).
class Mentionable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? headline;

  const Mentionable({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.headline,
  });
}

abstract class ICommunityRepository {
  // Fil
  // [tab] = onglet du feed intelligent : foryou | recent | connections.
  // [type] = filtre catégorie existant (combinable avec tous les onglets).
  Future<FeedPage> getFeed({
    String tab = 'foryou',
    String? type,
    int page = 1,
  });

  // Explore : posts publics tendance (même forme paginée que le feed).
  Future<FeedPage> getExplore({String? type, int page = 1});

  // Publications
  Future<Post> createPost({
    required String body,
    String category = 'general',
    String visibility = 'public',
    List<String> mediaPaths = const [],
    PollDraft? poll,
  });
  Future<void> deletePost(String postId);
  Future<Map<String, dynamic>> react(
      String postId, String type); // {status, reactions_count}
  Future<Post> repost(String postId, {String? body});
  Future<void> report(String postId, String reason);

  /// Édition (PUT) du corps d'une publication par son auteur.
  Future<Post> updatePost(String id, String body);

  // ── Wave 2 — Contenu riche ──────────────────────────────────────────────
  /// Vote (toggle) à un sondage → renvoie le sondage mis à jour.
  Future<PostPoll> votePoll(String pollId, List<String> optionIds);

  /// Enregistre (true) / retire (false) une publication → état `is_saved`.
  Future<bool> toggleSave(String postId, {required bool save});

  /// Publications enregistrées (paginé, même forme que le feed).
  Future<FeedPage> getSaved({int page = 1});

  /// Aperçu live d'un lien pour le composer (peut être null).
  Future<PostLinkPreview?> fetchLinkPreview(String url);

  // Commentaires
  Future<List<CommunityComment>> getComments(String postId);
  Future<CommunityComment> addComment(String postId, String body,
      {String? parentId});
  Future<void> deleteComment(String commentId);

  /// Édition (PUT) du corps d'un commentaire par son auteur.
  Future<CommunityComment> updateComment(String id, String body);

  /// Réaction (toggle) sur un commentaire → {reactions_count, my_reaction}.
  Future<Map<String, dynamic>> reactComment(String id, {String type = 'like'});

  // ── Wave 2 — Assistant IA (Mistral) ──────────────────────────────────────
  /// Aide à la rédaction d'une publication. [action] ∈ improve | rephrase |
  /// shorten | expand | hashtags | ideas. Peut lever (502 → indispo).
  Future<AiComposeResult> aiCompose(String draft, String action);

  /// Résumé IA d'une publication existante → texte du résumé.
  Future<String> summarizePost(String postId);

  /// Traduction IA d'une publication vers [lang] (ex. 'fr', 'en') → traduction.
  Future<String> translatePost(String postId, String lang);

  // Hashtags & mentions
  Future<FeedPage> getHashtagFeed(String tag, {int page = 1});
  Future<List<TrendingHashtag>> getTrendingHashtags();
  Future<List<Mentionable>> getMentionables(String q);

  // Graphe social
  Future<void> follow(String userId);
  Future<void> unfollow(String userId);
  Future<void> connect(String userId);
  Future<void> respondConnection(String connectionId, {required bool accept});
  Future<List<ConnectionRequest>> getConnections();

  // ── Cluster D — Sécurité & graphe social ────────────────────────────────
  /// Bloque (true) ou débloque (false) un membre. → état `is_blocked`.
  Future<bool> setBlocked(String userId, {required bool blocked});

  /// « Qui a vu mon profil » : viewers + total.
  Future<ProfileViewsResult> getProfileViews();

  /// Ajoute une compétence à son propre profil.
  Future<Skill> addSkill(String name);

  /// Retire une compétence de son propre profil.
  Future<void> removeSkill(String skillId);

  /// Recommande (true) / retire la recommandation (false) d'une compétence.
  /// → {skill_id, endorsed_by_me, endorsements_count}.
  Future<Skill> endorseSkill(String skillId, {required bool endorse});

  // Stories éphémères
  Future<List<StoryBucket>> getStories();
  Future<void> createStory({
    String? mediaPath,
    String? caption,
    String? backgroundColor,
    String visibility = 'connections',
  });
  Future<void> viewStory(String storyId);
  Future<void> reactStory(String storyId, String type);
  Future<String?> replyStory(
      String storyId, String content); // → conversationId
  Future<void> deleteStory(String storyId);
  Future<Map<String, dynamic>> storyViewers(String storyId);

  // Découverte
  Future<List<NetworkUser>> getSuggestions();
  Future<Map<String, dynamic>> getProfile(String userId);
  Future<Map<String, dynamic>> search(String query, {String type = 'people'});
  Future<List<NetworkUser>> searchPeople(String query);
}
