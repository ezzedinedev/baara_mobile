import '../../domain/entities/network_user.dart';

class NetworkUserModel extends NetworkUser {
  const NetworkUserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.userType,
    required super.role,
    super.avatarUrl,
    super.isFollowing,
    super.isSelf,
    super.connectionStatus,
    super.reason,
    super.mutualCount,
    super.sameSector,
    super.sameCity,
  });

  factory NetworkUserModel.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] as String?)?.trim() ?? '';
    final last = (json['last_name'] as String?)?.trim() ?? '';
    final full = (json['full_name'] as String?)?.trim();
    final rawReason = (json['reason'] as String?)?.trim();
    final mutual = json['mutual_count'];
    return NetworkUserModel(
      id: json['id']?.toString() ?? '',
      firstName: first,
      lastName: last,
      fullName: (full == null || full.isEmpty) ? '$first $last'.trim() : full,
      userType: json['user_type']?.toString() ?? 'candidate',
      role: json['role']?.toString() ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isFollowing: json['is_following'] == true,
      isSelf: json['is_self'] == true,
      connectionStatus: json['connection_status']?.toString() ?? 'none',
      reason: (rawReason == null || rawReason.isEmpty) ? null : rawReason,
      mutualCount:
          mutual is int ? mutual : int.tryParse(mutual?.toString() ?? '') ?? 0,
      sameSector: json['same_sector'] == true,
      sameCity: json['same_city'] == true,
    );
  }
}
