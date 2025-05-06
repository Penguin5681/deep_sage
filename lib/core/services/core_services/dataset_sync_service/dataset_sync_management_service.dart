import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatasetSyncManagementService {
  final String _baseUrl = dotenv.env['DEV_BASE_URL']!;

  /// Retrieves all recorded datasets for a specific user
  ///
  /// Parameters:
  ///   - `userId`: ID of the user whose datasets to retrieve
  ///
  /// Returns:
  ///   A [Future] that completes with a [Map<String, dynamic>] containing
  ///   the user ID, count of datasets, and a list of dataset metadata
  ///
  /// Throws:
  ///   - [Exception] if the request fails
  Future<Map<String, dynamic>> getRecordedDatasets({required String userId}) async {
    final uri = Uri.parse(
      '$_baseUrl/api/aws/s3/get-recorded-datasets',
    ).replace(queryParameters: {'user_id': userId});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Unknown error';
        throw Exception('Failed to retrieve datasets: $errorMessage');
      } catch (e) {
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    }
  }
}
