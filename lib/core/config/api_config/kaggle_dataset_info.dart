import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;

import '../../models/hive_models/user_api_model.dart';

class KaggleDatasetInfoService {
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
  UserApi? getUserApi() {
    if (hiveBox.isEmpty) return null;
    return hiveBox.getAt(0) as UserApi;
  }

  final String baseUrl = dotenv.env['DEV_BASE_URL']!;
  String get kaggleUsername => getUserApi()?.kaggleUserName ?? '';
  String get kaggleKey => getUserApi()?.kaggleApiKey ?? '';

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

class KaggleDataset {
  final String id;
  final String title;
  final String owner;
  final String url;
  final String size;
  final String lastUpdated;
  final int downloadCount;
  final int voteCount;
  final String description;

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

class DatasetNotFoundException implements Exception {
  final String message;
  DatasetNotFoundException(this.message);
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
