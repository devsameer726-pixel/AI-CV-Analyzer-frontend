/// Data models for the AI CV Analyzer.
///
/// These mirror the JSON shape returned by the FastAPI `/analyze` endpoint:
/// `ats_score`, `predicted_category`, `matched_skills`, `missing_skills`,
/// and `recommendations`. Optional fields (`metrics`, `experience`,
/// `keywords`, `summary`) are also parsed when present.
library;

import 'package:flutter/material.dart';

class MetricScore {
  final String key;
  final String label;
  final double value; // 0..100
  final String description;

  const MetricScore({
    required this.key,
    required this.label,
    required this.value,
    required this.description,
  });

  factory MetricScore.fromJson(Map<String, dynamic> j) => MetricScore(
        key: j['key'] as String? ?? '',
        label: j['label'] as String? ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
        description: j['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value': value,
        'description': description,
      };
}

class SkillTag {
  final String name;
  final bool matched;
  final String? recommendation;

  const SkillTag({
    required this.name,
    required this.matched,
    this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'matched': matched,
        'recommendation': recommendation,
      };
}

class ExperienceSlice {
  final String label;
  final double years;

  const ExperienceSlice({required this.label, required this.years});

  factory ExperienceSlice.fromJson(Map<String, dynamic> j) => ExperienceSlice(
        label: j['label'] as String? ?? '',
        years: (j['years'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'label': label, 'years': years};
}

class KeywordDensity {
  final String keyword;
  final int count;

  const KeywordDensity({required this.keyword, required this.count});

  factory KeywordDensity.fromJson(Map<String, dynamic> j) => KeywordDensity(
        keyword: j['keyword'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'keyword': keyword, 'count': count};
}

class Recommendation {
  final String id;
  final String title;
  final String detail;
  final RecommendationSeverity severity;

  const Recommendation({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
  });

  factory Recommendation.fromJson(Map<String, dynamic> j) => Recommendation(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        detail: j['detail'] as String? ?? '',
        severity: RecommendationSeverity.values.firstWhere(
          (s) => s.name == j['severity'],
          orElse: () => RecommendationSeverity.info,
        ),
      );

  /// Tolerant parser: accepts a JSON object or a plain string from the API.
  factory Recommendation.fromAny(dynamic e) {
    if (e is Map<String, dynamic>) return Recommendation.fromJson(e);
    if (e is String) {
      return Recommendation(
        id: '',
        title: e,
        detail: '',
        severity: RecommendationSeverity.info,
      );
    }
    return const Recommendation(
        id: '', title: '', detail: '', severity: RecommendationSeverity.info);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'severity': severity.name,
      };
}

enum RecommendationSeverity { info, warning, critical }

extension RecommendationSeverityX on RecommendationSeverity {
  Color get color => switch (this) {
        RecommendationSeverity.info => const Color(0xFF48CAE4),
        RecommendationSeverity.warning => const Color(0xFFFACC15),
        RecommendationSeverity.critical => const Color(0xFFF87171),
      };

  IconData get icon => switch (this) {
        RecommendationSeverity.info => Icons.lightbulb_outline,
        RecommendationSeverity.warning => Icons.warning_amber_rounded,
        RecommendationSeverity.critical => Icons.error_outline_rounded,
      };
}

class AnalysisResult {
  /// null when the API did not return an ATS score.
  final double? atsScore;
  final String predictedCategory;
  final List<MetricScore> metrics;
  final List<SkillTag> skills;
  final List<ExperienceSlice> experience;
  final List<KeywordDensity> keywords;
  final List<Recommendation> recommendations;
  final String summary;

  const AnalysisResult({
    required this.atsScore,
    required this.predictedCategory,
    required this.metrics,
    required this.skills,
    required this.experience,
    required this.keywords,
    required this.recommendations,
    required this.summary,
  });

  /// Whether the response contains any meaningful analysis data at all.
  bool get hasData =>
      atsScore != null ||
      predictedCategory.isNotEmpty ||
      skills.isNotEmpty ||
      recommendations.isNotEmpty ||
      metrics.isNotEmpty ||
      experience.isNotEmpty ||
      keywords.isNotEmpty ||
      summary.isNotEmpty;

  /// Parses the FastAPI response:
  ///   { ats_score, predicted_category, matched_skills, missing_skills,
  ///     recommendations, [metrics, experience, keywords, summary] }
  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    final skills = <SkillTag>[];
    if (j.containsKey('matched_skills') || j.containsKey('missing_skills')) {
      for (final s in (j['matched_skills'] as List?) ?? const []) {
        skills.add(SkillTag(name: s as String, matched: true));
      }
      for (final s in (j['missing_skills'] as List?) ?? const []) {
        skills.add(SkillTag(
            name: s as String, matched: false, recommendation: 'Add $s'));
      }
    } else if (j['skills'] is List) {
      for (final e in j['skills'] as List) {
        final m = e as Map<String, dynamic>;
        skills.add(SkillTag(
          name: m['name'] as String? ?? '',
          matched: m['matched'] as bool? ?? false,
          recommendation: m['recommendation'] as String?,
        ));
      }
    }

    return AnalysisResult(
      atsScore: (j['ats_score'] as num?)?.toDouble(),
      predictedCategory: j['predicted_category'] as String? ?? '',
      metrics: (j['metrics'] as List?)
              ?.map((e) => MetricScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      skills: skills,
      experience: (j['experience'] as List?)
              ?.map((e) => ExperienceSlice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      keywords: (j['keywords'] as List?)
              ?.map((e) => KeywordDensity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recommendations: (j['recommendations'] as List?)
              ?.map((e) => Recommendation.fromAny(e))
              .toList() ??
          const [],
      summary: j['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ats_score': atsScore,
        'predicted_category': predictedCategory,
        'metrics': metrics.map((e) => e.toJson()).toList(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'keywords': keywords.map((e) => e.toJson()).toList(),
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
        'summary': summary,
      };
}
