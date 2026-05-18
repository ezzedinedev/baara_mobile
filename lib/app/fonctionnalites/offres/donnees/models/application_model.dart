import 'interview_details_model.dart';
import 'offer_model.dart';

/// Statuts alignés avec le backend Laravel (table `applications.status`).
/// Ne pas renommer sans vérifier le web — les libellés viennent du serveur.
enum ApplicationStatus {
  newApp('new'),
  shortlisted('shortlisted'),
  evaluation('evaluation'),
  interview('interview'),
  offer('offer'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const ApplicationStatus(this.value);
  final String value;

  static ApplicationStatus fromString(String? raw) {
    if (raw == null) return ApplicationStatus.newApp;
    for (final s in ApplicationStatus.values) {
      if (s.value == raw) return s;
    }
    return ApplicationStatus.newApp;
  }

  String get label {
    switch (this) {
      case ApplicationStatus.newApp:
        return 'Nouvelle';
      case ApplicationStatus.shortlisted:
        return 'Présélectionnée';
      case ApplicationStatus.evaluation:
        return 'En évaluation';
      case ApplicationStatus.interview:
        return 'Entretien';
      case ApplicationStatus.offer:
        return 'Offre reçue';
      case ApplicationStatus.rejected:
        return 'Rejetée';
      case ApplicationStatus.withdrawn:
        return 'Retirée';
    }
  }
}

/// Modèle miroir de `App\Models\Application` côté backend Laravel.
/// Le snapshot CV et les métadonnées recruteur ne sont pas exposés côté candidat.
class ApplicationModel {
  const ApplicationModel({
    required this.id,
    required this.offerId,
    required this.candidateId,
    required this.status,
    required this.appliedAt,
    this.aiMatchScore,
    this.screeningScore,
    this.rejectionReason,
    this.offer,
    this.interviewDate,
    this.interviewType,
    this.interviewLocation,
    this.interviewInstructions,
    this.interviewLat,
    this.interviewLng,
    this.useCompanyLocation,
    this.interviewDetails,
  });

  final String id;
  final String offerId;
  final String candidateId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final double? aiMatchScore;
  final double? screeningScore;
  final String? rejectionReason;
  final OfferModel? offer;

  // ----- Champs entretien (smart location) --------------------------------
  // Bruts : refletent la table `applications` exposee par l'API quand on
  // ne consomme pas le payload "interview" agrege par le backend.
  final DateTime? interviewDate;
  final InterviewType? interviewType;
  final String? interviewLocation;
  final String? interviewInstructions;
  final double? interviewLat;
  final double? interviewLng;
  final bool? useCompanyLocation;

  // Agrege : version "effective" calculee par le backend (resolution
  // use_company_location vs lat/lng custom + deep links + QR). Disponible
  // seulement sur la reponse de GET /applications/{id} et upcoming.
  final InterviewDetails? interviewDetails;

  bool get isRejected => status == ApplicationStatus.rejected;
  bool get isPending => status == ApplicationStatus.newApp;

  /// True si un entretien est programme (le backend pose status=interview
  /// quand un entretien est planifie via scheduleInterview).
  bool get hasInterview =>
      status == ApplicationStatus.interview && interviewDate != null;

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id']?.toString() ?? '',
      offerId: json['offer_id']?.toString() ?? '',
      candidateId: json['candidate_id']?.toString() ?? '',
      status: ApplicationStatus.fromString(json['status']?.toString()),
      appliedAt: _parseDate(json['applied_at'] ?? json['created_at']) ??
          DateTime.now(),
      aiMatchScore: _parseDouble(json['ai_match_score']),
      screeningScore: _parseDouble(json['screening_score']),
      rejectionReason: json['rejection_reason']?.toString(),
      offer: json['offer'] is Map<String, dynamic>
          ? OfferModel.fromJson(json['offer'] as Map<String, dynamic>)
          : null,
      interviewDate: _parseDate(json['interview_date']),
      interviewType: json['interview_type'] == null
          ? null
          : InterviewType.fromString(json['interview_type']?.toString()),
      interviewLocation: _emptyToNull(json['interview_location']),
      interviewInstructions: _emptyToNull(json['interview_instructions']),
      interviewLat: _parseDouble(json['interview_lat']),
      interviewLng: _parseDouble(json['interview_lng']),
      useCompanyLocation: json['use_company_location'] == null
          ? null
          : json['use_company_location'] == true ||
              json['use_company_location'] == 1,
    );
  }

  ApplicationModel copyWith({
    InterviewDetails? interviewDetails,
  }) {
    return ApplicationModel(
      id: id,
      offerId: offerId,
      candidateId: candidateId,
      status: status,
      appliedAt: appliedAt,
      aiMatchScore: aiMatchScore,
      screeningScore: screeningScore,
      rejectionReason: rejectionReason,
      offer: offer,
      interviewDate: interviewDate,
      interviewType: interviewType,
      interviewLocation: interviewLocation,
      interviewInstructions: interviewInstructions,
      interviewLat: interviewLat,
      interviewLng: interviewLng,
      useCompanyLocation: useCompanyLocation,
      interviewDetails: interviewDetails ?? this.interviewDetails,
    );
  }

  static String? _emptyToNull(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Raisons d'échec qu'une candidature peut rencontrer, typées pour permettre
/// à l'UI d'afficher le bon message et de proposer la bonne action corrective.
enum ApplyFailureReason {
  network,
  unauthorized,
  notCandidate,
  alreadyApplied,
  deadlinePassed,
  offerNotActive,
  noCv,
  invalidOffer,
  unknown,
}

/// Résultat d'une tentative de candidature. Soit une application créée côté serveur,
/// soit une raison d'échec + message friendly.
class ApplyResult {
  const ApplyResult._({this.application, this.reason, this.message});

  final ApplicationModel? application;
  final ApplyFailureReason? reason;
  final String? message;

  bool get isSuccess => application != null;
  bool get isFailure => reason != null;

  factory ApplyResult.success(ApplicationModel application) =>
      ApplyResult._(application: application);

  factory ApplyResult.failure(ApplyFailureReason reason, String message) =>
      ApplyResult._(reason: reason, message: message);
}

/// Exception typée levée par le repository. Le controller la convertit
/// en `ApplyResult.failure` pour l'UI.
class ApplyException implements Exception {
  const ApplyException(this.reason, this.message);

  final ApplyFailureReason reason;
  final String message;

  @override
  String toString() => 'ApplyException(${reason.name}): $message';
}
