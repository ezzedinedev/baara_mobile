import 'package:get/get.dart';

import 'package:baara/app/core/utils/user_facing_error.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/i_community_repository.dart';

/// Contrôleur léger dédié au fil d'un hashtag (`#tag`). Pagination + refresh.
class HashtagFeedController extends GetxController {
  HashtagFeedController(this._repository, this.tag);

  final ICommunityRepository _repository;
  final String tag;

  final posts = <Post>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final errorMessage = RxnString();

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      _page = 1;
      final result = await _repository.getHashtagFeed(tag, page: 1);
      posts.assignAll(result.items);
      hasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => load();

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final result = await _repository.getHashtagFeed(tag, page: _page + 1);
      _page += 1;
      posts.addAll(result.items);
      hasMore.value = result.hasMore;
    } catch (_) {
      // silencieux : on garde la page courante.
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Réaction optimiste locale (même logique fine que le fil principal).
  Future<void> toggleReaction(String postId, String type) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final current = posts[index];
    final previous = current.myReaction;

    final breakdown = Map<String, int>.from(current.reactionsBreakdown);
    int count = current.reactionsCount;
    String? nextReaction;

    if (previous == type) {
      breakdown[type] = ((breakdown[type] ?? 1) - 1).clamp(0, 1 << 30);
      count = (count - 1).clamp(0, 1 << 30);
      nextReaction = null;
    } else if (previous == null) {
      breakdown[type] = (breakdown[type] ?? 0) + 1;
      count = count + 1;
      nextReaction = type;
    } else {
      breakdown[previous] = ((breakdown[previous] ?? 1) - 1).clamp(0, 1 << 30);
      breakdown[type] = (breakdown[type] ?? 0) + 1;
      nextReaction = type;
    }

    posts[index] = current.copyWith(
      isLiked: nextReaction != null,
      reactionsCount: count,
      reactionsBreakdown: breakdown,
      myReaction: nextReaction,
      clearMyReaction: nextReaction == null,
    );

    try {
      final res = await _repository.react(postId, type);
      final serverCount = (res['reactions_count'] as num?)?.toInt();
      if (serverCount != null) {
        final idx = posts.indexWhere((p) => p.id == postId);
        if (idx >= 0) {
          posts[idx] = posts[idx].copyWith(reactionsCount: serverCount);
        }
      }
    } catch (_) {
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx >= 0) posts[idx] = current;
    }
  }

  /// Vote (toggle) à un sondage — optimiste, réaligne sur la réponse, rollback.
  Future<void> votePoll(String postId, String optionId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final current = posts[index];
    final poll = current.poll;
    if (poll == null || poll.isClosed) return;

    posts[index] = current.copyWith(poll: _applyVoteLocally(poll, optionId));
    try {
      final updated = await _repository.votePoll(
        poll.id,
        _resolveVoteSelection(poll, optionId),
      );
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx >= 0) posts[idx] = posts[idx].copyWith(poll: updated);
    } catch (e) {
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx >= 0) posts[idx] = current;
      errorMessage.value = userFacingError(e);
    }
  }

  PostPoll _applyVoteLocally(PostPoll poll, String optionId) {
    final tapped = poll.options.firstWhere(
      (o) => o.id == optionId,
      orElse: () => poll.options.first,
    );
    final willSelect = !tapped.votedByMe;
    var total = poll.totalVotes;
    final myVotes = List<String>.from(poll.myVotes);

    final options = poll.options.map((o) {
      if (!poll.multiple) {
        if (o.id == optionId) {
          return o.copyWith(
            votedByMe: willSelect,
            votesCount: willSelect ? o.votesCount + 1 : o.votesCount - 1,
          );
        }
        if (willSelect && o.votedByMe) {
          return o.copyWith(votedByMe: false, votesCount: o.votesCount - 1);
        }
        return o;
      }
      if (o.id == optionId) {
        return o.copyWith(
          votedByMe: willSelect,
          votesCount: willSelect ? o.votesCount + 1 : o.votesCount - 1,
        );
      }
      return o;
    }).toList();

    if (!poll.multiple) {
      total = willSelect && myVotes.isEmpty ? total + 1 : total;
      if (!willSelect) total -= 1;
      myVotes
        ..clear()
        ..addAll(willSelect ? [optionId] : const []);
    } else {
      total += willSelect ? 1 : -1;
      if (willSelect) {
        myVotes.add(optionId);
      } else {
        myVotes.remove(optionId);
      }
    }

    return poll.copyWith(
      options: options,
      totalVotes: total < 0 ? 0 : total,
      myVotes: myVotes,
    );
  }

  List<String> _resolveVoteSelection(PostPoll poll, String optionId) {
    final tapped = poll.options.firstWhere(
      (o) => o.id == optionId,
      orElse: () => poll.options.first,
    );
    final willSelect = !tapped.votedByMe;
    if (!poll.multiple) {
      return willSelect ? [optionId] : const [];
    }
    final selected =
        poll.options.where((o) => o.votedByMe).map((o) => o.id).toSet();
    if (willSelect) {
      selected.add(optionId);
    } else {
      selected.remove(optionId);
    }
    return selected.toList();
  }

  /// Enregistre/retire une publication — optimiste, rollback sur échec.
  Future<void> toggleSave(String postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final current = posts[index];
    final willSave = !current.isSaved;
    posts[index] = current.copyWith(isSaved: willSave);
    try {
      await _repository.toggleSave(postId, save: willSave);
    } catch (e) {
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx >= 0) posts[idx] = current;
      errorMessage.value = userFacingError(e);
    }
  }
}
