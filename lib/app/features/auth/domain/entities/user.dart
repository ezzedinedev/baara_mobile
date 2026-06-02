class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String userType;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
  });

  bool get isCandidate => userType == 'candidate';
  bool get isRecruiter => userType == 'recruiter';
}
