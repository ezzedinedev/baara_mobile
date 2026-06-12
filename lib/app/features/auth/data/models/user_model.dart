import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final composedName = [json['first_name'], json['last_name']]
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .join(' ');
    final directName = json['name']?.toString().trim() ?? '';

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: directName.isNotEmpty ? directName : composedName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      userType: (json['user_type'] ?? json['type'] ?? 'candidate').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user_type': userType,
    };
  }
}
