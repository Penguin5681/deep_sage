import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service responsible for data cleaning operations.
///
/// Provides methods to interact with a data cleaning API for retrieving column information,
/// metadata about datasets, applying cleaning operations, and creating cleaning operations
/// for handling missing values.
class DataCleaningService {
  /// The base URL for the data cleaning API.
  ///
  /// Uses the DEV_BASE_URL environment variable or defaults to localhost if not set.
  final String baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  /// Retrieves column information from a CSV file.
  ///
  /// Makes a GET request to the API to fetch column details from the specified file.
  ///
  /// Parameters:
  ///   [filePath] - Path to the CSV file to analyze.
  ///
  /// Returns:
  ///   A [Future] that completes with a list of column information maps.
  ///
  /// Throws:
  ///   [Exception] if the request fails or returns a non-200 status code.
  Future<List<Map<String, dynamic>>> getColumns(String filePath) async {
    final Uri uri = Uri.parse(
      '$baseUrl/api/data-cleaning/columns',
    ).replace(queryParameters: {'file_path': filePath});

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['columns']);
      } else {
        throw Exception('Failed to load columns: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching columns: $e');
    }
  }

  /// Gets file metadata including missing value statistics.
  ///
  /// Makes a GET request to retrieve metadata about the file, including information
  /// about missing values.
  ///
  /// Parameters:
  ///   [filePath] - Path to the file to analyze.
  ///   [customNaValues] - Optional custom NA values to consider during analysis.
  ///
  /// Returns:
  ///   A [Future] that completes with a map containing the file metadata.
  ///
  /// Throws:
  ///   [Exception] if the request fails or returns a non-200 status code.
  Future<Map<String, dynamic>> getMetadata(
    String filePath, {
    String? customNaValues,
  }) async {
    final queryParams = {'file_path': filePath};
    if (customNaValues != null) {
      queryParams['custom_na_values'] = customNaValues;
    }

    final Uri uri = Uri.parse(
      '$baseUrl/api/data-cleaning/metadata',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load metadata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching metadata: $e');
    }
  }

  /// Applies cleaning operations to handle missing values in a file.
  ///
  /// Makes a POST request to clean a file according to specified operations.
  ///
  /// Parameters:
  ///   [filePath] - Path to the file that needs cleaning.
  ///   [cleaningOperations] - List of operations to apply to the file.
  ///   [customNaValues] - Optional custom NA values to consider during cleaning.
  ///
  /// Returns:
  ///   A [Future] that completes with the path to the cleaned file.
  ///
  /// Throws:
  ///   [Exception] if the request fails or returns a non-200 status code.
  Future<String> cleanFile({
    required String filePath,
    required List<Map<String, dynamic>> cleaningOperations,
    List<String>? customNaValues,
  }) async {
    final requestBody = {
      'file_path': filePath,
      'cleaning_operations': cleaningOperations,
    };
    if (customNaValues != null) {
      requestBody['custom_na_values'] = customNaValues;
    }

    final Uri uri = Uri.parse('$baseUrl/api/data-cleaning/clean');

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
        throw Exception('Failed to clean file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error cleaning file: $e');
    }
  }

  /// Creates a cleaning operation definition for handling missing values.
  ///
  /// Used to generate operation specifications that can be passed to [cleanFile].
  ///
  /// Parameters:
  ///   [column] - Name of the column to apply the operation to.
  ///   [method] - Method to use for handling missing values (e.g., 'mean', 'median', 'custom').
  ///   [customValues] - Optional map of custom values to use when method is 'custom'.
  ///
  /// Returns:
  ///   A map representing the cleaning operation.
  Map<String, dynamic> createMissingValueOperation({
    required String column,
    required String method,
    Map<String, dynamic>? customValues,
  }) {
    final operation = {'column': column, 'method': method};

    if (method == 'custom' && customValues != null) {
      operation['custom_values'] = json.encode(customValues);
    }
    return operation;
  }
}
