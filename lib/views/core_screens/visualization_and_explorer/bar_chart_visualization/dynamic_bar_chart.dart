import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class DynamicBarChart extends StatefulWidget {
  final String filePath;
  final Map<String, dynamic> chartOptions;

  const DynamicBarChart({
    super.key,
    required this.filePath,
    required this.chartOptions,
  });

  // For live update support (optional, like in DynamicLineChart)
  void updateOptions(Map<String, dynamic> newOptions) {
    if (_DynamicBarChartState._instance != null) {
      _DynamicBarChartState._instance!._updateOptions(newOptions);
    }
  }

  @override
  State<DynamicBarChart> createState() => _DynamicBarChartState();
}

class _DynamicBarChartState extends State<DynamicBarChart> {
  List<List<dynamic>>? _data;
  List<String>? _headers;
  String? _selectedXColumn;
  String? _selectedYColumn;
  bool _isLoading = true;
  static _DynamicBarChartState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _loadCsvData();
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
    super.dispose();
  }

  void _updateOptions(Map<String, dynamic> newOptions) {
    if (mounted) {
      setState(() {
        widget.chartOptions.addAll(newOptions);
      });
    }
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

      if (!mounted) return;

      setState(() {
        _headers = csvTable[0].map((e) => e.toString()).toList();
        _data = csvTable.length > 1 ? csvTable.sublist(1) : [];
        _selectedXColumn = widget.chartOptions['selectedXColumn'] ?? _headers!.first;
        _selectedYColumn = widget.chartOptions['selectedYColumn'] ?? _findNumericColumn();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
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
        Expanded(child: _buildBarChart()),
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
            (value) {
              setState(() {
                _selectedXColumn = value;
                widget.chartOptions['selectedXColumn'] = value;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            'Y Axis:',
            yColumn,
            _headers!,
            (value) {
              setState(() {
                _selectedYColumn = value;
                widget.chartOptions['selectedYColumn'] = value;
              });
            },
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
          items: items
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

  Widget _buildBarChart() {
    List<BarChartGroupData> barGroups = [];



    if (_data != null &&
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

      for (int i = 0; i < _data!.length; i++) {
        final row = _data![i];
        if (row.length <= xIndex || row.length <= yIndex) continue;
        final xRaw = row[xIndex];
        final yRaw = row[yIndex];

        double? y = yRaw is num ? yRaw.toDouble() : double.tryParse(yRaw.toString());
        if (y != null) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: y,
                  color: widget.chartOptions['barColor'] ?? Colors.blue,
                  width: (widget.chartOptions['barWidth'] ?? 16.0).toDouble(),
                  borderRadius: BorderRadius.circular(
                      (widget.chartOptions['borderRadius'] ?? 4.0).toDouble()),
                  borderSide: (widget.chartOptions['showBorder'] ?? false)
                      ? BorderSide(
                          color: widget.chartOptions['borderColor'] ?? Colors.black,
                          width: (widget.chartOptions['borderWidth'] ?? 1.0).toDouble(),
                        )
                      : BorderSide.none,
                  backDrawRodData: BackgroundBarChartRodData(show: false),
                ),
              ],
            ),
          );
        }
      }
    }

    if (barGroups.isEmpty) {
      return const Center(child: Text('No valid data to display in chart'));
    }

    // Axis bounds
    final minY = widget.chartOptions['minY'] ?? 0.0;
    final maxY = widget.chartOptions['maxY'] ?? (barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.1);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: widget.chartOptions['backgroundColor'] ?? Colors.transparent,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                groupsSpace: (widget.chartOptions['groupsSpace'] ?? 16.0).toDouble(),
                alignment: BarChartAlignment.values[
                    (widget.chartOptions['alignment'] ?? 0).clamp(0, 2)],
                gridData: FlGridData(show: widget.chartOptions['showGrid'] ?? true),
                borderData: FlBorderData(
                  show: widget.chartOptions['showBorderData'] ?? false,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (_data != null &&
                            value.toInt() >= 0 &&
                            value.toInt() < _data!.length) {
                          final xIndex = _headers!.indexOf(_selectedXColumn!);
                          final xVal = _data![value.toInt()][xIndex];
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(xVal.toString(), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minY: minY,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: widget.chartOptions['enableTouch'] ?? true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final xIndex = _headers!.indexOf(_selectedXColumn!);
                      final xVal = _data![group.x.toInt()][xIndex];
                      return BarTooltipItem(
                        '$xVal\n${rod.toY}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                  allowTouchBarBackDraw: widget.chartOptions['allowBackgroundBarTouch'] ?? true,
                ),
                baselineY: widget.chartOptions['baselineY'] ?? 0.0,
              ),
            ),
          ),
        );
      },
    );
  }
}