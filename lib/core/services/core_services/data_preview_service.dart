import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DataPreviewService {
  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  Future<Map<String, dynamic>?> loadDatasetPreview(String filePath, String fileType, int nRows) async {
    try {
      debugPrint('Requesting preview for: $filePath (type: $fileType)');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/data/preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_path': filePath,
          'n_rows': nRows,
          'file_type': fileType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Preview error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (ex) {
      debugPrint('Preview exception: $ex');
      return null;
    }
  }
}