import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/utils/profile_completion.dart';
import 'package:baara/app/features/profile/domain/entities/profile.dart';

Profile _minimalProfile({bool complete = false}) => Profile(
      id: '1',
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.c',
      phone: '',
      country: 'BF',
      city: '',
      userType: 'candidate',
      skills: const [],
      experiences: const [],
      educations: const [],
      languages: const [],
      isProfileComplete: complete,
    );

void main() {
  test('profileCompletionPercent returns 100 when backend marks complete', () {
    final p = _minimalProfile(complete: true);
    expect(profileCompletionPercent(p), 100);
  });

  test('profileCompletionMissing lists empty fields first', () {
    final p = _minimalProfile().copyWith(
      phone: '70000000',
      city: 'Ouaga',
    );
    final missing = profileCompletionMissing(p, limit: 5);
    expect(missing.any((i) => i.label == 'Téléphone'), isFalse);
    expect(missing.any((i) => i.label == 'Photo de profil'), isTrue);
  });
}

extension on Profile {
  Profile copyWith({
    String? phone,
    String? city,
    String? headline,
  }) {
    return Profile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone ?? this.phone,
      country: country,
      city: city ?? this.city,
      userType: userType,
      avatarUrl: avatarUrl,
      headline: headline ?? this.headline,
      bio: bio,
      skills: skills,
      experiences: experiences,
      educations: educations,
      languages: languages,
      isProfileComplete: isProfileComplete,
      presentationVideoUrl: presentationVideoUrl,
    );
  }
}
