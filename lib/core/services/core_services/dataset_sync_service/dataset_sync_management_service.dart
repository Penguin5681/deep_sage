import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();

  factory DownloadService() => _instance;

  DownloadService._internal();

  final ValueNotifier<Map<String, String>> activeDownloads = ValueNotifier<Map<String, String>>({});

  void startDownload(String fileName, String status) {
    final downloads = Map<String, String>.from(activeDownloads.value);
    downloads[fileName] = status;
    activeDownloads.value = downloads;
  }

  void updateDownloadStatus(String fileName, String status) {
    final downloads = Map<String, String>.from(activeDownloads.value);
    downloads[fileName] = status;
    activeDownloads.value = downloads;
  }

  void completeDownload(String fileName) {
    final downloads = Map<String, String>.from(activeDownloads.value);
    downloads.remove(fileName);
    activeDownloads.value = downloads;
  }

  int get downloadCount => activeDownloads.value.length;

  bool get hasDownloads => activeDownloads.value.isNotEmpty;
}

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

  /// Downloads a recorded dataset from S3 to the local filesystem
  ///
  /// Parameters:
  ///   - `userId`: ID of the user whose dataset to download
  ///   - `datasetKey`: The S3 key of the dataset to download
  ///   - `destinationPath`: Local path where the file should be saved
  ///
  /// Returns:
  ///   A [Future] that completes with a [Map<String, dynamic>] containing
  ///   download details including success status and file path
  ///
  /// Throws:
  ///   - [Exception] if the download fails
  Future<Map<String, dynamic>> downloadRecordedDataset({
    required String userId,
    required String s3Path,
    required String destinationPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/aws/s3/download-recorded-dataset');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 's3_path': s3Path, 'destination_path': destinationPath}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Unknown error';
        throw Exception('Failed to download dataset: $errorMessage');
      } catch (e) {
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    }
  }
}
