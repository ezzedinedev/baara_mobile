/// Entretien à venir — miroir exact du payload backend
/// `ApplicationApiController@upcomingInterviews`
/// (GET /applications/interviews/upcoming).
class UpcomingInterview {
  final String applicationId;
  final String offerTitle;
  final String? contractType;
  final String? companyName;
  final String? companyLogoUrl;
  final InterviewInfo? interview;

  const UpcomingInterview({
    required this.applicationId,
    required this.offerTitle,
    this.contractType,
    this.companyName,
    this.companyLogoUrl,
    this.interview,
  });

  factory UpcomingInterview.fromJson(Map<String, dynamic> json) {
    final offer = json['offer'] as Map<String, dynamic>?;
    final employer = json['employer'] as Map<String, dynamic>?;
    final interview = json['interview'] as Map<String, dynamic>?;
    return UpcomingInterview(
      applicationId: json['application_id']?.toString() ?? '',
      offerTitle: offer?['title']?.toString() ?? '',
      contractType: offer?['contract_type']?.toString(),
      companyName: employer?['company_name']?.toString(),
      companyLogoUrl: employer?['logo_url']?.toString(),
      interview:
          interview == null ? null : InterviewInfo.fromJson(interview),
    );
  }
}

class InterviewInfo {
  final DateTime? date;
  final String? dateHuman;
  final String? type;
  final String? address;
  final String? instructions;
  final double? lat;
  final double? lng;
  final bool hasCoordinates;
  final String? googleMapsUrl;
  final String? wazeUrl;
  final String? appleMapsUrl;
  final String? icsUrl;

  const InterviewInfo({
    this.date,
    this.dateHuman,
    this.type,
    this.address,
    this.instructions,
    this.lat,
    this.lng,
    this.hasCoordinates = false,
    this.googleMapsUrl,
    this.wazeUrl,
    this.appleMapsUrl,
    this.icsUrl,
  });

  factory InterviewInfo.fromJson(Map<String, dynamic> json) {
    final nav = json['navigation'] as Map<String, dynamic>?;
    return InterviewInfo(
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      dateHuman: json['date_human']?.toString(),
      type: json['type']?.toString(),
      address: json['address']?.toString(),
      instructions: json['instructions']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      hasCoordinates: json['has_coordinates'] == true,
      googleMapsUrl: nav?['google_maps']?.toString(),
      wazeUrl: nav?['waze']?.toString(),
      appleMapsUrl: nav?['apple_maps']?.toString(),
      icsUrl: json['ics_url']?.toString(),
    );
  }
}
