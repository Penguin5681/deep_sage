import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DownloadDatasetService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  Future<void> downloadDataset({
    required String source,
    required String datasetId,
    String? path,
    String? config,
  }) async {
    final uri = Uri.parse('$baseUrl/api/datasets/download');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (source == 'huggingface' && dotenv.env['HF_TOKEN'] != null) {
      headers['X-HF-Token'] = dotenv.env['HF_TOKEN']!;
    }

    final body = json.encode({
      'source': source,
      'dataset_id': datasetId,
      'path': path ?? './datasets',
      'config': config,
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        debugPrint('Dataset downloaded successfully to $path');
      } else {
        debugPrint('Failed to download dataset: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error downloading dataset: $e');
    }
  }
}
