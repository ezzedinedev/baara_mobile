import 'package:get/get.dart';
import 'package:baara/app/core/services/auth_token_store.dart';
import 'package:baara/app/core/utils/candidate_access.dart';
import 'package:baara/app/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:baara/routes/app_routes.dart';

/// Vérifie qu'une session active appartient bien à un candidat.
/// Déconnecte et renvoie vers la landing si employeur / recruteur.
class CandidateSessionGuard {
  CandidateSessionGuard(this._tokenStore, this._authRepository);

  final AuthTokenStore _tokenStore;
  final IAuthRepository _authRepository;

  Future<void> ensureCandidateOrSignOut() async {
    final token = await _tokenStore.readTokenOrNull();
    if (token == null || token.isEmpty) return;

    final storedType = await _tokenStore.readUserType();
    if (!CandidateAccess.isAllowed(storedType)) {
      await _tokenStore.clearSession();
      Get.offAllNamed(AppRoutes.landing);
      return;
    }

    try {
      await _authRepository.getMe();
    } on CandidateAccessDeniedException {
      await _tokenStore.clearSession();
      Get.offAllNamed(AppRoutes.landing);
    } catch (_) {
      // Hors-ligne : on garde la session si le type local est candidat.
    }
  }
}
