// Models for AI-related responses and structured matching data.

class AiMatchScore {
  final double score;
  final double screeningScore;
  final Map<String, dynamic> breakdown;

  const AiMatchScore({
    required this.score,
    required this.screeningScore,
    required this.breakdown,
  });

  factory AiMatchScore.fromJson(Map<String, dynamic> json) {
    return AiMatchScore(
      score: (json['score'] ?? 0).toDouble(),
      screeningScore: (json['screening_score'] ?? 0).toDouble(),
      breakdown: Map<String, dynamic>.from(json['breakdown'] ?? {}),
    );
  }
}

class AiMatchFeedResponse {
  final List<Map<String, dynamic>> offers;
  final int count;
  final bool reranked;

  const AiMatchFeedResponse({
    required this.offers,
    required this.count,
    required this.reranked,
  });

  factory AiMatchFeedResponse.fromJson(Map<String, dynamic> json) {
    return AiMatchFeedResponse(
      offers: List<Map<String, dynamic>>.from(json['offers'] ?? []),
      count: json['count'] ?? 0,
      reranked: json['reranked'] ?? false,
    );
  }
}

class AiCoverLetter {
  final String fullText;
  final String tone;
  final String length;
  final List<String> warnings;

  const AiCoverLetter({
    required this.fullText,
    required this.tone,
    required this.length,
    required this.warnings,
  });

  factory AiCoverLetter.fromJson(Map<String, dynamic> json) {
    return AiCoverLetter(
      fullText: json['full_text'] ?? '',
      tone: json['tone'] ?? 'formal',
      length: json['length'] ?? 'medium',
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

class AiCvAudit {
  final int overallQuality;
  final bool atsFriendly;
  final List<String> keywordsMissing;
  final Map<String, dynamic> sections;

  const AiCvAudit({
    required this.overallQuality,
    required this.atsFriendly,
    required this.keywordsMissing,
    required this.sections,
  });

  factory AiCvAudit.fromJson(Map<String, dynamic> json) {
    return AiCvAudit(
      overallQuality: json['overall_quality'] ?? 0,
      atsFriendly: json['ats_friendly'] ?? false,
      keywordsMissing: List<String>.from(json['keywords_missing'] ?? []),
      sections: Map<String, dynamic>.from(json['sections'] ?? {}),
    );
  }
}

class AiProfileScore {
  final int overall;
  final Map<String, dynamic> breakdown;
  final List<Map<String, dynamic>> suggestions;

  const AiProfileScore({
    required this.overall,
    required this.breakdown,
    required this.suggestions,
  });

  factory AiProfileScore.fromJson(Map<String, dynamic> json) {
    return AiProfileScore(
      overall: json['overall'] ?? 0,
      breakdown: Map<String, dynamic>.from(json['breakdown'] ?? {}),
      suggestions: List<Map<String, dynamic>>.from(json['suggestions'] ?? []),
    );
  }
}

class AiChatResponse {
  final String? sessionId;
  final String reply;
  final List<Map<String, dynamic>> ctaActions;

  const AiChatResponse({
    this.sessionId,
    required this.reply,
    required this.ctaActions,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      sessionId: json['session_id'],
      reply: json['reply'] ?? '',
      ctaActions: List<Map<String, dynamic>>.from(json['cta_actions'] ?? []),
    );
  }
}
