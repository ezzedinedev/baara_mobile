import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/features/offers/data/models/application_model.dart';
import 'package:jobaway/app/features/offers/data/models/upcoming_interview_model.dart';
import 'package:jobaway/app/features/offers/data/models/interview_detail_model.dart';
import 'package:jobaway/app/features/offers/data/models/job_proposal_model.dart';
import 'package:jobaway/app/features/offers/domain/entities/apply_result.dart';
import 'package:jobaway/app/features/offers/domain/entities/offer.dart';
import 'package:jobaway/app/features/offers/domain/entities/matched_offer.dart';
import 'package:jobaway/app/features/offers/domain/entities/sector_option.dart';
import 'package:jobaway/app/features/offers/domain/repositories/i_offer_repository.dart';
import 'package:jobaway/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:jobaway/app/features/offers/presentation/pages/match_celebration_screen.dart';
import 'package:jobaway/routes/app_routes.dart';

class _FakeOfferRepository implements IOfferRepository {
  _FakeOfferRepository({this.isMatch = false, this.score = 0});

  final bool isMatch;
  final int score;
  int applyCallCount = 0;

  @override
  Future<ApplyResult> applyToOffer(
    String offerId, {
    Map<String, dynamic>? screeningAnswers,
  }) async {
    applyCallCount++;
    return ApplyResult(
      application: ApplicationModel(
        id: 'app-1',
        offerId: offerId,
        candidateId: 'cand-1',
        status: ApplicationStatus.newApp,
        appliedAt: DateTime.now(),
        aiMatchScore: score.toDouble(),
        screeningScore: 0,
      ),
      isMatch: isMatch,
      score: score,
    );
  }

  @override
  Future<Offer?> getOfferById(String id) async => null;

  @override
  Future<List<Offer>> getOffers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? sectorId,
    String? contractType,
    String? city,
    String? region,
    bool? isRemote,
    int? salaryMin,
    String? sort,
  }) async =>
      [];

  @override
  Future<List<SectorOption>> getSectors() async => [];

  @override
  Future<List<Offer>> getFeaturedOffers() async => [];

  @override
  Future<List<MatchedOffer>> getMatchedOffers({int limit = 20}) async => [];

  @override
  Future<bool> saveOffer(String offerId) async => true;

  @override
  Future<bool> unsaveOffer(String offerId) async => true;

  @override
  Future<List<Offer>> getSavedOffers() async => [];

  @override
  Future<List<ApplicationModel>> getMyApplications({
    int page = 1,
    int perPage = 20,
  }) async =>
      [];

  @override
  Future<ApplicationModel?> getApplicationDetail(String id) async => null;

  @override
  Future<bool> withdrawApplication(String id) async => true;

  @override
  Future<List<UpcomingInterview>> getUpcomingInterviews() async => [];

  @override
  Future<List<InterviewDetailModel>> getInterviews() async => [];

  @override
  Future<InterviewDetailModel?> getInterviewDetail(String id) async => null;

  @override
  Future<bool> respondToInterview(
    String id, {
    required InterviewAction action,
    String? message,
    DateTime? proposedDate,
  }) async =>
      true;

  @override
  Future<List<JobProposalModel>> getJobProposals() async => [];

  @override
  Future<JobProposalModel?> getJobProposalDetail(String id) async => null;

  @override
  Future<bool> respondToProposal(
    String id, {
    required JobProposalAction action,
    String? message,
  }) async =>
      true;
}

const _offer = Offer(
  id: '42',
  title: 'Dev Flutter',
  company: 'JobAway',
  description: 'Desc',
  location: 'Ouaga',
  salary: '400 000 FCFA',
  contractType: 'CDI',
  requiredSkills: ['Flutter'],
  minYearsExperience: 2,
  sector: 'Informatique',
  isRemote: false,
);

/// Monte un shell GetX minimal : page d'accueil neutre + une page stub sur la
/// route de célébration (le vrai écran anime en boucle, il ferait timeout).
Future<OfferController> _pumpShell(
  WidgetTester tester,
  _FakeOfferRepository repo,
) async {
  final controller = Get.put(OfferController(repo));
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/accueil',
      getPages: [
        GetPage(name: '/accueil', page: () => const Scaffold(body: SizedBox())),
        GetPage(
          name: AppRoutes.offerMatch,
          page: () => const Scaffold(body: Text('CELEBRATION')),
        ),
      ],
    ),
  );
  controller.offers.assignAll([_offer]);
  return controller;
}

