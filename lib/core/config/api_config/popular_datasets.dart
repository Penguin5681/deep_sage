import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PopularDatasets {
  final String id;
  final String title;
  final String addedTime;
  final String fileType;
  final String fileSize;

  PopularDatasets({
    required this.id,
    required this.title,
    required this.addedTime,
    required this.fileType,
    required this.fileSize,
  });

  factory PopularDatasets.fromJson(Map<String, dynamic> json) {
    return PopularDatasets(
      id: json['ref'] ?? json['id'] ?? '',
      title: json['title'] ?? json['ref'] ?? json['id'] ?? 'Unnamed Dataset',
      addedTime: _formatDate(
        json['lastModified'] ?? json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
      fileType: json['fileType'] ?? _determineFileType(json),
      fileSize: _formatFileSize(json['size'] ?? 0),
    );
  }

  static String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "Added on ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }

  static String _determineFileType(Map<String, dynamic> json) {
    if (json.containsKey('fileTypes')) {
      List<dynamic> fileTypes = json['fileTypes'];
      if (fileTypes.isNotEmpty) {
        return fileTypes.first.toString().toUpperCase();
      }
    }
    return 'CSV';
  }

  static String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class PopularDatasetService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;
  final String? kaggleUsername = dotenv.env['KAGGLE_USERNAME'];
  final String? kaggleKey = dotenv.env['KAGGLE_KEY'];

  Future<List<PopularDatasets>> fetchPopularDatasets() async {
    final uri = Uri.parse('$baseUrl/api/datasets/kaggle?limit=10&sort_by=votes');

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
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PopularDatasets.fromJson(json)).toList();
      } else {
        debugPrint('Failed to load datasets: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load datasets');
      }
    } catch (e) {
      debugPrint('Error fetching datasets: $e');
      throw Exception('Error fetching datasets: $e');
    }
  }
}
