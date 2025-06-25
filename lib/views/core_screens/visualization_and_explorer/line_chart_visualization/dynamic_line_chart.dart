import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicLineChart extends StatefulWidget {
  final String filePath;
  final Map<String, dynamic> chartOptions;
  final List<Map<String, dynamic>>? preProcessedData;

  const DynamicLineChart({
    super.key,
    required this.filePath,
    required this.chartOptions,
    this.preProcessedData,
  });

  // Update the chart with new options
  void updateOptions(Map<String, dynamic> newOptions) {
    if (_DynamicLineChartState._instance != null) {
      _DynamicLineChartState._instance!._updateOptions(newOptions);
    }
  }

  @override
  State<DynamicLineChart> createState() => _DynamicLineChartState();
}

class _DynamicLineChartState extends State<DynamicLineChart> {
  List<List<dynamic>>? _data;
  List<String>? _headers;
  String? _selectedXColumn;
  String? _selectedYColumn;
  bool _isLoading = true;
  static _DynamicLineChartState? _instance;

  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _instance = this;
    if (widget.preProcessedData != null) {
      _processPreProcessedData();
    } else {
      _loadCsvData();
    }
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
    super.dispose();
  }

  // Method to update chart options
  void _updateOptions(Map<String, dynamic> newOptions) {
    if (mounted) {
      setState(() {
        widget.chartOptions.addAll(newOptions);
        // _buildLineChart();
      });
    }
  }

  // // Method to parse date values
  // double? parseXValue(dynamic value) {
  //   if (value is num) {
  //     return value.toDouble();
  //   } else if (value is String) {
  //     // Try parsing different date/time formats
  //     try {
  //       final date = DateTime.parse(value);
  //       return date.millisecondsSinceEpoch.toDouble();
  //     } catch (e) {
  //       // If not a date, try parsing as number
  //       return double.tryParse(value);
  //     }
  //   }
  //   return null;
  // }

  double? parseTimeValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  } else if (value is String) {
    try {
      // Try parsing different date/time formats
      DateTime? date;
      
      // Try ISO format with time
      try {
        date = DateTime.parse(value);
      } catch (_) {
        // Try custom format
        date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
      }
      
      if (date != null) {
        return date.millisecondsSinceEpoch.toDouble();
      }
    } catch (e) {
      // If not a date/time, try as number
      return double.tryParse(value);
    }
  }
  return null;
}

  // double? parseYValue(dynamic value) {
  //   if (value is num) {
  //     return value.toDouble();
  //   } else if (value is String) {
  //     // Try parsing as date first
  //     try {
  //       final date = DateTime.parse(value);
  //       return date.millisecondsSinceEpoch.toDouble();
  //     } catch (e) {
  //       // If not a date, try parsing as number
  //       return double.tryParse(value);
  //     }
  //   }
  //   return null;
  // }

  void _processPreProcessedData() {
    setState(() {
      _isLoading = false;
      _spots =
          widget.preProcessedData!
              .map(
                (row) => FlSpot(
                  (row['x'] as num).toDouble(),
                  (row['y'] as num).toDouble(),
                ),
              )
              .toList();
      _headers = null;
      _data = null;
    });
  }

  Future<void> _loadCsvData() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception("CSV File does not exist: ${widget.filePath}");
      }
      final content = await file.readAsString();
      final csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(content);

      if (csvTable.isEmpty) throw Exception("CSV File has no data");

      if (!mounted) return; // Try

      setState(() {
        _headers = csvTable[0].map((e) => e.toString()).toList();
        _data = csvTable.length > 1 ? csvTable.sublist(1) : [];
        _selectedXColumn = _headers!.first;
        _selectedYColumn = _findNumericColumn();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return; // Try
      setState(() {
        _isLoading = false;
        _data = null;
        _headers = null;
      });
    }
  }

  String? _findNumericColumn() {
    if (_headers == null ||
        _headers!.isEmpty ||
        _data == null ||
        _data!.isEmpty) {
      return null;
    }
    for (var header in _headers!) {
      final headerIndex = _headers!.indexOf(header);
      for (var row in _data!) {
        if (row.length > headerIndex) {
          final value = row[headerIndex];
          if (value is num ||
              (value != null && double.tryParse(value.toString()) != null)) {
            return header;
          }
        }
      }
    }
    return _headers!.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.preProcessedData != null) {
      _buildLineChart();
    }

    if (_data == null ||
        _headers == null ||
        _data!.isEmpty ||
        _headers!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load CSV data'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCsvData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnSelectors(),
        const SizedBox(height: 16),
        Expanded(child: _buildLineChart()),
      ],
    );
  }

  Widget _buildColumnSelectors() {
    final xColumn = _selectedXColumn ?? _headers!.first;
    final yColumn = _selectedYColumn ?? _headers!.first;

    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            'X Axis:',
            xColumn,
            _headers!,
            (value) => setState(() => _selectedXColumn = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            'Y Axis:',
            yColumn,
            _headers!,
            (value) => setState(() => _selectedYColumn = value),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        DropdownButton(
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          value: value,
          isExpanded: true,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> spots = [];

    if (widget.preProcessedData != null) {
      spots = _spots;
    } else if (_data != null &&
        _headers != null &&
        _selectedXColumn != null &&
        _selectedYColumn != null) {
      final xIndex = _headers!.indexOf(_selectedXColumn!);
      final yIndex = _headers!.indexOf(_selectedYColumn!);

      if (xIndex < 0 || yIndex < 0) {
        return Center(
          child: Text(
            'Invalid columns selected: $_selectedXColumn, $_selectedYColumn',
          ),
        );
      }

      // Modify the parsing logic to handle date/time values
      for (var row in _data!) {
        if (row.length <= xIndex || row.length <= yIndex) continue;
        final xRaw = row[xIndex];
        final yRaw = row[yIndex];

        double? x = parseTimeValue(xRaw);
        double? y = parseTimeValue(yRaw);
        // double? x =
        //     xRaw is num ? xRaw.toDouble() : double.tryParse(xRaw.toString());
        // double? y =
        //     yRaw is num ? yRaw.toDouble() : double.tryParse(yRaw.toString());

        if (x != null && y != null) {
          spots.add(FlSpot(x, y));
        }
      }
      spots.sort((a, b) => a.x.compareTo(b.x));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No valid data to display in chart'));
    }

    // Calculate min and max values for X and Y axes
    final minX =
        spots.isNotEmpty
            ? spots.map((e) => e.x).reduce((a, b) => a < b ? a : b)
            : 0;
    final maxX =
        spots.isNotEmpty
            ? spots.map((e) => e.x).reduce((a, b) => a > b ? a : b)
            : 0;
    final minYData =
        spots.isNotEmpty
            ? spots.map((e) => e.y).reduce((a, b) => a < b ? a : b)
            : 0;
    final maxYData =
        spots.isNotEmpty
            ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
            : 0;

    // Add some padding to the min/max values (10% of the range for better visibility)
    final xPadding = (maxX - minX) * 0.1;
    final yPadding = (maxYData - minYData) * 0.1;

    // Chart options (with defaults)
    final lineColor = widget.chartOptions['lineColor'] ?? Colors.blue;
    final lineWidth = widget.chartOptions['lineWidth'] ?? 3.0;
    final isCurved = widget.chartOptions['isCurved'] ?? true;
    final showDots = widget.chartOptions['showDots'] ?? true;
    final dotColor = widget.chartOptions['dotColor'] ?? Colors.blue;
    final dotSize = widget.chartOptions['dotSize'] ?? 5.0;
    final showGrid = widget.chartOptions['gridLines'] ?? true;
    final showTooltip = widget.chartOptions['showTooltip'] ?? true;
    final backgroundColor =
        widget.chartOptions['backgroundColor'] ?? Colors.transparent;
    // final autoScale = widget.chartOptions['autoScale'] ?? true;

    // // Calculate Y-axis bounds based on autoScale setting
    // double minY, maxY;
    // if (autoScale || widget.chartOptions['minY'] == null) {
    //   minY = minYData - yPadding;
    // } else {
    //   minY = widget.chartOptions['minY'];
    // }

    // if (autoScale || widget.chartOptions['maxY'] == null) {
    //   maxY = maxYData + yPadding;
    // } else {
    //   maxY = widget.chartOptions['maxY'];
    // }

    // Calculate min/max Y if auto-scale is enabled
    final autoScale = widget.chartOptions['autoScale'] ?? true;
    final minY = autoScale ? (minYData - yPadding) : widget.chartOptions['minY'];
    final maxY = autoScale ? (maxYData + yPadding) : widget.chartOptions['maxY'];

    // if (autoScale && spots.isNotEmpty) {
    //   final minYData = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    //   final maxYData = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    //   final padding = (maxYData - minYData) * 0.1;
    //   widget.chartOptions['minY'] = minYData - padding;
    //   widget.chartOptions['maxY'] = maxYData + padding;
    // }

    // X-axis bounds (always auto-scaled with padding)
    final effectiveMinX = minX - xPadding;
    final effectiveMaxX = maxX + xPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Create a ClipRect to ensure nothing renders outside the container bounds
        return ClipRect(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: backgroundColor,
            child: LineChart(
              LineChartData(
                minX: effectiveMinX,
                maxX: effectiveMaxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: showGrid),
                titlesData: _buildTitlesData(),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                clipData:
                    FlClipData.all(), // Important: Enable clipping on all sides
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: isCurved,
                    color: lineColor,
                    barWidth: lineWidth,
                    isStrokeCapRound: true, // Round the ends of lines
                    preventCurveOverShooting:
                        true, // Prevent curve overshooting
                    dotData: FlDotData(
                      show: showDots,
                      getDotPainter:
                          (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: dotSize,
                            color: dotColor,
                            strokeWidth: 0,
                          ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: showTooltip,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipMargin: 16,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipHorizontalOffset: 0,

                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    // Update the tooltip to show formatted dates for both axes:
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final xValue =
                            _isDateColumn(_selectedXColumn!)
                                ? DateFormat('yyyy-MM-dd HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    spot.x.toInt(),
                                  ),
                                )
                                : spot.x.toStringAsFixed(2);

                        final yValue =
                            _isDateColumn(_selectedYColumn!)
                                ? DateFormat('yyyy-MM-dd HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    spot.y.toInt(),
                                  ),
                                )
                                : spot.y.toStringAsFixed(2);

                        return LineTooltipItem(
                          '($xValue,\n$yValue)',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.blue.withValues(alpha: 0.8),
                          strokeWidth: 2,
                          dashArray: [
                            5,
                            5,
                          ], // Optional: creates dashed vertical line
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 8,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: barData.color ?? Colors.blue,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [],
                  verticalLines: [],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build titles data
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          // interval: null, // Let FL Chart determine the interval
          getTitlesWidget: (value, meta) {
            // Check if the column is a date column
            if (_selectedXColumn != null && _isDateColumn(_selectedXColumn!)) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              );
            }
            // For non-date columns, just show the number
            return SideTitleWidget(
              meta: meta,
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          // interval: null, // Let FL Chart determine the interval
          getTitlesWidget: (value, meta) {
            if (_selectedYColumn != null && _isDateColumn(_selectedYColumn!)) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('HH:mm').format(date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            );
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // Add helper method to check if a column contains dates
  bool _isDateColumn(String columnName) {
    if (_data == null || _data!.isEmpty) return false;

    final columnIndex = _headers!.indexOf(columnName);
    if (columnIndex < 0) return false;

    // Check first few non-null values in the column
    int checkedValues = 0;
    for (var row in _data!) {
      if (row.length > columnIndex && row[columnIndex] != null) {
        if (row[columnIndex] is String) {
          try {
            DateTime.parse(row[columnIndex].toString());
            checkedValues++;
            if (checkedValues >= 3) return true; // If first 3 values are dates
          } catch (_) {
            return false;
          }
        } else {
          return false;
        }
      }
    }
    return checkedValues > 0;
  }
}
