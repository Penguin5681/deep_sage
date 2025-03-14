import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExcelConversionService {
  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  Future<Map<String, dynamic>> convertExcelToCsv({
    required String filePath,
    String encoding = 'utf-8',
  }) async {
    try {
      if (kDebugMode) {
        print('Here I guess');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/convert/excel-to-csv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_path': filePath.replaceAll('\\', '/'), 'encoding': encoding}),
      );

      debugPrint('${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (kDebugMode) {
          print('Conversion successful: ${result['success']}');
        }
        return {
          'success': result['success'] ?? false,
          'csvPaths': List<String>.from(result['csv_paths'] ?? []),
          'executionTime': result['execution_time'] ?? '',
          'sheetsConverted': result['sheets_converted'] ?? 0,
        };
      } else {
        if (kDebugMode) {
          print('Server error: ${response.statusCode}, ${response.body}');
        }
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'csvPaths': <String>[],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception during Excel conversion: $e');
      }
      return {'success': false, 'error': e.toString(), 'csvPaths': <String>[]};
    }
  }

  Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
