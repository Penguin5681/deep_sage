import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;

import '../../models/hive_models/user_api_model.dart';

/// Service class responsible for retrieving Kaggle dataset information
/// using stored API credentials.
class KaggleDatasetInfoService {
  /// Hive storage box for API credentials
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  /// Retrieves stored user API credentials from Hive storage
  ///
  /// Returns [UserApi] object if credentials exist, null otherwise
  UserApi? getUserApi() {
    if (hiveBox.isEmpty) return null;
    return hiveBox.getAt(0) as UserApi;
  }

  /// Base URL for API requests, retrieved from environment variables
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  /// Gets the stored Kaggle username
  String get kaggleUsername => getUserApi()?.kaggleUserName ?? '';

  /// Gets the stored Kaggle API key
  String get kaggleKey => getUserApi()?.kaggleApiKey ?? '';

  /// Retrieves metadata for a Kaggle dataset by its ID
  ///
  /// [datasetId] The ID of the Kaggle dataset to retrieve
  ///
  /// Returns a [KaggleDataset] object containing dataset metadata
  ///
  /// Throws:
  /// - [DatasetNotFoundException] if the dataset doesn't exist
  /// - [AuthenticationException] if Kaggle credentials are invalid
  /// - [ApiException] for other API or connection errors
  Future<KaggleDataset> retrieveKaggleDatasetMetadata(String datasetId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/retrieve-kaggle-dataset?dataset_id=$datasetId'),
        headers: {
          'X-Kaggle-Username': kaggleUsername,
          'X-Kaggle-Key': kaggleKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return KaggleDataset.fromJson(data);
      } else if (response.statusCode == 404) {
        throw DatasetNotFoundException('Dataset not found: $datasetId');
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Invalid Kaggle credentials');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw ApiException('Failed to fetch dataset info: $error');
      }
    } catch (e) {
      if (e is DatasetNotFoundException ||
          e is AuthenticationException ||
          e is ApiException) {
        rethrow;
      }
      throw ApiException('Error connecting to server: ${e.toString()}');
    }
  }
}

/// Model class representing Kaggle dataset metadata
class KaggleDataset {
  /// Unique identifier for the dataset
  final String id;

  /// Title of the dataset
  final String title;

  /// Owner/creator of the dataset
  final String owner;

  /// URL to access the dataset on Kaggle
  final String url;

  /// Size of the dataset (formatted string)
  final String size;

  /// Date when the dataset was last updated
  final String lastUpdated;

  /// Number of times the dataset has been downloaded
  final int downloadCount;

  /// Number of votes/upvotes for the dataset
  final int voteCount;

  /// Description of the dataset
  final String description;

  /// Creates a new KaggleDataset instance
  KaggleDataset({
    required this.id,
    required this.title,
    required this.owner,
    required this.url,
    required this.size,
    required this.lastUpdated,
    required this.downloadCount,
    required this.voteCount,
    required this.description,
  });

  /// Creates a KaggleDataset instance from JSON data
  ///
  /// [json] The JSON map containing dataset metadata
  factory KaggleDataset.fromJson(Map<String, dynamic> json) {
    return KaggleDataset(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      owner: json['owner'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] ?? '',
      lastUpdated: json['lastUpdated'] ?? '',
      downloadCount: json['downloadCount'] ?? 0,
      voteCount: json['voteCount'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}

/// Exception thrown when a requested dataset cannot be found
class DatasetNotFoundException implements Exception {
  /// Error message
  final String message;

  /// Creates a new dataset not found exception
  DatasetNotFoundException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when Kaggle API authentication fails
class AuthenticationException implements Exception {
  /// Error message
  final String message;

  /// Creates a new authentication exception
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown for general API errors
class ApiException implements Exception {
  /// Error message
  final String message;

  /// Creates a new API exception
  ApiException(this.message);

  @override
  String toString() => message;
}
