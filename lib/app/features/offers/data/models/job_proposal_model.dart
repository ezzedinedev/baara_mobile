/// Offre d'emploi formelle reçue après l'entretien — miroir exact du payload
/// `Api/V1/JobProposalApiController@formatProposal`
/// (GET /applications/job-proposals[/{id}], POST .../respond).
class JobProposalModel {
  final String id;
  final String status; // sent | accepted | negotiating | refused
  final String statusLabel;
  final DateTime? startDate;
  final num? salary;
  final String? salaryType; // monthly | yearly
  final String? salaryFormatted;
  final String? contractType;
  final String? benefits;
  final String? message;
  final DateTime? sentAt;
  final DateTime? respondedAt;
  final JobProposalOfferRef? offer;
  final List<JobProposalAction> actions;

  const JobProposalModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    this.startDate,
    this.salary,
    this.salaryType,
    this.salaryFormatted,
    this.contractType,
    this.benefits,
    this.message,
    this.sentAt,
    this.respondedAt,
    this.offer,
    this.actions = const [],
  });

  bool get canRespond => actions.isNotEmpty;

  factory JobProposalModel.fromJson(Map<String, dynamic> json) {
    final offer = json['offer'] as Map<String, dynamic>?;
    final rawSalary = json['salary'];
    return JobProposalModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? ''),
      salary: rawSalary is num ? rawSalary : num.tryParse('${rawSalary ?? ''}'),
      salaryType: json['salary_type']?.toString(),
      salaryFormatted: json['salary_formatted']?.toString(),
      contractType: json['contract_type']?.toString(),
      benefits: json['benefits']?.toString(),
      message: json['message']?.toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? ''),
      respondedAt: DateTime.tryParse(json['responded_at']?.toString() ?? ''),
      offer: offer == null ? null : JobProposalOfferRef.fromJson(offer),
      actions: ((json['actions'] as List?) ?? const [])
          .map((a) => JobProposalActionX.fromWire(a?.toString()))
          .whereType<JobProposalAction>()
          .toList(),
    );
  }
}

class JobProposalOfferRef {
  final String id;
  final String title;
  final String? city;
  final String? companyName;
  final String? logoUrl;

  const JobProposalOfferRef({
    required this.id,
    required this.title,
    this.city,
    this.companyName,
    this.logoUrl,
  });

  factory JobProposalOfferRef.fromJson(Map<String, dynamic> j) =>
      JobProposalOfferRef(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        city: j['city']?.toString(),
        companyName: j['company_name']?.toString(),
        logoUrl: j['logo_url']?.toString(),
      );
}

/// Réponse du candidat à une offre (backend: in:accept,negotiate,refuse).
enum JobProposalAction { accept, negotiate, refuse }

extension JobProposalActionX on JobProposalAction {
  /// Valeur envoyée au backend (champ `action`).
  String get wire => name;

  static JobProposalAction? fromWire(String? value) {
    switch (value) {
      case 'accept':
        return JobProposalAction.accept;
      case 'negotiate':
        return JobProposalAction.negotiate;
      case 'refuse':
        return JobProposalAction.refuse;
      default:
        return null;
    }
  }
}
