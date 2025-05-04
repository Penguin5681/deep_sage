import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../views/core_screens/visualization_and_explorer/pie_chart_visualization/dynamic_pie_chart.dart';

class ChartRenderingService {
  static final ChartRenderingService _instance =
  ChartRenderingService._internal();

  factory ChartRenderingService() {
    return _instance;
  }

  ChartRenderingService._internal();

  final LinkedHashMap<String, Widget> _chartCache = LinkedHashMap(
    equals: (a, b) => a == b,
    hashCode: (key) => key.hashCode,
  );

  final int _maxCacheSize = 250;
  bool _isRunning = false;
  Isolate? _renderIsolate;
  late ReceivePort _receivePort;
  StreamController<Map<String, dynamic>>? _optionsStreamController;

  Future<void> startRenderingService(String datasetPath) async {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _receivePort = ReceivePort();
    _optionsStreamController = StreamController<Map<String, dynamic>>();

    _renderIsolate = await Isolate.spawn(_renderChartsInBackground, [
      _receivePort.sendPort,
      datasetPath,
    ]);

    _receivePort.listen((message) {
      if (message is SendPort) {
        // This is the initial SendPort from the isolate
        final SendPort isolateSendPort = message;
        // Send options to the isolate through this port
        _optionsStreamController!.stream.listen((options) {
          isolateSendPort.send(options);
        });
      } else if (message is Map<String, dynamic>) {
        // This is chart data sent back from the isolate
        final String key = message['key'] as String;

        if (message.containsKey('error')) {
          return;
        }

        // Convert serialized data back to a widget
        try {
          final chartData = message['chartData'];
          final options = _deserializeOptions(
            message['options'] as Map<String, dynamic>,
          );

          // Create widget on the main thread using the chart data
          final widget = _createChartWidgetFromData(chartData, options);

          // Add the created widget to the cache
          _addToCache(key, widget);
        } catch (e) {
          // Error creating widget from chart data
        }
      }
    });

    _generateOptionsCombinations();
  }

  // Method to deserialize options, converting numeric color values back to Color objects
  Map<String, dynamic> _deserializeOptions(
      Map<String, dynamic> serializedOptions,
      ) {
    final deserializedOptions = <String, dynamic>{};

    serializedOptions.forEach((key, value) {
      if (key.toLowerCase().contains('color') && value is int) {
        // Convert integer value back to Color object
        deserializedOptions[key] = Color(value);
      } else if (key == 'animationCurve' && value is int) {
        // Handle animation curve
        deserializedOptions[key] = value;
      } else if (value is List) {
        // Handle lists by recursively deserializing if needed
        deserializedOptions[key] =
            value.map((item) {
              if (item is Map<String, dynamic>) {
                return _deserializeOptions(item);
              }
              return item;
            }).toList();
      } else if (value is Map) {
        // Handle nested maps
        deserializedOptions[key] = _deserializeOptions(
          value as Map<String, dynamic>,
        );
      } else {
        // Pass through other values unchanged
        deserializedOptions[key] = value;
      }
    });

    return deserializedOptions;
  }

  // Method to create a widget from the chart data returned by the isolate
  Widget _createChartWidgetFromData(
      dynamic chartData,
      Map<String, dynamic> options,
      ) {
    if (chartData is! Map<String, dynamic>) {
      throw Exception('Invalid chart data format');
    }

    // For pie charts, we need to create a DynamicPieChart
    if (options.containsKey('centerSpaceRadius')) {
      // This is a pie chart option
      return DynamicPieChart(
        // Instead of passing a file path, we pass the pre-processed data
        filePath: '', // Empty as we're using pre-processed data
        chartOptions: options,
        preProcessedData: chartData['sections'] as List<Map<String, dynamic>>?,
        key: ValueKey(
          '${DateTime.now().millisecondsSinceEpoch}_${options.hashCode}',
        ),
      );
    }

    // Return a placeholder for unsupported chart types
    return const Center(child: Text('Unsupported chart type'));
  }

  void stopRenderingService() {
    _isRunning = false;
    if (_renderIsolate != null) {
      _renderIsolate?.kill();
    }
    _receivePort.close();
    _optionsStreamController?.close();
  }

