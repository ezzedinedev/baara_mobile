import 'offer_model.dart';
import 'interview_details_model.dart';

enum ApplicationStatus {
  newApp,
  shortlisted,
  interview,
  rejected;

  static ApplicationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'new': return ApplicationStatus.newApp;
      case 'shortlisted': return ApplicationStatus.shortlisted;
      case 'interview': return ApplicationStatus.interview;
      case 'rejected': return ApplicationStatus.rejected;
      default: return ApplicationStatus.newApp;
    }
  }
}

class ApplicationModel {
  final String id;
  final String offerId;
  final String candidateId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final double aiMatchScore;
  final double screeningScore;
  final String? rejectionReason;
  final OfferModel? offer;
  final InterviewDetails? interviewDetails;

  const ApplicationModel({
    required this.id,
    required this.offerId,
    required this.candidateId,
    required this.status,
    required this.appliedAt,
    required this.aiMatchScore,
    required this.screeningScore,
    this.rejectionReason,
    this.offer,
    this.interviewDetails,
  });

  bool get isRejected => status == ApplicationStatus.rejected;

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id']?.toString() ?? '',
      offerId: json['offer_id']?.toString() ?? '',
      candidateId: json['candidate_id']?.toString() ?? '',
      status: ApplicationStatus.fromString(json['status']),
      appliedAt: DateTime.tryParse(json['applied_at'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      aiMatchScore: _parseDouble(json['ai_match_score']),
      screeningScore: _parseDouble(json['screening_score']),
      rejectionReason: json['rejection_reason'],
      offer: json['offer'] != null ? OfferModel.fromJson(json['offer']) : null,
      interviewDetails: json['interview_details'] != null ? InterviewDetails.fromJson(json['interview_details']) : null,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  ApplicationModel copyWith({InterviewDetails? interviewDetails}) {
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
      interviewDetails: interviewDetails ?? this.interviewDetails,
    );
  }
}
