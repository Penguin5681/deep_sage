// lib/services/visualization_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';

class VisualizationService {
  final String baseUrl;

  VisualizationService({String? customBaseUrl})
    : baseUrl =
          customBaseUrl ??
          (dotenv.env['FLUTTER_ENV'] == 'development'
              ? dotenv.env['DEV_BASE_URL']!
              : dotenv.env['PROD_BASE_URL']!);

  Future<Map<String, List<String>>> getDatasetColumns(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final input = file.openRead();
      final fields =
          await input
              .transform(utf8.decoder)
              .transform(const CsvToListConverter())
              .toList();

      if (fields.isEmpty) {
        throw Exception('Empty CSV file');
      }

      // Get header row and cast to String
      final headers = List<String>.from(fields[0].map((e) => e.toString()));

      // Get a sample of values for each column to determine if it's numeric
      Map<String, List<String>> columnSamples = {};

      for (int colIndex = 0; colIndex < headers.length; colIndex++) {
        final String columnName = headers[colIndex];
        columnSamples[columnName] = [];

        // Get up to 5 sample values for each column
        for (
          int rowIndex = 1;
          rowIndex < fields.length && rowIndex < 6;
          rowIndex++
        ) {
          if (colIndex < fields[rowIndex].length) {
            columnSamples[columnName]!.add(
              fields[rowIndex][colIndex].toString(),
            );
          }
        }
      }

      return columnSamples;
    } catch (e) {
      debugPrint('Error reading CSV columns: $e');
      throw Exception('Failed to read dataset columns: $e');
    }
  }

  Future<String> generatePieChart(
    File csvFile,
    Map<String, dynamic> options,
  ) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/visualization/generate_pie_chart'),
      );

      // Add CSV file
      request.files.add(
        await http.MultipartFile.fromPath(
          'csv_file',
          csvFile.path,
          filename: path.basename(csvFile.path),
        ),
      );

      // Convert options to API format
      final apiConfig = {
        'category_column': options['categoryColumn'],
        'value_column': options['valueColumn'],
        'title': options['title'],
        'subtitle': options['subtitle'],
        'show_labels': options['showLabels'],
        'show_legend': options['legendPosition'] != 'none',
        'legend_position':
            options['legendPosition'] == 'none'
                ? 'best'
                : options['legendPosition'],
        'show_percent': options['showPercentages'],
        'show_values': options['showValues'],
        'explode': options['enableExplode'],
        'colors': options['colorPalette'],
        'start_angle': options['startAngle'],
        'shadow': options['enableShadow'],
        'donut': options['isDonutChart'],
        'donut_ratio':
            options['isDonutChart'] ? options['donutHoleSize'] : null,
        'sort': _mapSortingOption(options['sortingOption']),
        'top_n':
            options['enableFiltering'] && options['filterType'] == 'topN'
                ? options['topNValue']
                : null,
        'min_value':
            options['enableFiltering'] && options['filterType'] == 'valueRange'
                ? options['minValue']
                : null,
        'max_value':
            options['enableFiltering'] && options['filterType'] == 'valueRange'
                ? options['maxValue']
                : null,
        'format': options['outputFormat'].toLowerCase(),
        'dpi': options['outputDpi'].toInt(),
        'label_fontsize': options['labelFontSize'],
        'transparent': options['transparentBackground'],
        'label_position': options['labelPosition'],
      };

      // Add config JSON
      request.fields['config'] = jsonEncode(apiConfig);

      debugPrint(
        'Sending pie chart request with config: ${jsonEncode(apiConfig)}',
      );

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Received response with status code: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return '$baseUrl${jsonResponse['generated_pie_chart']}';
      } else {
        throw Exception(
          'Failed to generate pie chart: ${jsonResponse['error']}',
        );
      }
    } catch (e) {
      debugPrint('Error sending request: $e');
      throw Exception('Error sending request: $e');
    }
  }

  String _mapSortingOption(String option) {
    switch (option) {
      case 'descending':
        return 'desc';
      case 'ascending':
        return 'asc';
      case 'alphabetical':
        return 'alpha';
      default:
        return 'none';
    }
  }
}
