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
    debugPrint('ChartRenderingService: Factory constructor called');
    return _instance;
  }

  ChartRenderingService._internal() {
    debugPrint('ChartRenderingService: Internal constructor initialized');
  }

  // This would be the LRU cache to store the pre-rendered charts with 50mb lim
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
    debugPrint(
      'ChartRenderingService: Starting rendering service with dataset: $datasetPath',
    );
    if (_isRunning) {
      debugPrint(
        'ChartRenderingService: Service already running, exiting start method',
      );
      return;
    }

    _isRunning = true;
    _receivePort = ReceivePort();
    _optionsStreamController = StreamController<Map<String, dynamic>>();

    debugPrint('ChartRenderingService: Spawning render isolate');
    _renderIsolate = await Isolate.spawn(_renderChartsInBackground, [
      _receivePort.sendPort,
      datasetPath,
    ]);
    debugPrint('ChartRenderingService: Render isolate spawned successfully');

    _receivePort.listen((message) {
      debugPrint('ChartRenderingService: Received message from isolate');
      if (message is SendPort) {
        // This is the initial SendPort from the isolate
        debugPrint('ChartRenderingService: Received send port from isolate');
        final SendPort isolateSendPort = message;
        // Send options to the isolate through this port
        _optionsStreamController!.stream.listen((options) {
          isolateSendPort.send(options);
        });
      } else if (message is Map<String, dynamic>) {
        // This is chart data sent back from the isolate
        debugPrint('ChartRenderingService: Received chart data from isolate');

        final String key = message['key'] as String;

        if (message.containsKey('error')) {
          debugPrint(
            'ChartRenderingService: Error received: ${message['error']}',
          );
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

          debugPrint(
            'ChartRenderingService: Successfully added pre-rendered chart to cache',
          );
        } catch (e) {
          debugPrint(
            'ChartRenderingService: Error creating widget from chart data: $e',
          );
        }
      }
    });

    debugPrint(
      'ChartRenderingService: Starting to generate options combinations',
    );
    _generateOptionsCombinations();
    debugPrint(
      'ChartRenderingService: Finished generating options combinations',
    );
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
    debugPrint(
      'ChartRenderingService: Creating chart widget from pre-processed data',
    );

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
    debugPrint('ChartRenderingService: Stopping rendering service');
    _isRunning = false;
    if (_renderIsolate != null) {
      debugPrint('ChartRenderingService: Killing render isolate');
      _renderIsolate?.kill();
    }
    debugPrint('ChartRenderingService: Closing receive port');
    _receivePort.close();
    debugPrint('ChartRenderingService: Closing options stream controller');
    _optionsStreamController?.close();
    debugPrint('ChartRenderingService: Service stopped');
  }

  void _generateOptionsCombinations() {
    debugPrint('ChartRenderingService: Generating options combinations');
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
              debugPrint(
                'ChartRenderingService: Service stopped during generation, exiting',
              );
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
              debugPrint(
                'ChartRenderingService: Adding option combination $optionCounter: radius=$radius, space=$space, angle=$angle, sectionRadius=$sectionRadius',
              );
              _optionsStreamController?.add(options);
            } else {
              cachedOptions++;
              debugPrint(
                'ChartRenderingService: Option already in cache: radius=$radius, space=$space, angle=$angle, sectionRadius=$sectionRadius',
              );
            }

            if (radius == 40.0 && space == 2.0 && angle == 0.0) {
              for (var showBorder in showSectionBorderOptions) {
                if (showBorder) {
                  for (var borderWidth in sectionBorderWidthOptions) {
                    if (!_isRunning) {
                      debugPrint(
                        'ChartRenderingService: Service stopped during border options generation, exiting',
                      );
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
                      debugPrint(
                        'ChartRenderingService: Adding border option combination $optionCounter: borderWidth=$borderWidth',
                      );
                      _optionsStreamController?.add(borderOptions);
                    } else {
                      cachedOptions++;
                      debugPrint(
                        'ChartRenderingService: Border option already in cache: borderWidth=$borderWidth',
                      );
                    }
                  }
                }
              }
            }

            if (radius == 40.0 && space == 2.0 && angle == 0.0) {
              for (var showTitles in showTitlesOptions) {
                if (!_isRunning) {
                  debugPrint(
                    'ChartRenderingService: Service stopped during title options generation, exiting',
                  );
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
                      debugPrint(
                        'ChartRenderingService: Adding title option combination $optionCounter: showTitles=$showTitles, titlePos=$titlePos',
                      );
                      _optionsStreamController?.add(titleOptions);
                    } else {
                      cachedOptions++;
                      debugPrint(
                        'ChartRenderingService: Title option already in cache: showTitles=$showTitles, titlePos=$titlePos',
                      );
                    }
                  }
                } else {
                  final titleKey = _generateOptionsKey(titleOptions);
                  if (!_chartCache.containsKey(titleKey)) {
                    optionCounter++;
                    debugPrint(
                      'ChartRenderingService: Adding title option combination $optionCounter: showTitles=$showTitles',
                    );
                    _optionsStreamController?.add(titleOptions);
                  } else {
                    cachedOptions++;
                    debugPrint(
                      'ChartRenderingService: Title option already in cache: showTitles=$showTitles',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
    debugPrint(
      'ChartRenderingService: Generated $optionCounter new options, $cachedOptions were already cached, total options considered: $totalOptions',
    );
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
    debugPrint(
      'ChartRenderingService: Generated options key: ${key.substring(0, min(30, key.length))}...',
    );
    return key;
  }

  void _addToCache(String key, Widget chart) {
    debugPrint(
      'ChartRenderingService: Adding chart to cache, current size: ${_chartCache.length}',
    );
    if (_chartCache.length >= _maxCacheSize) {
      final removedKey = _chartCache.keys.first;
      debugPrint(
        'ChartRenderingService: Cache full, removing oldest item: ${removedKey.substring(0, min(20, removedKey.length))}...',
      );
      _chartCache.remove(removedKey);
    }

    _chartCache[key] = chart;
    debugPrint(
      'ChartRenderingService: Chart added to cache, new size: ${_chartCache.length}',
    );
  }

  Widget? getPreRenderedChart(Map<String, dynamic> options) {
    final key = _generateOptionsKey(options);
    debugPrint(
      'ChartRenderingService: Looking for pre-rendered chart with key: ${key.substring(0, min(20, key.length))}...',
    );
    if (_chartCache.containsKey(key)) {
      debugPrint('ChartRenderingService: Found exact match in cache');
      final chart = _chartCache.remove(key)!;
      _chartCache[key] = chart; // Move to the end (most recently used)
      return chart;
    }
    debugPrint(
      'ChartRenderingService: No exact match found, looking for closest match',
    );
    return _findClosestMatch(options);
  }

  Widget? _findClosestMatch(Map<String, dynamic> options) {
    if (_chartCache.isEmpty) {
      debugPrint(
        'ChartRenderingService: Cache is empty, no closest match can be found',
      );
      return null;
    }

    String? bestMatch;
    double bestScore = double.negativeInfinity;

    debugPrint(
      'ChartRenderingService: Searching for closest match among ${_chartCache.length} cached items',
    );
    for (final cacheKey in _chartCache.keys) {
      final score = _calculateSimilarityScore(options, cacheKey);
      debugPrint(
        'ChartRenderingService: Similarity score for ${cacheKey.substring(0, min(20, cacheKey.length))}... is $score',
      );
      if (score > bestScore) {
        bestScore = score;
        bestMatch = cacheKey;
        debugPrint(
          'ChartRenderingService: New best match found with score $bestScore',
        );
      }
    }

    if (bestScore > 0.7 && bestMatch != null) {
      debugPrint(
        'ChartRenderingService: Using closest match with score $bestScore: ${bestMatch.substring(0, min(20, bestMatch.length))}...',
      );
      return _chartCache[bestMatch];
    }
    debugPrint(
      'ChartRenderingService: No sufficient match found (best score: $bestScore)',
    );
    return null;
  }

  double _calculateSimilarityScore(
    Map<String, dynamic> options,
    String cacheKey,
  ) {
    final keyParts = cacheKey.split('|');
    int matchingFields = 0;
    debugPrint(
      'ChartRenderingService: Calculating similarity score for key with ${keyParts.length} parts',
    );

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
            debugPrint(
              'ChartRenderingService: Field $key matches with value $value',
            );
          } else {
            debugPrint(
              'ChartRenderingService: Field $key does not match: $value vs $optionValue',
            );
          }
        } else {
          debugPrint(
            'ChartRenderingService: Field $key not found in request options',
          );
        }
      }
    }

    final score = matchingFields / keyParts.length;
    debugPrint(
      'ChartRenderingService: Final similarity score: $score (matched $matchingFields out of ${keyParts.length})',
    );
    return score;
  }

  static void _renderChartsInBackground(List<dynamic> args) async {
    debugPrint(
      'ChartRenderingService [Isolate]: Background rendering process started',
    );
    final SendPort sendPort = args[0] as SendPort;
    final String datasetPath = args[1] as String;
    debugPrint(
      'ChartRenderingService [Isolate]: Using dataset path: $datasetPath',
    );

    // Create receive port for this isolate
    final receivePort = ReceivePort();

    // Send the SendPort of this isolate back to the main isolate
    sendPort.send(receivePort.sendPort);
    debugPrint('ChartRenderingService [Isolate]: Send port established');

    // Listen for option combinations to render
    await for (var options in receivePort) {
      if (options is Map<String, dynamic>) {
        debugPrint(
          'ChartRenderingService [Isolate]: Received options to render',
        );
        final key = _generateOptionsKeyStatic(options);
        debugPrint(
          'ChartRenderingService [Isolate]: Generated key for options: ${key.substring(0, min(30, key.length))}...',
        );

        // Process the dataset with these options
        debugPrint('ChartRenderingService [Isolate]: Computing chart data');
        final chartData = await compute(_computeChartData, [
          datasetPath,
          options,
        ]);
        debugPrint(
          'ChartRenderingService [Isolate]: Chart data computation completed',
        );

        if (!chartData.containsKey('error')) {
          // Send back the serialized representation of the chart
          debugPrint(
            'ChartRenderingService [Isolate]: Sending back processed chart data',
          );

          // Create serializable representation with all necessary information
          final serializedChart = {
            'key': key,
            'chartData': chartData['chartData'],
            'options': _serializeOptions(
              options,
            ), // Ensure all values are serializable
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };

          sendPort.send(serializedChart);
          debugPrint(
            'ChartRenderingService [Isolate]: Chart data sent to main isolate',
          );
        } else {
          debugPrint(
            'ChartRenderingService [Isolate]: Error in chart data: ${chartData['error']}',
          );
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
    debugPrint('ChartRenderingService [Static]: Generating static options key');
    for (var key in sortedKeys) {
      keyParts.add('$key:${options[key]}');
    }
    final key = keyParts.join('|');
    debugPrint(
      'ChartRenderingService [Static]: Static key generated: ${key.substring(0, min(30, key.length))}...',
    );
    return key;
  }

  static Future<Map<String, dynamic>> _computeChartData(
    List<dynamic> args,
  ) async {
    final String datasetPath = args[0] as String;
    final Map<String, dynamic> options = args[1] as Map<String, dynamic>;
    debugPrint(
      'ChartRenderingService [Compute]: Computing chart data for dataset: $datasetPath',
    );

    try {
      // Read the dataset file
      final File file = File(datasetPath);
      if (!await file.exists()) {
        debugPrint(
          'ChartRenderingService [Compute]: Dataset file not found: $datasetPath',
        );
        return {'error': 'Dataset file not found', 'options': options};
      }

      debugPrint('ChartRenderingService [Compute]: Reading dataset file');
      final String content = await file.readAsString();
      final List<String> lines = content.split('\n');
      debugPrint(
        'ChartRenderingService [Compute]: Dataset has ${lines.length} lines',
      );

      List<Map<String, dynamic>> data = [];

      if (lines.isNotEmpty) {
        final header = lines[0].split(',').map((e) => e.trim()).toList();
        debugPrint(
          'ChartRenderingService [Compute]: Dataset header: ${header.join(", ")}',
        );

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

      debugPrint(
        'ChartRenderingService [Compute]: Parsed ${data.length} rows from dataset',
      );
      debugPrint(
        'ChartRenderingService [Compute]: Processing for pie chart format',
      );
      final processedData = _processPieChartData(data);
      debugPrint(
        'ChartRenderingService [Compute]: Chart data processed with ${processedData['sections']?.length ?? 0} sections',
      );

      return {
        'chartData': processedData,
        'options': options,
        'datasetInfo': {
          'rowCount': data.length,
          'columnsUsed': processedData['usedColumns'],
        },
      };
    } catch (e) {
      debugPrint(
        'ChartRenderingService [Compute]: Error processing dataset: ${e.toString()}',
      );
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
      debugPrint(
        'ChartRenderingService [Process]: Empty dataset, returning empty sections',
      );
      return {'sections': [], 'usedColumns': []};
    }

    final Map<String, dynamic> firstRow = data.first;
    String? labelColumn;
    String? valueColumn;
    debugPrint(
      'ChartRenderingService [Process]: Analyzing first row for label and value columns',
    );

    for (final key in firstRow.keys) {
      if (firstRow[key] is String && labelColumn == null) {
        labelColumn = key;
        debugPrint(
          'ChartRenderingService [Process]: Found label column: $labelColumn',
        );
      } else if (firstRow[key] is num && valueColumn == null) {
        valueColumn = key;
        debugPrint(
          'ChartRenderingService [Process]: Found value column: $valueColumn',
        );
      }

      if (labelColumn != null && valueColumn != null) break;
    }

    labelColumn ??= firstRow.keys.first;
    valueColumn ??=
        firstRow.keys.length > 1
            ? firstRow.keys.elementAt(1)
            : firstRow.keys.first;
    debugPrint(
      'ChartRenderingService [Process]: Using label column: $labelColumn, value column: $valueColumn',
    );

    final List<Map<String, dynamic>> sections = [];

    for (final row in data) {
      if (row[labelColumn] == null || row[valueColumn] == null) {
        debugPrint(
          'ChartRenderingService [Process]: Skipping row with null label or value',
        );
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
        debugPrint(
          'ChartRenderingService [Process]: Reached max of 10 sections, stopping',
        );
        break;
      }
    }

    debugPrint(
      'ChartRenderingService [Process]: Created ${sections.length} sections for pie chart',
    );
    return {
      'sections': sections,
      'usedColumns': [labelColumn, valueColumn],
    };
  }

  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
