/// Entretien du pipeline (invitation -> reponse candidat) — miroir exact du
/// payload `Api/V1/InterviewApiController@formatInterview`
/// (GET /applications/interviews[/{id}], POST .../respond).
class InterviewDetailModel {
  final String id;
  // pending_candidate | confirmed | declined | rescheduled | completed | cancelled
  final String status;
  final String statusLabel;
  final String? type; // onsite | video | phone
  final String? typeLabel;
  final DateTime? scheduledAt;
  final String? location;
  final String? instructions;
  final String? qrCode;
  final String? qrCodeUrl;
  final InterviewOfferRef? offer;
  final String? applicationId;
  final List<InterviewAction> actions;

  const InterviewDetailModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    this.type,
    this.typeLabel,
    this.scheduledAt,
    this.location,
    this.instructions,
    this.qrCode,
    this.qrCodeUrl,
    this.offer,
    this.applicationId,
    this.actions = const [],
  });

  bool get canRespond => actions.isNotEmpty;

  factory InterviewDetailModel.fromJson(Map<String, dynamic> json) {
    final offer = json['offer'] as Map<String, dynamic>?;
    return InterviewDetailModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      type: json['type']?.toString(),
      typeLabel: json['type_label']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
      location: json['location']?.toString(),
      instructions: json['instructions']?.toString(),
      qrCode: (json['qr_code'] ?? json['qr'])?.toString(),
      qrCodeUrl: (json['qr_code_url'] ?? json['qr_url'])?.toString(),
      offer: offer == null ? null : InterviewOfferRef.fromJson(offer),
      applicationId: json['application_id']?.toString(),
      actions: ((json['actions'] as List?) ?? const [])
          .map((a) => InterviewActionX.fromWire(a?.toString()))
          .whereType<InterviewAction>()
          .toList(),
    );
  }

  bool get hasQr => (qrCodeUrl ?? qrCode ?? '').isNotEmpty;
}

class InterviewOfferRef {
  final String id;
  final String title;
  final String? city;
  final String? contractType;
  final String? companyName;
  final String? logoUrl;

  const InterviewOfferRef({
    required this.id,
    required this.title,
    this.city,
    this.contractType,
    this.companyName,
    this.logoUrl,
  });

  factory InterviewOfferRef.fromJson(Map<String, dynamic> j) =>
      InterviewOfferRef(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        city: j['city']?.toString(),
        contractType: j['contract_type']?.toString(),
        companyName: j['company_name']?.toString(),
        logoUrl: j['logo_url']?.toString(),
      );
}

/// Réponse du candidat à une invitation (backend: in:accept,decline,reschedule).
enum InterviewAction { accept, decline, reschedule }

extension InterviewActionX on InterviewAction {
  /// Valeur envoyée au backend (champ `action`).
  String get wire => name;

  static InterviewAction? fromWire(String? value) {
    switch (value) {
      case 'accept':
        return InterviewAction.accept;
      case 'decline':
        return InterviewAction.decline;
      case 'reschedule':
        return InterviewAction.reschedule;
      default:
        return null;
    }
  }
}
