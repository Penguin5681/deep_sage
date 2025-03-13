import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;

import '../../models/hive_models/user_api_model.dart';

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

  bool isThereApiDetailsForKaggle() {
    return kaggleUsername!.isNotEmpty && kaggleKey!.isNotEmpty;
  }

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
