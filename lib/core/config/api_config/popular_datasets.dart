import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/user_api_model.dart';

class PopularDataset {
  final String id;
  final String title;
  final String owner;
  final String url;
  final String description;
  final String lastUpdated;
  final String size;
  final int downloadCount;
  final int voteCount;
  // Experimenting
  final String category;

  String get addedTime => _formatDate(lastUpdated);
  String get fileType => 'CSV';
  String get fileSize => size;

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
    // Experimenting
    required this.category,
  });

  factory PopularDataset.fromJson(Map<String, dynamic> json) {
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
      // Experimenting
      category: json['category'],
    );
  }

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

class PopularDatasetService {
  final String baseUrl = dotenv.env['DEV_BASE_URL'] ?? '';

  UserApi? _getUserApi() {
    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME'] ?? '');
      if (hiveBox.isEmpty) return null;
      return hiveBox.getAt(0) as UserApi;
    } catch (e) {
      return null;
    }
  }

  String get kaggleUsername => _getUserApi()?.kaggleUserName ?? '';
  String get kaggleKey => _getUserApi()?.kaggleApiKey ?? '';

  Future<List<PopularDataset>> fetchPopularDatasets({
    int limit = 10,
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
}
