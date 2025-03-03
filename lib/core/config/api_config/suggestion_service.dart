import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;

import '../../models/user_api_model.dart';

class DatasetSuggestion {
  final String name;
  final String source;

  DatasetSuggestion({required this.name, required this.source});

  @override
  String toString() => name;
}

class SuggestionService {
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  UserApi? getUserApi() {
    if (hiveBox.isEmpty) return null;
    return hiveBox.getAt(0) as UserApi;
  }

  String? get kaggleUsername => getUserApi()?.kaggleUserName;

  String? get kaggleKey => getUserApi()?.kaggleApiKey;

  String? get hfToken => getUserApi()?.hfToken;

  bool isThereApiDetailsForKaggle() {
    return kaggleUsername!.isNotEmpty && kaggleKey!.isNotEmpty;
  }

  Future<List<DatasetSuggestion>> getSuggestions({
    required String query,
    String source = 'all',
    int limit = 5,
  }) async {
    if (query.length < 2) {
      return [];
    }

    final uri = Uri.parse('$baseUrl/api/suggestions').replace(
      queryParameters: {
        'query': query,
        'source': source,
        'limit': limit.toString(),
      },
    );

    final headers = <String, String>{};

    if (source == 'all' || source == 'kaggle') {
      if (kaggleUsername != null && kaggleKey != null) {
        headers['X-Kaggle-Username'] = kaggleUsername!;
        headers['X-Kaggle-Key'] = kaggleKey!;
      }
    }

    // I am not sure if this piece of code would barely be used.
    // Let's put it anyways
    if (source == 'all' || source == 'huggingface') {
      if (hfToken != null) {
        headers['X-HF-Token'] = hfToken!;
      }
    }

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<DatasetSuggestion> suggestions = [];

        if (data.containsKey('huggingface')) {
          final List<dynamic> hfSuggestions = data['huggingface'];
          suggestions.addAll(
            hfSuggestions.map(
              (name) => DatasetSuggestion(
                name: name.toString(),
                source: 'huggingface',
              ),
            ),
          );
        }

        if (data.containsKey('kaggle')) {
          final List<dynamic> kaggleSuggestions = data['kaggle'];
          suggestions.addAll(
            kaggleSuggestions.map(
              (name) =>
                  DatasetSuggestion(name: name.toString(), source: 'kaggle'),
            ),
          );
        }
        debugPrint(suggestions.toString());
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