  void _generateOptionsCombinations() {
    final centerSpaceRadiusOptions = [10.0, 20.0, 30.0, 40.0, 50.0];
    final sectionsSpaceOptions = [0.0, 2.0, 4.0, 6.0];
    final startDegreeOffsetOptions = [0.0, 90.0, 180.0, 270.0];
    final sectionRadiusOptions = [80.0, 100.0, 120.0];

    final showSectionBorderOptions = [false, true];
    final sectionBorderWidthOptions = [1.0, 3.0];

    final showTitlesOptions = [true, false];
    final titlePositionOffsetOptions = [0.6];

    int optionCounter = 0;
    int cachedOptions = 0;
    int totalOptions = 0;

    for (var radius in centerSpaceRadiusOptions) {
      for (var space in sectionsSpaceOptions) {
        for (var angle in startDegreeOffsetOptions) {
          for (var sectionRadius in sectionRadiusOptions) {
            if (!_isRunning) {
              return;
            }

            totalOptions++;
            final options = {
              'centerSpaceRadius': radius,
              'centerSpaceColor': Colors.transparent,
              'sectionsSpace': space,
              'startDegreeOffset': angle,
              'sectionRadius': sectionRadius,
              'showSectionBorder': false,
              'showTitles': true,
              'titleColor': Colors.white,
              'titleSize': 14.0,
              'titlePositionOffset': 0.6,
              'enableTouch': true,
              'showTooltip': true,
            };

            final key = _generateOptionsKey(options);
            if (!_chartCache.containsKey(key)) {
              optionCounter++;
              _optionsStreamController?.add(options);
            } else {
              cachedOptions++;
            }

            if (radius == 40.0 && space == 2.0 && angle == 0.0) {
              for (var showBorder in showSectionBorderOptions) {
                if (showBorder) {
                  for (var borderWidth in sectionBorderWidthOptions) {
                    if (!_isRunning) {
                      return;
                    }

                    totalOptions++;
                    final borderOptions = Map<String, dynamic>.from(options);
                    borderOptions['showSectionBorder'] = true;
                    borderOptions['sectionBorderColor'] = Colors.white;
                    borderOptions['sectionBorderWidth'] = borderWidth;

                    final borderKey = _generateOptionsKey(borderOptions);
                    if (!_chartCache.containsKey(borderKey)) {
                      optionCounter++;
                      _optionsStreamController?.add(borderOptions);
                    } else {
                      cachedOptions++;
                    }
                  }
                }
              }
            }

            if (radius == 40.0 && space == 2.0 && angle == 0.0) {
              for (var showTitles in showTitlesOptions) {
                if (!_isRunning) {
                  return;
                }

                totalOptions++;
                final titleOptions = Map<String, dynamic>.from(options);
                titleOptions['showTitles'] = showTitles;

                if (showTitles) {
                  for (var titlePos in titlePositionOffsetOptions) {
                    titleOptions['titlePositionOffset'] = titlePos;

                    final titleKey = _generateOptionsKey(titleOptions);
                    if (!_chartCache.containsKey(titleKey)) {
                      optionCounter++;
                      _optionsStreamController?.add(titleOptions);
                    } else {
                      cachedOptions++;
                    }
                  }
                } else {
                  final titleKey = _generateOptionsKey(titleOptions);
                  if (!_chartCache.containsKey(titleKey)) {
                    optionCounter++;
                    _optionsStreamController?.add(titleOptions);
                  } else {
                    cachedOptions++;
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  String _generateOptionsKey(Map<String, dynamic> options) {
    final keyParts = <String>[];

    final sortedKeys = options.keys.toList()..sort();
    for (var key in sortedKeys) {
      final value = options[key];
      if (value is Color) {
        keyParts.add('$key:${value.value}');
      } else {
        keyParts.add('$key:$value');
      }
    }

    final key = keyParts.join('|');
    return key;
  }

  void _addToCache(String key, Widget chart) {
    if (_chartCache.length >= _maxCacheSize) {
      final removedKey = _chartCache.keys.first;
      _chartCache.remove(removedKey);
    }

    _chartCache[key] = chart;
  }

  Widget? getPreRenderedChart(Map<String, dynamic> options) {
    final key = _generateOptionsKey(options);
    if (_chartCache.containsKey(key)) {
      final chart = _chartCache.remove(key)!;
      _chartCache[key] = chart; // Move to the end (most recently used)
      return chart;
    }
    return _findClosestMatch(options);
  }

  Widget? _findClosestMatch(Map<String, dynamic> options) {
    if (_chartCache.isEmpty) {
      return null;
    }

    String? bestMatch;
    double bestScore = double.negativeInfinity;

    for (final cacheKey in _chartCache.keys) {
      final score = _calculateSimilarityScore(options, cacheKey);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = cacheKey;
      }
    }

    if (bestScore > 0.7 && bestMatch != null) {
      return _chartCache[bestMatch];
    }
    return null;
  }

  double _calculateSimilarityScore(
      Map<String, dynamic> options,
      String cacheKey,
      ) {
    final keyParts = cacheKey.split('|');
    int matchingFields = 0;

    for (var part in keyParts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0];
        final value = keyValue[1];

        if (options.containsKey(key)) {
          var optionValue = options[key];
          if (optionValue is Color) {
            optionValue = optionValue.value.toString();
          } else {
            optionValue = optionValue.toString();
          }

          if (value == optionValue) {
            matchingFields++;
          }
        }
      }
    }

    final score = matchingFields / keyParts.length;
    return score;
  }

  static void _renderChartsInBackground(List<dynamic> args) async {
    final SendPort sendPort = args[0] as SendPort;
    final String datasetPath = args[1] as String;

    // Create receive port for this isolate
    final receivePort = ReceivePort();

    // Send the SendPort of this isolate back to the main isolate
    sendPort.send(receivePort.sendPort);

    // Listen for option combinations to render
    await for (var options in receivePort) {
      if (options is Map<String, dynamic>) {
        final key = _generateOptionsKeyStatic(options);

        // Process the dataset with these options
        final chartData = await compute(_computeChartData, [
          datasetPath,
          options,
        ]);

        if (!chartData.containsKey('error')) {
          // Send back the serialized representation of the chart
          final serializedChart = {
            'key': key,
            'chartData': chartData['chartData'],
            'options': _serializeOptions(options),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };

          sendPort.send(serializedChart);
        } else {
          // Send back error information
          sendPort.send({
            'key': key,
            'error': chartData['error'],
            'options': _serializeOptions(options),
          });
        }
      }
    }
  }

  // Helper method to ensure all option values are serializable
  static Map<String, dynamic> _serializeOptions(Map<String, dynamic> options) {
    final serializedOptions = <String, dynamic>{};

    options.forEach((key, value) {
      if (value is Color) {
        // Convert Color to integer
        serializedOptions[key] = value.value;
      } else if (value is DateTime) {
        // Convert DateTime to milliseconds since epoch
        serializedOptions[key] = value.millisecondsSinceEpoch;
      } else if (value is List) {
        // Handle lists recursively if needed
        serializedOptions[key] =
            value.map((item) {
              if (item is Map<String, dynamic>) {
                return _serializeOptions(item);
              }
              return item;
            }).toList();
      } else if (value is Map) {
        // Handle nested maps recursively
        serializedOptions[key] = _serializeOptions(
          value as Map<String, dynamic>,
        );
      } else {
        // Primitive types are already serializable
        serializedOptions[key] = value;
      }
    });

    return serializedOptions;
  }

  static String _generateOptionsKeyStatic(Map<String, dynamic> options) {
    final keyParts = <String>[];
    final sortedKeys = options.keys.toList()..sort();
    for (var key in sortedKeys) {
      keyParts.add('$key:${options[key]}');
    }
    final key = keyParts.join('|');
    return key;
  }

  static Future<Map<String, dynamic>> _computeChartData(
      List<dynamic> args,
      ) async {
    final String datasetPath = args[0] as String;
    final Map<String, dynamic> options = args[1] as Map<String, dynamic>;

    try {
      // Read the dataset file
      final File file = File(datasetPath);
      if (!await file.exists()) {
        return {'error': 'Dataset file not found', 'options': options};
      }

      final String content = await file.readAsString();
      final List<String> lines = content.split('\n');

      List<Map<String, dynamic>> data = [];

      if (lines.isNotEmpty) {
        final header = lines[0].split(',').map((e) => e.trim()).toList();

        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isNotEmpty) {
            final values = lines[i].split(',').map((e) => e.trim()).toList();

            if (values.length == header.length) {
              final Map<String, dynamic> row = {};
              for (int j = 0; j < header.length; j++) {
                final value = values[j];
                final numericValue = double.tryParse(value);
                row[header[j]] = numericValue ?? value;
              }
              data.add(row);
            }
          }
        }
      }

      final processedData = _processPieChartData(data);

      return {
        'chartData': processedData,
        'options': options,
        'datasetInfo': {
          'rowCount': data.length,
          'columnsUsed': processedData['usedColumns'],
        },
      };
    } catch (e) {
      return {
        'error': 'Error processing dataset: ${e.toString()}',
        'options': options,
      };
    }
  }

  static Map<String, dynamic> _processPieChartData(
      List<Map<String, dynamic>> data,
      ) {
    if (data.isEmpty) {
      return {'sections': [], 'usedColumns': []};
    }

    final Map<String, dynamic> firstRow = data.first;
    String? labelColumn;
    String? valueColumn;

    for (final key in firstRow.keys) {
      if (firstRow[key] is String && labelColumn == null) {
        labelColumn = key;
      } else if (firstRow[key] is num && valueColumn == null) {
        valueColumn = key;
      }

      if (labelColumn != null && valueColumn != null) break;
    }

    labelColumn ??= firstRow.keys.first;
    valueColumn ??=
    firstRow.keys.length > 1
        ? firstRow.keys.elementAt(1)
        : firstRow.keys.first;

    final List<Map<String, dynamic>> sections = [];

    for (final row in data) {
      if (row[labelColumn] == null || row[valueColumn] == null) {
        continue;
      }

      sections.add({
        'label': row[labelColumn].toString(),
        'value':
        row[valueColumn] is num
            ? (row[valueColumn] as num).toDouble()
            : 0.0,
      });

      if (sections.length >= 10) {
        break;
      }
    }

    return {
      'sections': sections,
      'usedColumns': [labelColumn, valueColumn],
    };
  }

  static int min(int a, int b) {
    return a < b ? a : b;
  }
}