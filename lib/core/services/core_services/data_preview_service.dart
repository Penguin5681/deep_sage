import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;

class DataPreviewService {
  /// Base URL for API requests, retrieved from environment variables.
  /// Defaults to 'http://localhost:5000' if not specified.
  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';

  /// Loads a preview of a dataset from the specified file path.
  ///
  /// Makes an API request to retrieve a preview of the dataset.
  ///
  /// Parameters:
  /// - [filePath]: The path to the file to be previewed
  /// - [fileType]: The type of the file (e.g., 'csv', 'json')
  /// - [previewRows]: Number of rows to retrieve in the preview
  ///
  /// Returns:
  /// - A [Future] that completes with a [Map] containing the preview data
  ///   or `null` if an error occurs
  Future<Map<String, dynamic>?> loadDatasetPreview(
    String filePath,
    String fileType,
    int previewRows,
  ) async {
    // For CSV files, use direct file handling for better performance
    if (fileType.toLowerCase() == 'csv') {
      return _loadCsvPreviewDirectly(filePath, previewRows);
    }

    try {
      debugPrint('Requesting preview for: $filePath (type: $fileType)');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/data/preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_path': filePath,
          'n_rows': previewRows,
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

  /// Loads a preview of a CSV file directly from the file system.
  ///
  /// This method reads a CSV file directly, extracts the header and a
  /// specified number of rows for preview, and constructs metadata about the file.
  ///
  /// Parameters:
  /// - [filePath]: The path to the CSV file.
  /// - [previewRows]: The number of rows to include in the preview.
  ///
  /// Returns:
  /// - A [Future] that completes with a [Map] containing:
  ///   - 'columns': A list of column headers (String).
  ///   - 'preview': A list of maps, where each map represents a row of data
  ///     and keys are column names.
  ///   - 'metadata': Metadata about the file (Map).
  /// - Returns `null` if the file does not exist or an error occurs.
  ///
  /// Throws:
  /// - Any exception that occurs during file reading or parsing.
  ///
  Future<Map<String, dynamic>?> _loadCsvPreviewDirectly(
    String filePath,
    int previewRows,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('CSV file not found: $filePath');
        return null;
      }

      final fileSize = await file.length();
      List<String> headerLine = [];
      List<Map<String, dynamic>> preview = [];

      // Estimate total rows based on average line size for large files
      int totalRows = 0;
      bool isLargeFile = fileSize > 10 * 1024 * 1024; // 10MB threshold

      final inputStream = file.openRead();
      final lines = inputStream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      // Create a limited stream that stops after previewRows + 1 lines (header + data rows)
      int lineCount = 0;

      await for (var line in lines) {
        // Stop reading when we have enough rows
        if (lineCount > previewRows) {
          break;
        }

        if (lineCount == 0) {
          // Parse header
          try {
            headerLine =
                const CsvToListConverter()
                    .convert(line)
                    .first
                    .map((e) => e.toString())
                    .toList();
          } catch (e) {
            debugPrint('Error parsing CSV header: $e');
            headerLine = List<String>.generate(
              line.split(',').length,
              (i) => 'Column_${i + 1}',
            );
          }
        } else {
          // Parse data rows
          try {
            final parsedRow = const CsvToListConverter().convert(line).first;
            final rowMap = <String, dynamic>{};
            for (
              int i = 0;
              i < headerLine.length && i < parsedRow.length;
              i++
            ) {
              rowMap[headerLine[i]] = parsedRow[i];
            }
            preview.add(rowMap);
          } catch (e) {
            debugPrint('Error parsing CSV row $lineCount: $e');
          }
        }

        lineCount++;
      }

      // For large files, use an estimation of total rows
      if (isLargeFile) {
        final avgRowSize = lineCount > 1 ? fileSize / lineCount : fileSize;
        totalRows =
            (fileSize / avgRowSize).round() - 1; // Subtract 1 for header
        totalRows = totalRows.clamp(preview.length, double.infinity).toInt();
      } else {
        // For smaller files, we can count rows more accurately
        try {
          totalRows =
              await _countCsvLines(filePath) - 1; // Subtract 1 for header
        } catch (e) {
          totalRows = preview.length; // Fallback to what we know
        }
      }

      return {
        'columns': headerLine,
        'preview': preview,
        'metadata': _buildMetadata(
          filePath,
          totalRows,
          fileSize,
          preview.length,
        ),
      };
    } catch (e) {
      debugPrint('Error loading CSV directly: $e');
      return null;
    }
  }

  // Helper method to count lines in a file more efficiently
  Future<int> _countCsvLines(String filePath) async {
    final file = File(filePath);
    final sampleSize = 1024 * 64; // 64KB sample

    if (await file.length() < sampleSize * 2) {
      // Small file, just count lines directly
      return LineSplitter().convert(await file.readAsString()).length;
    }

    // For larger files, use statistical estimation
    final fileSize = await file.length();
    final sample =
        await file.openRead(0, sampleSize).transform(utf8.decoder).join();
    final sampleLineCount = LineSplitter().convert(sample).length;

    // Extrapolate the total based on the sample
    final bytesPerLine = sampleSize / sampleLineCount;
    return (fileSize / bytesPerLine).round();
  }

  /// Saves edited CSV data back to the file.
  ///
  /// This method takes a list of dynamic lists (representing the CSV data)
  /// and writes it back to the original file location.
  ///
  /// Parameters:
  /// - [filePath]: Path to save the CSV file
  /// - [csvData]: List of lists containing the CSV data to save
  ///
  /// Returns:
  /// - A [Future<bool>] indicating success or failure
  Future<bool> saveCsvData(String filePath, List<List<dynamic>> csvData) async {
    try {
      final file = File(filePath);
      final csv = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csv);
      return true;
    } catch (e) {
      debugPrint('Error saving CSV data: $e');
      return false;
    }
  }

  /// Builds metadata for the dataset preview.
  ///
  /// Creates a structured map containing information about the dataset file.
  ///
  /// Parameters:
  /// - [filePath]: Path to the dataset file
  /// - [totalRows]: Total number of rows in the dataset
  /// - [fileSize]: File size in bytes
  /// - [previewRows]: Number of rows in the preview
  ///
  /// Returns:
  /// - A [Map] containing metadata information
  Map<String, dynamic> _buildMetadata(
    String filePath,
    int totalRows,
    int fileSize,
    int previewRows,
  ) {
    String fileSizeFormatted;

    if (fileSize < 1024) {
      fileSizeFormatted = '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      fileSizeFormatted = '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      fileSizeFormatted = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return {
      'file_name': path.basename(filePath),
      'file_path': filePath,
      'file_type': path.extension(filePath).replaceFirst('.', ''),
      'total_rows': totalRows,
      'preview_rows': previewRows,
      'file_size': fileSize,
      'file_size_formatted': fileSizeFormatted,
    };
  }
}
