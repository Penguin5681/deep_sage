import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/hive_models/user_api_model.dart';

class PopularDataset {
  /// Unique identifier for the dataset
  final String id;

  /// Title of the dataset
  final String title;

  /// Owner or creator of the dataset
  final String owner;

  /// URL to access the dataset
  final String url;

  /// Description of the dataset's contents
  final String description;

  /// When the dataset was last updated in raw format
  final String lastUpdated;

  /// Size of the dataset in string format (e.g. "1.2 MB")
  final String size;

  /// Number of times the dataset has been downloaded
  final int downloadCount;

  /// Number of votes or likes the dataset has received
  final int voteCount;

  /// Returns a formatted date string based on [lastUpdated]
  String get addedTime => _formatDate(lastUpdated);

  /// Returns the file type of the dataset (always "CSV" for now)
  String get fileType => 'CSV';

  /// Returns the file size as stored in the [size] field
  String get fileSize => size;

  /// Creates a [PopularDataset] instance with required fields
  PopularDataset({
    required this.id,
    required this.title,
    required this.owner,
    required this.url,
    required this.description,
    required this.lastUpdated,
    required this.size,
    required this.downloadCount,
    required this.voteCount,
  });

  /// Creates a [PopularDataset] from a JSON map
  ///
  /// Handles missing values with sensible defaults and ensures
  /// numeric fields are properly parsed from different formats.
  factory PopularDataset.fromJson(Map<String, dynamic> json) {
    /// Helper function to safely parse integers from various input types
    ///
    /// Returns 0 if parsing fails or value is null
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (_) {
          return 0;
        }
      }
      return 0;
    }

    return PopularDataset(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unnamed Dataset',
      owner: json['owner']?.toString() ?? 'Unknown',
      url: json['url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lastUpdated: json['lastUpdated']?.toString() ?? '',
      size: json['size']?.toString() ?? '0 B',
      downloadCount: safeParseInt(json['downloadCount']),
      voteCount: safeParseInt(json['voteCount']),
    );
  }

  /// Formats a date string into a user-friendly format.
  ///
  /// This method takes a date string [dateStr] in various possible formats and
  /// converts it to a standardized "Added on DD/MM/YYYY" format.
  ///
  /// Parameters:
  ///   - [dateStr]: The date string to format, which can be in various formats including:
  ///     - ISO 8601 format (for standard DateTime.parse)
  ///     - GMT format (e.g. "Wed, 21 Oct 2023 13:45:30 GMT")
  ///     - Other string formats that can be parsed by splitting
  ///
  /// Returns:
  ///   - A formatted string in the form "Added on DD/MM/YYYY"
  ///   - "Date unknown" if the input string is empty
  ///
  /// If the date parsing fails, it attempts to extract date components by splitting
  /// the string and using the components directly.
  static String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "Date unknown";

    try {
      if (dateStr.contains("GMT")) {
        final pattern = "EEE, dd MMM yyyy HH:mm:ss 'GMT'";
        final date = DateFormat(pattern).parse(dateStr);
        return "Added on ${date.day}/${date.month}/${date.year}";
      } else {
        final date = DateTime.parse(dateStr);
        return "Added on ${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return "Added on ${dateStr.split(' ')[1]} ${dateStr.split(' ')[2]} ${dateStr.split(' ')[3]}";
    }
  }
}

/// Service class for fetching popular datasets from various categories
///
/// This class handles API communication with Kaggle to retrieve popular datasets
/// across different domains including general, healthcare, finance, and technology.
/// It uses credentials stored in the app's Hive database to authenticate API requests.
class PopularDatasetService {
  /// Base URL for API requests, fetched from environment variables
  final String baseUrl = dotenv.env['DEV_BASE_URL'] ?? '';

