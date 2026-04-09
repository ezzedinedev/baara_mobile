class UserModel {
  const UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.userType,
  });

  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? userType;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      userType: json['user_type'] as String?,
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
