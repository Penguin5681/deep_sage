import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for previewing the effects of data cleaning operations before applying them.
///
/// This service interacts with the backend API to show users how their cleaning
/// operations will affect their data before they commit to making changes.
/// It provides both the original data and the preview of cleaned data for comparison.
class DataCleaningPreviewService {
  final String _baseUrl;
  final http.Client _httpClient;

  /// Creates a new instance of the [DataCleaningPreviewService].
  ///
  /// [baseUrl] is the base URL of the API server.
  /// [httpClient] is an optional HTTP client for making requests.
  DataCleaningPreviewService({required String baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient ?? http.Client();

  /// Previews the effect of cleaning missing values in a dataset.
  ///
  /// [filePath] is the path to the dataset file.
  /// [method] is the method to use for cleaning missing values (e.g., 'mean', 'median', 'custom').
  /// [customValues] is a map of custom values to use for filling missing values when using 'custom' method.
  /// [selectedColumns] is an optional list of columns to apply the cleaning to.
  /// [limit] is the maximum number of rows to return in the preview.
  ///
  /// Returns a map containing 'before' and 'after' states of the data,
  /// as well as metadata about the preview.
  Future<Map<String, dynamic>> previewMissingValueCleaning({
    required String filePath,
    required String method,
    Map<String, dynamic>? customValues,
    List<String>? selectedColumns,
    int limit = 10,
  }) async {
    try {
      // Create proper cleaning operations format
      List<Map<String, dynamic>> operations = [];

      // If specific columns are selected, create one operation per column
      if (selectedColumns != null && selectedColumns.isNotEmpty) {
        for (String column in selectedColumns) {
          final Map<String, dynamic> operation = {
            'column': column,
            'method': method,
          };

          // Add custom values if provided
          if (method == 'custom' && customValues != null) {
            operation['custom_values'] = customValues;
          }

          operations.add(operation);
        }
      } else {
        // If no columns specified, it might be using a different API pattern
        // This is a fallback but likely won't work as expected
        operations.add({
          'type': 'missing_values',
          'method': method,
          'custom_values': customValues,
        });
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/data-cleaning/preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_path': filePath,
          'cleaning_operations': operations,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to get preview: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error previewing missing value cleaning: $e');
      rethrow;
    }
  }

  /// Previews the effect of multiple cleaning operations on a dataset.
  ///
  /// [filePath] is the path to the dataset file.
  /// [operations] is a list of cleaning operations to apply.
  /// Each operation is a map with at least a 'type' key and other operation-specific properties.
  /// [limit] is the maximum number of rows to return in the preview.
  ///
  /// Returns a map containing 'before' and 'after' states of the data,
  /// as well as metadata about the preview.
  Future<Map<String, dynamic>> previewMultipleCleaningOperations({
    required String filePath,
    required List<Map<String, dynamic>> operations,
    int limit = 10,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/data-cleaning/preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_path': filePath,
          'cleaning_operations': operations,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to get preview: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error previewing cleaning operations: $e');
      rethrow;
    }
  }

  /// Closes the HTTP client when the service is no longer needed.
  void dispose() {
    _httpClient.close();
  }
}
