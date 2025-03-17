import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A service class responsible for converting Excel files to CSV format
/// by communicating with a backend conversion service.
class ExcelConversionService {
  /// Base URL for the API server, retrieved from environment variables
  /// with a fallback to localhost.
  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  /// Converts an Excel file to CSV format by sending a request to the backend service.
  ///
  /// [filePath] The path to the Excel file that needs to be converted.
  /// [encoding] The character encoding to use for the CSV output (defaults to 'utf-8').
  ///
  /// Returns a [Map] containing:
  /// - 'success': Whether the conversion was successful
  /// - 'csvPaths': List of paths to the generated CSV files
  /// - 'executionTime': The time taken to perform the conversion
  /// - 'sheetsConverted': Number of Excel sheets that were converted
  /// - 'error': An error message if the conversion failed
  Future<Map<String, dynamic>> convertExcelToCsv({
    required String filePath,
    String encoding = 'utf-8',
  }) async {
    try {
      if (kDebugMode) {
        print('Here I guess');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/convert/excel-to-csv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_path': filePath.replaceAll('\\', '/'),
          'encoding': encoding,
        }),
      );

      debugPrint('${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (kDebugMode) {
          print('Conversion successful: ${result['success']}');
        }
        return {
          'success': result['success'] ?? false,
          'csvPaths': List<String>.from(result['csv_paths'] ?? []),
          'executionTime': result['execution_time'] ?? '',
          'sheetsConverted': result['sheets_converted'] ?? 0,
        };
      } else {
        if (kDebugMode) {
          print('Server error: ${response.statusCode}, ${response.body}');
        }
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'csvPaths': <String>[],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception during Excel conversion: $e');
      }
      return {'success': false, 'error': e.toString(), 'csvPaths': <String>[]};
    }
  }

  /// Checks if the backend conversion service is available and responsive.
  ///
  /// Sends a health check request to the API server with a 5-second timeout.
  ///
  /// Returns [bool]:
  /// - true if the service is available (status code 200)
  /// - false if the service is unavailable or the request times out
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
