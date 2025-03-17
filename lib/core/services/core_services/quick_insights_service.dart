import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A service for generating quick insights from CSV data using the analytics API.
///
/// This service communicates with the '/api/analyze-csv' endpoint to process CSV files
/// and extract statistical information such as column types, missing values,
/// numerical statistics, categorical distributions, and data quality metrics.
class QuickInsightsService {
  /// The base URL for the API.
  final String baseUrl;

  /// Creates a new [QuickInsightsService] with the specified [baseUrl].
  ///
  /// If [baseUrl] is not provided, it defaults to 'http://localhost:5000'.
  QuickInsightsService({this.baseUrl = 'http://localhost:5000'});

  /// Analyzes a CSV file and returns insights data.
  ///
  /// Takes a [File] object representing the CSV file to analyze.
  /// The [useAI] parameter determines whether to use AI-powered analysis (defaults to false).
  ///
  /// Returns a [Future] that completes with a [Map] containing the analysis results.
  /// Returns null if the request fails.
  Future<Map<String, dynamic>?> analyzeCsvFile(File csvFile, {bool useAI = false}) async {
    try {
      // Create multipart request
      final uri = Uri.parse('$baseUrl/api/analyze-csv?use_ai=$useAI');
      final request = http.MultipartRequest('POST', uri);

      // Add the file to the request
      final fileStream = http.ByteStream(csvFile.openRead());
      final fileLength = await csvFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: csvFile.path.split('/').last
      );
      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to analyze CSV. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error analyzing CSV file: $e');
      return null;
    }
  }

  /// Extracts basic data quality information from the insights result.
  ///
  /// Takes the [insights] map returned from [analyzeCsvFile].
  /// Returns a [Map] containing simplified data quality metrics.
  Map<String, dynamic> extractDataQualitySummary(Map<String, dynamic> insights) {
    final dataQuality = insights['basic_insights']['data_quality'];
    return {
      'overall_score': dataQuality['overall_score'],
      'completeness_score': dataQuality['completeness_score'],
      'duplication_score': dataQuality['duplication_score'],
      'outlier_score': dataQuality['outlier_score'],
      'missing_percentage': dataQuality['total_missing_percentage'],
      'column_types': dataQuality['column_types'],
    };
  }

  /// Extracts column statistics from the insights result.
  ///
  /// Takes the [insights] map returned from [analyzeCsvFile].
  /// Returns a [Map] with column names as keys and their statistics as values.
  Map<String, dynamic> extractColumnStats(Map<String, dynamic> insights) {
    final basicInsights = insights['basic_insights'];
    final result = <String, dynamic>{};

    // Add numerical statistics
    if (basicInsights.containsKey('numeric_stats')) {
      result['numeric_stats'] = basicInsights['numeric_stats'];
    }

    // Add categorical statistics
    if (basicInsights.containsKey('categorical_stats')) {
      result['categorical_stats'] = basicInsights['categorical_stats'];
    }

    // Add missing values information
    if (basicInsights.containsKey('missing_values')) {
      result['missing_values'] = basicInsights['missing_values'];
    }

    // Add outliers information
    if (basicInsights.containsKey('outliers')) {
      result['outliers'] = basicInsights['outliers'];
    }

    return result;
  }

  /// Gets a summary of the dataset from the insights result.
  ///
  /// Takes the [insights] map returned from [analyzeCsvFile].
  /// Returns a [Map] containing general dataset information.
  Map<String, dynamic> getDatasetSummary(Map<String, dynamic> insights) {
    final basicInsights = insights['basic_insights'];
    return {
      'row_count': basicInsights['row_count'],
      'column_count': basicInsights['column_count'],
      'columns': basicInsights['columns'],
      'data_types': basicInsights['data_types'],
      'duplicates': basicInsights['duplicates'],
    };
  }
}