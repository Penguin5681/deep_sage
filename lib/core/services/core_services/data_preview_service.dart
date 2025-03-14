/// Data Preview Service
///
/// This service handles requests to preview data from various file types.
/// It communicates with a backend API to retrieve previews of datasets.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service responsible for fetching data previews from the backend.
class DataPreviewService {
  /// Base URL for API requests, retrieved from environment variables.
  /// Defaults to 'http://localhost:5000' if not specified.
  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  /// Loads a preview of a dataset from the specified file path.
  ///
  /// Makes an API request to retrieve a preview of the dataset.
  ///
  /// Parameters:
  /// - [filePath]: The path to the file to be previewed
  /// - [fileType]: The type of the file (e.g., 'csv', 'json')
  /// - [nRows]: Number of rows to retrieve in the preview
  ///
  /// Returns:
  /// - A [Future] that completes with a [Map] containing the preview data
  ///   or `null` if an error occurs
  Future<Map<String, dynamic>?> loadDatasetPreview(
    String filePath,
    String fileType,
    int nRows,
  ) async {
    try {
      debugPrint('Requesting preview for: $filePath (type: $fileType)');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/data/preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_path': filePath,
          'n_rows': nRows,
          'file_type': fileType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Preview error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (ex) {
      debugPrint('Preview exception: $ex');
      return null;
    }
  }
}
