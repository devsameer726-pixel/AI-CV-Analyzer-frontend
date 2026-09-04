import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/analysis_result.dart';

/// Service layer that talks to the FastAPI CV analysis backend.
///
/// POSTs a multipart request (file bytes + optional `job_description`
/// text) to `<baseUrl>/analyze` and parses the JSON response into
/// [AnalysisResult]. The default [baseUrl] is `http://127.0.0.1:8000`.
///
/// There is no mock/fallback path: if the request fails or the response is
/// invalid, an exception propagates to the caller so the UI can show a real
/// error state.
class CvApiService {
  CvApiService({http.Client? client, this.baseUrl = 'http://127.0.0.1:8000'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Analyze a resume against an optional job description.
  ///
  /// Sends a multipart/form-data POST to `/analyze` with:
  ///   - file `file`: the uploaded PDF/DOCX bytes (required)
  ///   - field `job_description`: the pasted JD text (optional)
  ///
  /// Throws if [fileBytes] is null, the network fails, the HTTP status is not
  /// 200, or the response body cannot be parsed as JSON with the expected
  /// shape.
  Future<AnalysisResult> analyze({
    required Uint8List fileBytes,
    required String fileName,
    String jobDescription = '',
  }) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final request = http.MultipartRequest('POST', uri);

    if (jobDescription.trim().isNotEmpty) {
      request.fields['job_description'] = jobDescription;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: _contentTypeFor(fileName),
      ),
    );

    final streamed = await _client.send(request).timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid response: could not parse server output.');
    }

    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid response: unexpected format from server.');
    }

    final result = AnalysisResult.fromJson(body);

    if (!result.hasData) {
      throw Exception(
        'The server returned an incomplete analysis. No usable data was found.',
      );
    }

    return result;
  }

  /// Maps a filename extension to a MIME type for the multipart upload.
  MediaType _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
