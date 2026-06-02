import '../entities/offer.dart';
import '../../data/models/application_model.dart';
import '../../data/models/upcoming_interview_model.dart';

abstract class IOfferRepository {
  Future<List<Offer>> getOffers({int page = 1, int perPage = 20});
  Future<Offer?> getOfferById(String id);
  Future<List<Offer>> getFeaturedOffers();
  Future<bool> saveOffer(String offerId);
  Future<bool> unsaveOffer(String offerId);

  // Applications
  Future<ApplicationModel> applyToOffer(String offerId, {Map<String, dynamic>? screeningAnswers});
  Future<List<ApplicationModel>> getMyApplications({int page = 1, int perPage = 20});

  /// Entretiens à venir (géoloc + itinéraire + .ics).
  /// GET /applications/interviews/upcoming.
  Future<List<UpcomingInterview>> getUpcomingInterviews();
}
