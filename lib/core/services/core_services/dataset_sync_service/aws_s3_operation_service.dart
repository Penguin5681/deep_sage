import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for performing AWS S3 operations through the backend API.
///
/// This service provides methods to:
/// - List available S3 buckets
/// - Upload datasets to S3
/// - List datasets for a user
/// - Download datasets from S3
/// - Delete datasets from S3
///
/// All methods require AWS credentials which are retrieved from local storage
/// and automatically added to API requests as headers.
class AWSS3OperationService {
  /// Base URL for AWS S3 API endpoints.
  final String _baseUrl;

  /// Singleton instance of the service.
  static final AWSS3OperationService _instance = AWSS3OperationService._internal();

  /// Factory constructor that returns the singleton instance.
  factory AWSS3OperationService() => _instance;

  /// Private constructor that initializes the base URL from environment variables.
  AWSS3OperationService._internal() : _baseUrl = dotenv.env['DEV_BASE_URL'] ?? '';

  /// Lists all buckets accessible with the provided AWS credentials.
  ///
  /// Parameters:
  ///   - `accessKey`: AWS access key ID
  ///   - `secretKey`: AWS secret access key
  ///   - `region`: AWS region name (e.g., 'us-east-1')
  ///
  /// Returns:
  ///   A [Future] that completes with a [List<String>] containing bucket names
  ///
  /// Throws:
  ///   - [Exception] if the request fails or returns an error status code
  Future<List<String>> listBuckets({
    required String accessKey,
    required String secretKey,
    required String region,
  }) async {
    debugPrint('Inside listBuckets()');
    final response = await http.post(
      Uri.parse('$_baseUrl/api/aws/s3/list-buckets'),
      headers: {
        'X-AWS-Access-Key': accessKey,
        'X-AWS-Secret-Key': secretKey,
        'X-AWS-Region': region,
      },
    );

    debugPrint('${jsonDecode(response.body)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['buckets']);
    } else {
      final errorMessage = _parseErrorMessage(response);
      debugPrint(errorMessage);
      throw Exception('Failed to list buckets: $errorMessage');
    }
  }

  /// Uploads a dataset file to the user's S3 storage.
  ///
  /// Parameters:
  ///   - `file`: The local file to upload
  ///   - `userId`: User identifier for organizing files by user
  ///   - `accessKey`: AWS access key ID
  ///   - `secretKey`: AWS secret access key
  ///   - `region`: AWS region name
  ///   - `bucketName`: S3 bucket name
  ///
  /// Returns:
  ///   A [Future] that completes with a [Map<String, dynamic>] containing
  ///   metadata about the uploaded file
  ///
  /// Throws:
  ///   - [Exception] if the upload fails
  Future<Map<String, dynamic>> uploadDataset({
    required File file,
    required String userId,
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucketName,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/api/aws/s3/upload-dataset'));

    // Add AWS credentials as headers
    request.headers.addAll({
      'X-AWS-Access-Key': accessKey,
      'X-AWS-Secret-Key': secretKey,
      'X-AWS-Region': region,
      'X-AWS-Bucket-Name': bucketName,
    });

    // Add the file and user ID
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['user_id'] = userId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      final errorMessage = _parseErrorMessage(response);
      throw Exception('Failed to upload dataset: $errorMessage');
    }
  }

  Future<void> recordDataset({
    required String userId,
    required String datasetName,
    required String fileSize,
    String fileType = 'csv',
    required String bucketName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/aws/s3/record-dataset'),
      body: {
        'user_id': userId,
        'dataset_name': datasetName,
        "s3_path": constructS3Path(
          bucketName: bucketName,
          filePath: 'datasets/$userId/$datasetName',
        ),
        'file_size': fileSize,
        'file_type': fileType,
      },
    );

    if (response.statusCode != 200) {
      final errorMessage = _parseErrorMessage(response);
      throw Exception('Failed to record dataset: $errorMessage');
    }
  }

  String constructS3Path({required String bucketName, required String filePath}) {
    return 's3://$bucketName/$filePath';
  }

  /// Lists all datasets uploaded by a specific user.
  ///
  /// Parameters:
  ///   - `userId`: User identifier to filter datasets
  ///   - `accessKey`: AWS access key ID
  ///   - `secretKey`: AWS secret access key
  ///   - `region`: AWS region name
  ///   - `bucketName`: S3 bucket name
  ///
  /// Returns:
  ///   A [Future] that completes with a [List<Map<String, dynamic>>] containing
  ///   metadata for each dataset
  ///
  /// Throws:
  ///   - [Exception] if the request fails
  Future<List<Map<String, dynamic>>> listDatasets({
    required String userId,
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucketName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/aws/s3/list-datasets'),
      headers: {
        'X-AWS-Access-Key': accessKey,
        'X-AWS-Secret-Key': secretKey,
        'X-AWS-Region': region,
        'X-AWS-Bucket-Name': bucketName,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['datasets']);
    } else {
      final errorMessage = _parseErrorMessage(response);
      throw Exception('Failed to list datasets: $errorMessage');
    }
  }

  /// Downloads a dataset from S3 to a local path.
  ///
  /// Parameters:
  ///   - `s3Path`: Path to the file in S3
  ///   - `localPath`: Local path to save the downloaded file
  ///   - `accessKey`: AWS access key ID
  ///   - `secretKey`: AWS secret access key
  ///   - `region`: AWS region name
  ///   - `bucketName`: S3 bucket name
  ///
  /// Returns:
  ///   A [Future] that completes with a [Map<String, dynamic>] containing
  ///   download confirmation details
  ///
  /// Throws:
  ///   - [Exception] if the download fails
  Future<Map<String, dynamic>> downloadDataset({
    required String s3Path,
    required String localPath,
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucketName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/aws/s3/download-dataset'),
      headers: {
        'X-AWS-Access-Key': accessKey,
        'X-AWS-Secret-Key': secretKey,
        'X-AWS-Region': region,
        'X-AWS-Bucket-Name': bucketName,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'s3_path': s3Path, 'local_path': localPath}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = _parseErrorMessage(response);
      throw Exception('Failed to download dataset: $errorMessage');
    }
  }

  /// Deletes a dataset from S3.
  ///
  /// Parameters:
  ///   - `s3Path`: Path to the file in S3
  ///   - `accessKey`: AWS access key ID
  ///   - `secretKey`: AWS secret access key
  ///   - `region`: AWS region name
  ///   - `bucketName`: S3 bucket name
  ///
  /// Returns:
  ///   A [Future] that completes with a [Map<String, dynamic>] containing
  ///   deletion confirmation details
  ///
  /// Throws:
  ///   - [Exception] if the deletion fails
  Future<Map<String, dynamic>> deleteDataset({
    required String s3Path,
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucketName,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/aws/s3/delete-dataset'),
      headers: {
        'X-AWS-Access-Key': accessKey,
        'X-AWS-Secret-Key': secretKey,
        'X-AWS-Region': region,
        'X-AWS-Bucket-Name': bucketName,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'s3_path': s3Path}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = _parseErrorMessage(response);
      throw Exception('Failed to delete dataset: $errorMessage');
    }
  }

  /// Parses error messages from API responses.
  ///
  /// Parameters:
  ///   - `response`: HTTP response to parse errors from
  ///
  /// Returns:
  ///   A [String] containing the error message or a generic message if parsing fails
  String _parseErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return errorData['error'] ?? errorData['message'] ?? 'Unknown error';
    } catch (e) {
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
