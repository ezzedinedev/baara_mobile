import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/features/offers/data/models/application_model.dart';
import 'package:opportune_bf/app/features/offers/data/models/upcoming_interview_model.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/offer.dart';
import 'package:opportune_bf/app/features/offers/domain/repositories/i_offer_repository.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_detail_controller.dart';

class _FakeOfferRepository implements IOfferRepository {
  Offer? offerById;

  @override
  Future<Offer?> getOfferById(String id) async => offerById;

  @override
  Future<List<Offer>> getOffers({int page = 1, int perPage = 20}) async => [];

  @override
  Future<List<Offer>> getFeaturedOffers() async => [];

  @override
  Future<bool> saveOffer(String offerId) async => true;

  @override
  Future<bool> unsaveOffer(String offerId) async => true;

  @override
  Future<ApplicationModel> applyToOffer(
    String offerId, {
    Map<String, dynamic>? screeningAnswers,
  }) async {
    return ApplicationModel(
      id: 'app-1',
      offerId: offerId,
      candidateId: 'cand-1',
      status: ApplicationStatus.newApp,
      appliedAt: DateTime.now(),
      aiMatchScore: 0,
      screeningScore: 0,
    );
  }

  @override
  Future<List<ApplicationModel>> getMyApplications({
    int page = 1,
    int perPage = 20,
  }) async =>
      [];

  @override
  Future<List<UpcomingInterview>> getUpcomingInterviews() async => [];
}

void main() {
  late OfferDetailController controller;
  late _FakeOfferRepository fakeOfferRepo;

  setUp(() {
    fakeOfferRepo = _FakeOfferRepository();
    controller = OfferDetailController(fakeOfferRepo);
  });

  group('OfferDetailController', () {
    test('fetches offer successfully', () async {
      fakeOfferRepo.offerById = const Offer(
        id: '1',
        title: 'Dev Flutter',
        company: 'Opportune',
        description: 'Desc',
        location: 'Ouaga',
        salary: '400 000 FCFA',
        contractType: 'CDI',
        requiredSkills: ['Flutter'],
        minYearsExperience: 2,
        sector: 'Informatique',
        isRemote: false,
      );

      await controller.fetchOfferDetail('1');

      expect(controller.offer.value?.id, '1');
      expect(controller.isLoading.value, false);
    });

    test('handles missing offer correctly', () async {
      fakeOfferRepo.offerById = null;

      await controller.fetchOfferDetail('1');

      expect(controller.offer.value, null);
      expect(controller.errorMessage.value, 'Offre introuvable');
    });
  });
}
