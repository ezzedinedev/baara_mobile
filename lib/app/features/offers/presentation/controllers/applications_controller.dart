import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/application_model.dart';
import '../../data/models/interview_detail_model.dart';
import '../../data/models/job_proposal_model.dart';
import '../../data/models/upcoming_interview_model.dart';
import '../../domain/repositories/i_offer_repository.dart';

/// Charge la liste des candidatures du candidat connecté
/// (GET /applications) et les entretiens à venir
/// (GET /applications/interviews/upcoming), et expose un état observable.
class ApplicationsController extends GetxController {
  ApplicationsController(this._repository);

  final IOfferRepository _repository;

  final applications = <ApplicationModel>[].obs;
  final upcomingInterviews = <UpcomingInterview>[].obs;
  final interviews = <InterviewDetailModel>[].obs;
  final jobProposals = <JobProposalModel>[].obs;
  final respondingIds = <String>{}.obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _repository.getMyApplications(),
        _repository.getUpcomingInterviews(),
        _repository.getInterviews(),
        _repository.getJobProposals(),
      ]);
      applications.assignAll(results[0] as List<ApplicationModel>);
      upcomingInterviews.assignAll(results[1] as List<UpcomingInterview>);
      interviews.assignAll(results[2] as List<InterviewDetailModel>);
      jobProposals.assignAll(results[3] as List<JobProposalModel>);
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> respondToInterview(
    InterviewDetailModel interview,
    InterviewAction action, {
    String? message,
    DateTime? proposedDate,
  }) async {
    if (respondingIds.contains(interview.id)) return false;
    respondingIds.add(interview.id);
    try {
      final ok = await _repository.respondToInterview(
        interview.id,
        action: action,
        message: message,
        proposedDate: proposedDate,
      );
      if (!ok) throw Exception('interview response failed');
      AppToast.success(
          'Réponse envoyée', interview.offer?.title ?? 'Entretien');
      await load();
      return true;
    } catch (e) {
      AppToast.error('Réponse impossible', userFacingError(e));
      return false;
    } finally {
      respondingIds.remove(interview.id);
    }
  }

  Future<bool> respondToProposal(
    JobProposalModel proposal,
    JobProposalAction action, {
    String? message,
  }) async {
    if (respondingIds.contains(proposal.id)) return false;
    respondingIds.add(proposal.id);
    try {
      final ok = await _repository.respondToProposal(
        proposal.id,
        action: action,
        message: message,
      );
      if (!ok) throw Exception('proposal response failed');
      AppToast.success(
          'Réponse envoyée', proposal.offer?.title ?? 'Proposition');
      await load();
      return true;
    } catch (e) {
      AppToast.error('Réponse impossible', userFacingError(e));
      return false;
    } finally {
      respondingIds.remove(proposal.id);
    }
  }

  /// Détail complet d'une candidature (offre + entretien). Null si introuvable.
  Future<ApplicationModel?> loadDetail(String applicationId) {
    return _repository.getApplicationDetail(applicationId);
  }

  /// Désiste une candidature (retrait optimiste + rollback si l'API échoue).
  Future<bool> withdraw(String applicationId) async {
    final index = applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return false;
    final removed = applications[index];
    applications.removeAt(index);
    try {
      final ok = await _repository.withdrawApplication(applicationId);
      if (!ok) throw Exception('withdraw failed');
      AppToast.success('Candidature retirée', removed.offer?.title ?? '');
      return true;
    } catch (e) {
      applications.insert(index, removed);
      AppToast.error('Retrait impossible', userFacingError(e));
      return false;
    }
  }
}
