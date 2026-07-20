import 'training.dart';

/// Une formation à laquelle le candidat est inscrit.
///
/// `GET /trainings/enrolled/list` renvoie des **inscriptions** (et non des
/// formations) : la progression et le certificat vivent sur l'inscription,
/// la formation n'y est imbriquée qu'en résumé (titre, format, niveau, note,
/// visuel). D'où cette entité distincte de [Training].
class EnrolledTraining {
  const EnrolledTraining({
    required this.enrollmentId,
    required this.training,
    required this.progressPct,
    required this.isCompleted,
    required this.completedModuleIds,
    this.enrolledAt,
    this.completedAt,
    this.certificateUrl,
    this.paymentStatus,
  });

  final String enrollmentId;

  /// Résumé de la formation. Le backend ne charge que
  /// `id, title, format, level, avg_rating, image_path` : les autres champs
  /// portent leurs valeurs par défaut. Pour la fiche complète, appeler
  /// `getTrainingById`.
  final Training training;

  final int progressPct;
  final bool isCompleted;
  final List<String> completedModuleIds;
  final DateTime? enrolledAt;
  final DateTime? completedAt;

  /// Renseigné une fois la formation terminée et le certificat émis.
  final String? certificateUrl;

  /// `pending` | `paid` | … (null pour les formations gratuites).
  final String? paymentStatus;

  bool get hasCertificate =>
      certificateUrl != null && certificateUrl!.trim().isNotEmpty;
}
