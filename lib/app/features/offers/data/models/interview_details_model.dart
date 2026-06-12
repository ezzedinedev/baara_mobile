class InterviewDetails {
  final String id;
  final DateTime scheduledAt;
  final String location;
  final String? notes;
  final InterviewNavigation navigation;

  const InterviewDetails({
    required this.id,
    required this.scheduledAt,
    required this.location,
    this.notes,
    required this.navigation,
  });

  factory InterviewDetails.fromJson(Map<String, dynamic> json) {
    return InterviewDetails(
      id: json['id']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ??
          DateTime.now(),
      location: json['location'] ?? '',
      notes: json['notes'],
      navigation: InterviewNavigation.fromJson(json['navigation'] ?? {}),
    );
  }
}

class InterviewNavigation {
  final String? googleMapsUrl;
  final String? wazeUrl;
  final String? appleMapsUrl;

  const InterviewNavigation({
    this.googleMapsUrl,
    this.wazeUrl,
    this.appleMapsUrl,
  });

  factory InterviewNavigation.fromJson(Map<String, dynamic> json) {
    return InterviewNavigation(
      googleMapsUrl: json['google_maps_url'],
      wazeUrl: json['waze_url'],
      appleMapsUrl: json['apple_maps_url'],
    );
  }
}