  /// Retrieves the user's API credentials from Hive storage
  ///
  /// Returns a [UserApi] object containing the user's credentials or null if
  /// credentials are not found or an error occurs.
  UserApi? _getUserApi() {
    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME'] ?? '');
      if (hiveBox.isEmpty) return null;
      return hiveBox.getAt(0) as UserApi;
    } catch (e) {
      return null;
    }
  }

  /// The user's Kaggle username from stored credentials
  String get kaggleUsername => _getUserApi()?.kaggleUserName ?? '';

  /// The user's Kaggle API key from stored credentials
  String get kaggleKey => _getUserApi()?.kaggleApiKey ?? '';

  /// Fetches a list of popular datasets from Kaggle
  ///
  /// Makes an API request to retrieve popular datasets with configurable parameters.
  ///
  /// Parameters:
  ///   - [limit]: Maximum number of datasets to return (default: 10)
  ///   - [sortBy]: Criterion to sort results by (default: 'votes')
  ///
  /// Returns:
  ///   A list of [PopularDataset] objects representing the fetched datasets
  ///
  /// Throws:
  ///   - [Exception] if base URL is not configured
  ///   - [Exception] if Kaggle credentials are missing
  ///   - [Exception] with API error details if the request fails
  Future<List<PopularDataset>> fetchPopularDatasets({
    int limit = 50,
    String sortBy = 'votes',
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('Base URL is not configured');
    }

    if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
      throw Exception('Kaggle credentials not configured');
    }

    final uri = Uri.parse(
      '$baseUrl/api/datasets/kaggle',
    ).replace(queryParameters: {'limit': limit.toString(), 'sort_by': sortBy});

    final headers = {
      'X-Kaggle-Username': kaggleUsername,
      'X-Kaggle-Key': kaggleKey,
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty &&
            data.first is Map &&
            (data.first as Map).containsKey('error')) {
          throw Exception('API error: ${data.first['error']}');
        }
        return data.map((json) => PopularDataset.fromJson(json)).toList();
      } else {
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            throw Exception(
              'API error (${response.statusCode}): ${errorBody['error']}',
            );
          }
        } catch (_) {}

        throw Exception(
          'Failed to load datasets (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a list of popular healthcare datasets from Kaggle
  ///
  /// Makes an API request to retrieve healthcare-specific datasets with configurable parameters.
  ///
  /// Parameters:
  ///   - [limit]: Maximum number of datasets to return (default: 10)
  ///   - [sortBy]: Criterion to sort results by (default: 'hottest')
  ///
  /// Returns:
  ///   A list of [PopularDataset] objects representing the fetched datasets
  ///
  /// Throws:
  ///   - [Exception] if base URL is not configured
  ///   - [Exception] if Kaggle credentials are missing
  ///   - [Exception] with API error details if the request fails
  Future<List<PopularDataset>> fetchPopularHealthcareDatasets({
    int limit = 50,
    String sortBy = 'hottest',
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('Base URL is not configured');
    }

    if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
      throw Exception('Kaggle credentials not configured');
    }

    final uri = Uri.parse(
      '$baseUrl/api/datasets/healthcare',
    ).replace(queryParameters: {'limit': limit.toString(), 'sort_by': sortBy});

    final headers = {
      'X-Kaggle-Username': kaggleUsername,
      'X-Kaggle-Key': kaggleKey,
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty &&
            data.first is Map &&
            (data.first as Map).containsKey('error')) {
          throw Exception('API error: ${data.first['error']}');
        }

        return data.map((json) => PopularDataset.fromJson(json)).toList();
      } else {
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            throw Exception(
              'API error (${response.statusCode}): ${errorBody['error']}',
            );
          }
        } catch (_) {}

        throw Exception(
          'Failed to load datasets (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a list of popular finance datasets from Kaggle
  ///
  /// Makes an API request to retrieve finance-specific datasets with configurable parameters.
  ///
  /// Parameters:
  ///   - [limit]: Maximum number of datasets to return (default: 50)
  ///   - [sortBy]: Criterion to sort results by (default: 'hottest')
  ///
  /// Returns:
  ///   A list of [PopularDataset] objects representing the fetched datasets
  ///
  /// Throws:
  ///   - [Exception] if base URL is not configured
  ///   - [Exception] if Kaggle credentials are missing
  ///   - [Exception] with API error details if the request fails
  Future<List<PopularDataset>> fetchPopularFinanceDatasets({
    int limit = 50,
    String sortBy = 'hottest',
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('Base URL is not configured');
    }

    if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
      throw Exception('Kaggle credentials not configured');
    }

    final uri = Uri.parse(
      '$baseUrl/api/datasets/finance',
    ).replace(queryParameters: {'limit': limit.toString(), 'sort_by': sortBy});

    final headers = {
      'X-Kaggle-Username': kaggleUsername,
      'X-Kaggle-Key': kaggleKey,
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty &&
            data.first is Map &&
            (data.first as Map).containsKey('error')) {
          throw Exception('API error: ${data.first['error']}');
        }

        return data.map((json) => PopularDataset.fromJson(json)).toList();
      } else {
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            throw Exception(
              'API error (${response.statusCode}): ${errorBody['error']}',
            );
          }
        } catch (_) {}

        throw Exception(
          'Failed to load datasets (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a list of popular technology datasets from Kaggle
  ///
  /// Makes an API request to retrieve technology-specific datasets with configurable parameters.
  ///
  /// Parameters:
  ///   - [limit]: Maximum number of datasets to return (default: 50)
  ///   - [sortBy]: Criterion to sort results by (default: 'hottest')
  ///
  /// Returns:
  ///   A list of [PopularDataset] objects representing the fetched datasets
  ///
  /// Throws:
  ///   - [Exception] if base URL is not configured
  ///   - [Exception] if Kaggle credentials are missing
  ///   - [Exception] with API error details if the request fails
  Future<List<PopularDataset>> fetchPopularTechnologyDatasets({
    int limit = 50,
    String sortBy = 'hottest',
  }) async {
    if (baseUrl.isEmpty) {
      throw Exception('Base URL is not configured');
    }

    if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
      throw Exception('Kaggle credentials not configured');
    }

    final uri = Uri.parse(
      '$baseUrl/api/datasets/technology',
    ).replace(queryParameters: {'limit': limit.toString(), 'sort_by': sortBy});

    final headers = {
      'X-Kaggle-Username': kaggleUsername,
      'X-Kaggle-Key': kaggleKey,
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }

        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty &&
            data.first is Map &&
            (data.first as Map).containsKey('error')) {
          throw Exception('API error: ${data.first['error']}');
        }

        return data.map((json) => PopularDataset.fromJson(json)).toList();
      } else {
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            throw Exception(
              'API error (${response.statusCode}): ${errorBody['error']}',
            );
          }
        } catch (_) {}

        throw Exception(
          'Failed to load datasets (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