/// Répond à la feuille de confirmation ouverte par un swipe droite.
Future<void> _answerConfirmSheet(WidgetTester tester,
    {required bool confirm}) async {
  await tester.pumpAndSettle();
  expect(find.text('Postuler chez JobAway ?'), findsOneWidget);
  await tester.tap(find.text(confirm ? 'Postuler' : 'Annuler'));
  await tester.pumpAndSettle();
}

/// Laisse le swipe (210 ms) puis la candidature `unawaited` se résoudre.
Future<void> _settleSwipe(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
  await tester.pump();
}

/// Le snackbar GetX garde un Ticker actif sur l'Overlay : sans fermeture
/// explicite, le teardown du widget tree lève « disposed with an active
/// Ticker ».
Future<void> _drainToasts(WidgetTester tester) async {
  Get.closeAllSnackbars();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  tearDown(Get.reset);

  group('OfferController — swipe droite', () {
    testWidgets('confirmée sur un match, ouvre l\'écran de célébration',
        (tester) async {
      final repo = _FakeOfferRepository(isMatch: true, score: 82);
      final controller = await _pumpShell(tester, repo);

      controller.swipeOfferRight();
      await _answerConfirmSheet(tester, confirm: true);
      await _settleSwipe(tester);

      expect(repo.applyCallCount, 1);
      expect(Get.currentRoute, AppRoutes.offerMatch);
      expect(find.text('CELEBRATION'), findsOneWidget);

      final args = Get.arguments as Map<String, dynamic>;
      expect(args['score'], 82);
      expect(args['offerTitle'], 'Dev Flutter');
      expect(args['company'], 'JobAway');
    });

    testWidgets('confirmée sans match, on reste sur le deck', (tester) async {
      final repo = _FakeOfferRepository(isMatch: false, score: 12);
      final controller = await _pumpShell(tester, repo);

      controller.swipeOfferRight();
      await _answerConfirmSheet(tester, confirm: true);
      await _settleSwipe(tester);

      expect(repo.applyCallCount, 1);
      expect(Get.currentRoute, '/accueil');
      expect(controller.appliedOfferIds, contains('42'));

      await _drainToasts(tester);
    });

    testWidgets('annulée, aucune candidature et la carte revient au centre',
        (tester) async {
      final repo = _FakeOfferRepository(isMatch: true, score: 90);
      final controller = await _pumpShell(tester, repo);
      final indexBefore = controller.currentOfferIndex.value;

      controller.swipeOfferRight();
      await _answerConfirmSheet(tester, confirm: false);
      await _settleSwipe(tester);

      expect(repo.applyCallCount, 0);
      expect(Get.currentRoute, '/accueil');
      expect(controller.appliedOfferIds, isEmpty);
      // La carte n'a pas été consommée : même offre au sommet du deck.
      expect(controller.currentOfferIndex.value, indexBefore);
      expect(controller.offerDragDx.value, 0);
      expect(controller.isOfferAnimating.value, isFalse);
    });

    testWidgets('un swipe gauche ne demande rien et ne candidate pas',
        (tester) async {
      final repo = _FakeOfferRepository(isMatch: true, score: 90);
      final controller = await _pumpShell(tester, repo);

      controller.swipeOfferLeft();
      await _settleSwipe(tester);

      expect(find.text('Postuler chez JobAway ?'), findsNothing);
      expect(repo.applyCallCount, 0);
      expect(Get.currentRoute, '/accueil');
    });
  });

  group('MatchCelebrationScreen', () {
    testWidgets('rend le contenu et ne déborde pas à fort textScale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          // `builder` : on dérive la MediaQuery réelle (taille, padding) au lieu
          // d'en fabriquer une vide, sinon `size` vaut Size.zero.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const MatchCelebrationScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('VOUS AVEZ MATCHÉ !'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Palette de confetti', () {
    // Le hero de l'écran de match est un dégradé vert : un confetti vert y est
    // invisible. C'était la cause du « la célébration n'apparaît pas ».
    test('aucune couleur du confetti de match n\'est un vert de la charte', () {
      const heroGreens = [
        AppColors.primary,
        AppColors.primaryMedium,
        AppColors.primaryDark,
        AppColors.secondary,
      ];
      for (final color in AppColors.celebrationOnBrandConfetti) {
        expect(heroGreens, isNot(contains(color)),
            reason: '$color se confond avec le dégradé de fond');
      }
    });
  });
}
