import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service class responsible for downloading datasets from various sources.
///
/// This service handles dataset downloads, particularly from sources like HuggingFace,
/// using environment variables for configuration and authentication.
class DownloadDatasetService {
  /// Base URL for the API endpoints, retrieved from environment variables.
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  /// Downloads a dataset from the specified source.
  ///
  /// Parameters:
  /// - [source]: The source platform of the dataset (e.g., 'huggingface')
  /// - [datasetId]: Unique identifier for the dataset
  /// - [path]: Optional custom path where the dataset will be saved (defaults to './datasets')
  /// - [config]: Optional configuration parameters for the download
  ///
  /// Throws:
  /// - May throw network-related exceptions during the download process
  ///
  /// Example:
  /// ```dart
  /// final downloader = DownloadDatasetService();
  /// await downloader.downloadDataset(
  ///   source: 'huggingface',
  ///   datasetId: 'bert-base-uncased',
  ///   path: './my_datasets'
  /// );
  /// ```
  Future<void> downloadDataset({
    required String source,
    required String datasetId,
    String? path,
    String? config,
  }) async {
    final uri = Uri.parse('$baseUrl/api/datasets/download');
    final headers = <String, String>{'Content-Type': 'application/json'};

    // Add HuggingFace token to headers if source is huggingface and token exists
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
