import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

class HuggingFaceDataset {
  final String id;
  final String author;
  final String description;
  final String lastModified;
  final int downloads;
  final int likes;
  final List<String> configs;

  HuggingFaceDataset({
    required this.id,
    required this.author,
    required this.description,
    required this.lastModified,
    required this.downloads,
    required this.likes,
    required this.configs,
  });

  factory HuggingFaceDataset.fromJson(Map<String, dynamic> json) {
    String rawDescription = json['description'] ?? '';
    String cleanDescription = HfDatasetInfoService._cleanDescription(rawDescription);
    return HuggingFaceDataset(
      id: json['id'] ?? '',
      author: json['author'] ?? '',
      description: cleanDescription,
      lastModified: json['lastModified'] ?? '',
      downloads: json['downloads'] ?? 0,
      likes: json['likes'] ?? 0,
      configs: List<String>.from(json['configs'] ?? []),
    );
  }
}

class HfDatasetInfoService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  // Contributed by Claude 3.7

  static String _cleanDescription(String rawDescription) {
    final fullDescPattern = RegExp(r'See the full description on the dataset page: https://huggingface\.co/datasets/[^\.]+\.');
    rawDescription = rawDescription.replaceAll(fullDescPattern, '');

    try {
      var document = html_parser.parse(rawDescription);
      String text = document.body?.text ?? rawDescription;

      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      text = text.replaceAll('[Dataset Name]', '');
      text = text.replaceAll('Dataset Summary', '');
      text = text.replaceAll('Supported Tasks and Leaderboards', '');

      return text;
    } catch (e) {
      return rawDescription
          .replaceAll(RegExp(r'\n\s*\n'), '\n')
          .replaceAll(RegExp(r'\t'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }

  Future<HuggingFaceDataset> getDatasetInfo(String datasetId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/retrieve-dataset?dataset_id=$datasetId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HuggingFaceDataset.fromJson(data);
      } else if (response.statusCode == 404) {
        throw DatasetNotFoundException('Dataset not found: $datasetId');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw ApiException('Failed to fetch dataset info: $error');
      }
    } catch (e) {
      if (e is DatasetNotFoundException || e is ApiException) {
        rethrow;
      }
      throw ApiException('Error connecting to server: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> retrieveHfDatasetMetadata(String datasetId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/retrieve-dataset?dataset_id=$datasetId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          debugPrint('HTTP Error: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');
        }

        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw ApiException('Failed to fetch dataset info: $error');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Exception occurred: $e');
      }
      throw ApiException('Error connecting to server: ${e.toString()}');
    }
  }
}

class DatasetNotFoundException implements Exception {
  final String message;
  DatasetNotFoundException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}