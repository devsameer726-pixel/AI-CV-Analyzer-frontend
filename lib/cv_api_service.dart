import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AnalysisResult {
  final double atsScore;
  final String predictedCategory;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> recommendations;

  AnalysisResult({
    required this.atsScore,
    required this.predictedCategory,
    required this.matchedSkills,
    required this.missingSkills,
    required this.recommendations,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      atsScore: (json['ats_score'] as num).toDouble(),
      predictedCategory: json['predicted_category'] ?? '',
      matchedSkills: List<String>.from(json['matched_skills'] ?? []),
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class CvApiService {
  static const String apiUrl = 'http://127.0.0.1:8000/analyze';

  static Future<AnalysisResult> analyzeCv({
    required Uint8List fileBytes,
    required String fileName,
    required String jobDescription,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );
    request.fields['job_description'] = jobDescription;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Server returned ${response.statusCode}: ${response.body}');
    }
  }
}
