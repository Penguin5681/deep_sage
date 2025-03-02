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
      id: json['id'],
      title: json['id'], // Assuming 'id' is used as the title
      addedTime: _formatDate(json['lastModified']),
      fileType: 'CSV', // Default file type
      fileSize: 'Unknown', // Default file size
    );
  }

  static String _formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "Added on ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }
}

  class PopularDatasetService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  Future<List<PopularDatasets>> fetchPopularDatasets() async {
    final uri = Uri.parse('$baseUrl/api/datasets/huggingface?limit=3&sort_by=downloads');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PopularDatasets.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load datasets');
      }
    } catch (e) {
      debugPrint('Error fetching datasets: $e');
      throw Exception('Error fetching datasets');
    }
  }
}
