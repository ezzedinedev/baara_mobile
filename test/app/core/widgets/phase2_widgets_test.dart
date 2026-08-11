import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/services/network_status_service.dart';
import 'package:baara/app/core/widgets/common/network_status_banner.dart';
import 'package:baara/app/core/widgets/common/profile_completion_card.dart';
import 'package:baara/app/features/profile/domain/entities/profile.dart';
import 'package:baara/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:baara/app/features/profile/domain/repositories/i_profile_repository.dart';

class _FakeProfileRepo implements IProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

void main() {
  testWidgets('NetworkStatusBanner hides when online', (tester) async {
    Get.put(NetworkStatusService());
    final network = Get.find<NetworkStatusService>();
    network.isOnline.value = true;

    await tester.pumpWidget(
      GetMaterialApp(
        home: NetworkStatusBanner(
          child: const Scaffold(body: Text('content')),
        ),
      ),
    );

    expect(find.text('Hors ligne'), findsNothing);
    expect(find.text('content'), findsOneWidget);
    Get.reset();
  });

  testWidgets('NetworkStatusBanner shows offline strip', (tester) async {
    Get.put(NetworkStatusService());
    final network = Get.find<NetworkStatusService>();
    network.isOnline.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        home: NetworkStatusBanner(
          child: const Scaffold(body: Text('content')),
        ),
      ),
    );

    expect(find.textContaining('Hors ligne'), findsOneWidget);
    Get.reset();
  });

  testWidgets('ProfileCompletionCard hidden at 100%', (tester) async {
    final repo = _FakeProfileRepo();
    Get.put(ProfileController(repo));
    final ctrl = Get.find<ProfileController>();
    ctrl.profile.value = Profile(
      id: '1',
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.c',
      phone: '+226',
      country: 'BF',
      city: 'Ouaga',
      userType: 'candidate',
      avatarUrl: 'x',
      headline: 'Dev',
      bio: 'Bio',
      skills: ['Dart'],
      experiences: [
        Experience(
          id: '1',
          title: 'Dev',
          company: 'Co',
          location: 'Ouaga',
          startDate: DateTime(2020),
          isCurrent: true,
        ),
      ],
      educations: [
        Education(
          id: '1',
          degree: 'Licence',
          institution: 'Uni',
          location: 'Ouaga',
          startDate: DateTime(2018),
        ),
      ],
      languages: const [Language(id: '1', name: 'Français', level: 'C2')],
      isProfileComplete: true,
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: ProfileCompletionCard())),
    );
    await tester.pump();

    expect(find.textContaining('Profil à'), findsNothing);
    Get.reset();
  });
}
