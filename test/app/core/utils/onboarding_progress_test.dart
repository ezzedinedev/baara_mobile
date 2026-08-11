import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/utils/onboarding_progress.dart';
import 'package:baara/app/features/profile/domain/entities/profile.dart';

Profile _profile({
  String? headline,
  String? avatarUrl,
  String? bio,
  List<String> skills = const [],
  List<Experience> experiences = const [],
  List<Education> educations = const [],
  String? desiredRole,
  String city = '',
}) {
  return Profile(
    id: '1',
    firstName: 'A',
    lastName: 'B',
    email: 'a@b.com',
    phone: '',
    country: 'BF',
    city: city,
    userType: 'candidate',
    avatarUrl: avatarUrl,
    headline: headline,
    bio: bio,
    skills: skills,
    experiences: experiences,
    educations: educations,
    languages: const [],
    isProfileComplete: false,
    desiredRole: desiredRole,
  );
}

void main() {
  test('onboardingProfileStepDone detects enriched profile', () {
    expect(onboardingProfileStepDone(_profile()), isFalse);
    expect(
      onboardingProfileStepDone(_profile(headline: 'Dev Flutter')),
      isTrue,
    );
  });

  test('onboardingCvStepDone detects CV-like content', () {
    expect(onboardingCvStepDone(_profile()), isFalse);
    expect(
      onboardingCvStepDone(_profile(
        experiences: [
          Experience(
            id: '1',
            title: 'Dev',
            company: 'X',
            location: 'Ouaga',
            startDate: DateTime(2020),
            isCurrent: true,
          ),
        ],
      )),
      isTrue,
    );
  });
}
