import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for handling missing value detection and cleaning operations
///
/// This service communicates with a backend API to:
/// - Fetch statistics about missing values in datasets
/// - Apply various cleaning methods to handle missing data
class MissingValuesService {
  /// Base URL for API endpoints, retrieved from environment variables
  /// Defaults to localhost if environment variable is not set
  final String baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  /// Retrieves missing value statistics for a CSV file
  ///
  /// Makes a GET request to the server to analyze the missing values in the dataset
  ///
  /// Parameters:
  ///   [filePath] - Path to the CSV file on the server to analyze
  ///
  /// Returns:
  ///   A Map containing statistics about missing values in each column
  ///
  /// Throws:
  ///   [Exception] if the API request fails
  Future<Map<String, dynamic>> getMissingValueStats(String filePath) async {
    final Uri uri = Uri.parse(
      '$baseUrl/api/data-cleaning/metadata',
    ).replace(queryParameters: {'file_path': filePath});

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load missing value stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching missing value stats: $e');
      throw Exception('Error fetching missing value stats: $e');
    }
  }

  /// Apply missing value cleaning operations to a CSV file
  ///
  /// Sends a POST request to the server to clean missing values in the dataset
  /// using the specified method and parameters.
  ///
  /// Parameters:
  ///   [filePath] - Path to the CSV file on the server
  ///   [method] - Cleaning method to apply (e.g., 'mean', 'median', 'custom')
  ///   [customValues] - Optional map of custom values to use for replacement
  ///                    when method is 'custom', with keys for different data types
  ///   [selectedColumns] - Optional list of specific columns to apply cleaning to
  ///                       If null or empty, cleaning is applied to all columns
  ///                       with missing values
  ///
  /// Returns:
  ///   String path to the cleaned CSV file on the server
  ///
  /// Throws:
  ///   [Exception] if the API request fails
  Future<String> cleanMissingValues({
    required String filePath,
    required String method,
    Map<String, dynamic>? customValues,
    List<String>? selectedColumns,
  }) async {
    // Create cleaning operations list based on selected columns
    final List<Map<String, dynamic>> cleaningOperations = [];

    // If no specific columns are selected, apply to all columns with missing values
    if (selectedColumns == null || selectedColumns.isEmpty) {
      final metadata = await getMissingValueStats(filePath);
      final columns = List<Map<String, dynamic>>.from(metadata['columns']);

      for (var column in columns) {
        if (column['missing_values'] > 0) {
          final Map<String, dynamic> operation = {
            'column': column['name'],
            'method': method,
          };

          // Add custom values with proper formatting if needed
          if (method == 'custom' && customValues != null) {
            operation['custom_values'] = {
              'numeric': customValues['numeric'],
              'categorical': customValues['categorical'],
              'date': customValues['datetime'],
            };
          }

          cleaningOperations.add(operation);
        }
      }
    } else {
      // Apply only to selected columns
      for (var column in selectedColumns) {
        final Map<String, dynamic> operation = {
          'column': column,
          'method': method,
        };

        // Add custom values with proper formatting if needed
        if (method == 'custom' && customValues != null) {
          operation['custom_values'] = {
            'numeric': customValues['numeric'],
            'categorical': customValues['categorical'],
            'date': customValues['datetime'],
          };
        }

        cleaningOperations.add(operation);
      }
    }

    // If no operations were created, return the original file path
    if (cleaningOperations.isEmpty) {
      return filePath;
    }

    final Uri uri = Uri.parse('$baseUrl/api/data-cleaning/clean');

    final requestBody = {
      'file_path': filePath,
      'cleaning_operations': cleaningOperations,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['cleaned_path'];
      } else {
        throw Exception(
          'Failed to clean missing values: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error cleaning missing values: $e');
      throw Exception('Error cleaning missing values: $e');
    }
  }
}
