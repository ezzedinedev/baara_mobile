/// Format d'entretien — aligné avec `applications.interview_type` côté backend.
enum InterviewType {
  onsite('onsite', 'Présentiel'),
  video('video', 'Visio'),
  phone('phone', 'Téléphone'),
  unknown('unknown', 'Non précisé');

  const InterviewType(this.value, this.label);

  final String value;
  final String label;

  static InterviewType fromString(String? raw) {
    if (raw == null) return InterviewType.unknown;
    for (final t in InterviewType.values) {
      if (t.value == raw) return t;
    }
    return InterviewType.unknown;
  }
}

/// Deep links d'itinéraire fournis par le backend pour ouvrir un GPS natif.
/// Tous les champs peuvent être null si l'entretien n'a pas de coordonnées GPS.
class InterviewNavigation {
  const InterviewNavigation({
    this.googleMapsUrl,
    this.wazeUrl,
    this.appleMapsUrl,
  });

  final String? googleMapsUrl;
  final String? wazeUrl;
  final String? appleMapsUrl;

  bool get hasAny =>
      googleMapsUrl != null || wazeUrl != null || appleMapsUrl != null;

  factory InterviewNavigation.fromJson(Map<String, dynamic> json) {
    return InterviewNavigation(
      googleMapsUrl: json['google_maps']?.toString(),
      wazeUrl: json['waze']?.toString(),
      appleMapsUrl: json['apple_maps']?.toString(),
    );
  }
}

/// Détails effectifs d'un entretien — payload renvoyé par
/// `GET /applications/{id}` et `GET /applications/interviews/upcoming`.
/// La résolution use_company_location vs custom est faite côté serveur :
/// les `lat`/`lng`/`address`/`instructions` ici sont les valeurs effectives
/// à afficher tel quel au candidat.
class InterviewDetails {
  const InterviewDetails({
    required this.date,
    this.dateHuman,
    required this.type,
    required this.useCompanyLocation,
    this.address,
    this.instructions,
    this.lat,
    this.lng,
    this.navigation,
    this.icsUrl,
    this.qrPayload,
  });

  final DateTime date;
  final String? dateHuman;
  final InterviewType type;
  final bool useCompanyLocation;
  final String? address;
  final String? instructions;
  final double? lat;
  final double? lng;
  final InterviewNavigation? navigation;
  final String? icsUrl;
  final String? qrPayload;

  bool get hasCoordinates => lat != null && lng != null;
  bool get isOnsite => type == InterviewType.onsite;
  bool get isUpcoming => date.isAfter(DateTime.now());

  factory InterviewDetails.fromJson(Map<String, dynamic> json) {
    return InterviewDetails(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      dateHuman: json['date_human']?.toString(),
      type: InterviewType.fromString(json['type']?.toString()),
      useCompanyLocation: json['use_company_location'] == true,
      address: _emptyToNull(json['address']),
      instructions: _emptyToNull(json['instructions']),
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      navigation: json['navigation'] is Map<String, dynamic>
          ? InterviewNavigation.fromJson(
              json['navigation'] as Map<String, dynamic>,
            )
          : null,
      icsUrl: _emptyToNull(json['ics_url']),
      qrPayload: _emptyToNull(json['qr_payload']),
    );
  }

  static String? _emptyToNull(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Entrée de la liste "Mes entretiens à venir" — agrège l'application, l'offre
/// minimale, l'employer minimal et les détails d'entretien complets.
class UpcomingInterview {
  const UpcomingInterview({
    required this.applicationId,
    required this.offerId,
    required this.offerTitle,
    this.contractType,
    this.employerId,
    this.employerName,
    this.employerLogoUrl,
    required this.interview,
  });

  final String applicationId;
  final String offerId;
  final String offerTitle;
  final String? contractType;
  final String? employerId;
  final String? employerName;
  final String? employerLogoUrl;
  final InterviewDetails interview;

  factory UpcomingInterview.fromJson(Map<String, dynamic> json) {
    final offer = json['offer'] is Map<String, dynamic>
        ? json['offer'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final employer = json['employer'] is Map<String, dynamic>
        ? json['employer'] as Map<String, dynamic>
        : null;
    final interviewRaw = json['interview'] is Map<String, dynamic>
        ? json['interview'] as Map<String, dynamic>
        : <String, dynamic>{};

    return UpcomingInterview(
      applicationId: json['application_id']?.toString() ?? '',
      offerId: offer['id']?.toString() ?? '',
      offerTitle: offer['title']?.toString() ?? '',
      contractType: offer['contract_type']?.toString(),
      employerId: employer?['id']?.toString(),
      employerName: employer?['company_name']?.toString(),
      employerLogoUrl: employer?['logo_url']?.toString(),
      interview: InterviewDetails.fromJson(interviewRaw),
    );
  }
}
