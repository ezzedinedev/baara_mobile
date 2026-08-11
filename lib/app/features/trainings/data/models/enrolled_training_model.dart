import 'package:baara/app/core/utils/asset_url.dart';

import '../../domain/entities/enrolled_training.dart';
import 'training_model.dart';

/// Décode une ligne de `GET /trainings/enrolled/list` (paginator Laravel de
/// TrainingEnrollment, relation `training` chargée en résumé).
class EnrolledTrainingModel extends EnrolledTraining {
  const EnrolledTrainingModel({
    required super.enrollmentId,
    required super.training,
    required super.progressPct,
    required super.isCompleted,
    required super.completedModuleIds,
    super.enrolledAt,
    super.completedAt,
    super.certificateUrl,
    super.paymentStatus,
  });

  factory EnrolledTrainingModel.fromJson(Map<String, dynamic> json) {
    // La formation peut manquer si elle a été supprimée : on retombe sur un
    // objet minimal plutôt que de faire échouer toute la liste.
    final rawTraining = json['training'];
    final trainingJson = rawTraining is Map<String, dynamic>
        ? rawTraining
        : <String, dynamic>{'id': json['training_id']?.toString() ?? ''};

    return EnrolledTrainingModel(
      enrollmentId: json['id']?.toString() ?? '',
      training: TrainingModel.fromJson(trainingJson),
      progressPct: _asInt(json['progress_pct']),
      isCompleted: json['is_completed'] == true,
      completedModuleIds: _asStringList(json['modules_completed']),
      enrolledAt: _asDate(json['enrolled_at']),
      completedAt: _asDate(json['completed_at']),
      certificateUrl: _asUrl(json['certificate_url']),
      paymentStatus: json['payment_status']?.toString(),
    );
  }

  /// `resolveAssetUrl` n'accepte pas de null : on filtre en amont.
  static String? _asUrl(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return resolveAssetUrl(raw);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _asDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
