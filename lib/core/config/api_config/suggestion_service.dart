import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;

import '../../models/hive_models/user_api_model.dart';

/// Represents a dataset suggestion with a name and source.
///
/// This class is used to store dataset suggestions retrieved from
/// various sources like Kaggle.
class DatasetSuggestion {
  /// The name of the dataset.
  final String name;

  /// The source of the dataset (e.g., 'kaggle').
  final String source;

  /// Creates a new [DatasetSuggestion] with the required name and source.
  ///
  /// [name]: The name of the dataset.
  /// [source]: The source platform of the dataset.
  DatasetSuggestion({required this.name, required this.source});

  @override
  String toString() => name;
}

/// Service class for retrieving dataset suggestions from external APIs.
///
/// This class handles API communication with services like Kaggle to
/// fetch dataset suggestions based on user queries.
class SuggestionService {
  /// The Hive box used to store API credentials.
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  /// The base URL for API requests.
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  /// Retrieves the user's API credentials from Hive storage.
  ///
  /// Returns a [UserApi] object if credentials exist, null otherwise.
  UserApi? getUserApi() {
    if (hiveBox.isEmpty) return null;
    return hiveBox.getAt(0) as UserApi;
  }

  /// Gets the stored Kaggle username.
  ///
  /// Returns null if no credentials are stored.
  String? get kaggleUsername => getUserApi()?.kaggleUserName;

  /// Gets the stored Kaggle API key.
  ///
  /// Returns null if no credentials are stored.
  String? get kaggleKey => getUserApi()?.kaggleApiKey;

  /// Checks if valid Kaggle API credentials are available.
  ///
  /// Returns true if both username and API key are non-empty.
  /// Note: This method may throw if credentials are null.
  bool isThereApiDetailsForKaggle() {
    return kaggleUsername!.isNotEmpty && kaggleKey!.isNotEmpty;
  }

  /// Fetches dataset suggestions based on a search query.
  ///
  /// [query]: The search term to find matching datasets.
  /// [source]: The source platform to search (defaults to 'kaggle').
  /// [limit]: Maximum number of suggestions to return.
  ///
  /// Returns a list of [DatasetSuggestion] objects matching the query,
  /// or an empty list if no matches are found or an error occurs.
  Future<List<DatasetSuggestion>> getSuggestions({
    required String query,
    String source = 'kaggle',
    int limit = 10,
  }) async {
    if (query.length < 2) {
      return [];
    }

    final uri = Uri.parse('$baseUrl/api/suggestions').replace(
      queryParameters: {
        'query': query,
        'source': 'kaggle',
        'limit': limit.toString(),
      },
    );

    final headers = <String, String>{};

    if (kaggleUsername != null && kaggleKey != null) {
      headers['X-Kaggle-Username'] = kaggleUsername!;
      headers['X-Kaggle-Key'] = kaggleKey!;
    } else {
      debugPrint('No Kaggle credentials available');
      return [];
    }

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<DatasetSuggestion> suggestions = [];

        if (data.containsKey('kaggle')) {
          final List<dynamic> kaggleSuggestions = data['kaggle'];
          suggestions.addAll(
            kaggleSuggestions.map(
              (name) =>
                  DatasetSuggestion(name: name.toString(), source: 'kaggle'),
            ),
          );
        }

        debugPrint('Kaggle suggestions: ${suggestions.length}');
        return suggestions;
      } else {
        debugPrint('Error occurred: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Internal Server error: $e');
      return [];
    }
  }
}
