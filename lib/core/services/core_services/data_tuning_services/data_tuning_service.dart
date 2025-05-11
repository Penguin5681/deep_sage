import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DataTuningService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  /// Uploads a CSV file to the server for fine-tuning
  Future<Map<String, dynamic>> uploadCsv(File file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/finetune/upload_csv'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('text', 'csv'),
        filename: path.basename(file.path),
      ),
    );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      throw Exception(
        'Failed to upload CSV: ${response.statusCode}, $responseBody',
      );
    }
  }

  /// Generates auto-prompted JSONL from the uploaded CSV
  Future<Map<String, dynamic>> generateAutoPromptJsonl(String fileId) async {
    var response = await http.post(
      Uri.parse('$baseUrl/api/finetune/generate_autoprompt'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'file_id': fileId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to generate auto-prompted JSONL: ${response.statusCode}, ${response.body}',
      );
    }
  }

  /// Generates custom template JSONL from the uploaded CSV
  Future<Map<String, dynamic>> generateTemplateJsonl(
    String fileId,
    String promptTemplate,
    String responseTemplate,
  ) async {
    var response = await http.post(
      Uri.parse('$baseUrl/api/finetune/generate_from_config'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'file_id': fileId,
        'prompt_template': promptTemplate,
        'response_template': responseTemplate,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to generate template JSONL: ${response.statusCode}, ${response.body}',
      );
    }
  }

  /// Downloads a generated JSONL file
  Future<http.Response> downloadJsonl(String fileId, String type) async {
    var response = await http.get(
      Uri.parse('$baseUrl/api/finetune/download/${fileId}_$type'),
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception(
        'Failed to download JSONL file: ${response.statusCode}, ${response.body}',
      );
    }
  }

  /// Suggests AI-generated templates based on the uploaded CSV
  Future<Map<String, dynamic>> suggestAITemplates(String fileId) async {
    var response = await http.post(
      Uri.parse('$baseUrl/api/finetune/suggest_templates'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'file_id': fileId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to suggest AI templates: ${response.statusCode}, ${response.body}',
      );
    }
  }
}
