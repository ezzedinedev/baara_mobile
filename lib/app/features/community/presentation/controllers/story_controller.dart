import 'dart:async';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opportune_bf/app/core/services/realtime_events.dart';

import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';

import '../../domain/entities/story.dart';
import '../../domain/repositories/i_community_repository.dart';

/// Pilote les stories : feed groupé, publication, vue, réaction, réponse,
/// suppression. La barre se masque si vide.
class StoryController extends GetxController {
  StoryController(this._repo);
  final ICommunityRepository _repo;

  final buckets = <StoryBucket>[].obs;
  final isLoading = false.obs;
  final isPublishing = false.obs;

  StreamSubscription<RealtimeEvent>? _realtimeSub;
  Timer? _storyReloadDebounce;

  @override
  void onInit() {
    super.onInit();
    loadStories();
    if (Get.isRegistered<RealtimeEventBus>()) {
      _realtimeSub = Get.find<RealtimeEventBus>()
          .stream
          .where((e) => e is RealtimeStoryCreated)
          .listen((_) => _scheduleStoryReload());
    }
  }

  void _scheduleStoryReload() {
    _storyReloadDebounce?.cancel();
    _storyReloadDebounce = Timer(const Duration(seconds: 2), loadStories);
  }

  @override
  void onClose() {
    _realtimeSub?.cancel();
    _storyReloadDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadStories() async {
    try {
      isLoading.value = true;
      final fetched = await _repo.getStories();

      // Assurer que la story de l'utilisateur (isMine) apparait toujours en premier
      fetched.sort((a, b) {
        if (a.isMine && !b.isMine) return -1;
        if (!a.isMine && b.isMine) return 1;
        return 0;
      });

      buckets.assignAll(fetched);
    } catch (_) {
      // Silencieux : pas de barre = pas de bruit (le réseau peut être absent).
    } finally {
      isLoading.value = false;
    }
  }

  /// Sélectionne une image (galerie) pour créer une story.
  Future<XFile?> pickStoryImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      return await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 70,
      );
    } catch (_) {
      AppToast.error('Galerie', 'Impossible d\'ouvrir le sélecteur.');
      return null;
    }
  }

  /// Sélectionne une vidéo (≤ 60 s) pour créer une story.
  Future<XFile?> pickStoryVideo(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      return await ImagePicker().pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
    } catch (_) {
      AppToast.error('Galerie', 'Impossible d\'ouvrir le sélecteur.');
      return null;
    }
  }

  Future<bool> publish({
    String? mediaPath,
    String? caption,
    String? backgroundColor,
    String visibility = 'connections',
    List<String> mentions = const [],
  }) async {
    // 1. Mise à jour optimiste (immédiate)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final isVideo = mediaPath != null &&
        (mediaPath.endsWith('.mp4') || mediaPath.endsWith('.mov'));

    final optimisticStory = StoryItem(
      id: tempId,
      mediaUrl:
          mediaPath, // Temporaire (peut ne pas s'afficher parfaitement en preview selon la plateforme)
      mediaType: isVideo ? 'video' : 'image',
      caption: caption,
      backgroundColor: backgroundColor,
      createdAt: DateTime.now(),
      isMine: true,
      seen: true,
    );

    final myIndex = buckets.indexWhere((b) => b.isMine);
    if (myIndex >= 0) {
      buckets[myIndex].stories.add(optimisticStory);
    } else {
      buckets.insert(
        0,
        StoryBucket(
          user: const StoryAuthor(id: 'me', name: 'Moi'),
          isMine: true,
          stories: [optimisticStory],
        ),
      );
    }
    buckets.refresh();

    // 2. Envoi en arrière-plan sans bloquer l'UI
    _publishInBackground(
        mediaPath, caption, backgroundColor, visibility, mentions, tempId);

    return true; // Retour immédiat !
  }

  Future<void> _publishInBackground(
    String? mediaPath,
    String? caption,
    String? backgroundColor,
    String visibility,
    List<String> mentions,
    String tempId,
  ) async {
    try {
      await _repo.createStory(
        mediaPath: mediaPath,
        caption: caption,
        backgroundColor: backgroundColor,
        visibility: visibility,
        mentions: mentions,
      );
      // Remplace la story fantôme par la vraie liste du serveur
      await loadStories();
      AppToast.success('Story publiée !');
    } catch (e) {
      // Rollback en cas d'erreur
      AppToast.error('Publication', userFacingError(e));
      final myIndex = buckets.indexWhere((b) => b.isMine);
      if (myIndex >= 0) {
        buckets[myIndex].stories.removeWhere((s) => s.id == tempId);
        if (buckets[myIndex].stories.isEmpty) buckets.removeAt(myIndex);
        buckets.refresh();
      }
    }
  }

  Future<void> markViewed(StoryItem story) async {
    if (story.seen || story.isMine) return;
    story.seen = true;
    buckets.refresh();
    try {
      await _repo.viewStory(story.id);
    } catch (_) {}
  }

  Future<void> react(String storyId, String type) async {
    try {
      await _repo.reactStory(storyId, type);
    } catch (e) {
      AppToast.error('Réaction', userFacingError(e));
    }
  }

  Future<bool> reply(String storyId, String content) async {
    try {
      await _repo.replyStory(storyId, content);
      return true;
    } catch (e) {
      AppToast.error('Réponse', userFacingError(e));
      return false;
    }
  }

  Future<void> delete(String storyId) async {
    try {
      await _repo.deleteStory(storyId);
      await loadStories();
      AppToast.success('Story supprimée');
    } catch (e) {
      AppToast.error('Suppression', userFacingError(e));
    }
  }

  Future<Map<String, dynamic>> viewers(String storyId) =>
      _repo.storyViewers(storyId);
}
