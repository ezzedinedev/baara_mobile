import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  Future<void> loadStories() async {
    try {
      isLoading.value = true;
      buckets.assignAll(await _repo.getStories());
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
        maxWidth: 1440,
        maxHeight: 2560,
        imageQuality: 88,
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
  }) async {
    if (isPublishing.value) return false;
    try {
      isPublishing.value = true;
      await _repo.createStory(
        mediaPath: mediaPath,
        caption: caption,
        backgroundColor: backgroundColor,
        visibility: visibility,
      );
      await loadStories();
      return true;
    } catch (e) {
      AppToast.error('Publication', userFacingError(e));
      return false;
    } finally {
      isPublishing.value = false;
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
