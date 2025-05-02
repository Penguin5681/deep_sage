import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:googleapis/apigeeregistry/v1.dart';

class DynamicPieChart extends StatefulWidget {
  final String filePath;
  final Map<String, dynamic> chartOptions;

  const DynamicPieChart({super.key, required this.filePath, required this.chartOptions});

  @override
  State<DynamicPieChart> createState() => _DynamicPieChartState();
}

class _DynamicPieChartState extends State<DynamicPieChart> {
  List<List<dynamic>>? _data;
  List<String>? _headers;
  String? _selectedCategoryColumn;
  String? _selectedValueColumn;
  String? _selectedFilterColumn;
  String? _selectedFilterValue;
  bool _isLoading = true;

  List<PieChartSectionData> _sections = [];
  Map<String, double>? _sectionData;
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _loadCsvData();
  }

  Future<void> _loadCsvData() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception("CSV File does not exist: ${widget.filePath}");
      }

      final content = await file.readAsString();
      debugPrint('CSV content length: ${content.length} bytes');

      // Fix parsing issues by forcing the parsing format
      final csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(content);

      debugPrint('CSV rows: ${csvTable.length}');

      if (csvTable.isEmpty) {
        throw Exception("CSV File has no data");
      }

      setState(() {
        _headers = csvTable[0].map((e) => e.toString()).toList();
        debugPrint('Headers: ${_headers!.join(', ')}');

        // Get data rows (everything after header row)
        _data = csvTable.length > 1 ? csvTable.sublist(1) : [];

        // Log the first few rows to verify
        if (_data!.isNotEmpty) {
          for (int i = 0; i < min(5, _data!.length); i++) {
            debugPrint('Row $i: ${_data![i]}');
          }
        }

        debugPrint('Data rows: ${_data!.length}');

        if (_data!.isEmpty) {
          throw Exception("CSV File has no data rows");
        }

        // Find appropriate columns for category and value
        _selectedCategoryColumn = _headers!.isNotEmpty ? _headers!.first : null;
        _selectedValueColumn = _findNumericColumn();

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading CSV file: $error');
      setState(() {
        _isLoading = false;
        _data = null;
        _headers = null;
      });
    }
  }

  String? _findNumericColumn() {
    if (_headers == null || _headers!.isEmpty || _data == null || _data!.isEmpty) {
      return null;
    }

    for (var header in _headers!) {
      final headerIndex = _headers!.indexOf(header);
      for (var row in _data!) {
        if (row.length > headerIndex) {
          final value = row[headerIndex];
          if (value is num || (value != null && double.tryParse(value.toString()) != null)) {
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

    if (_data == null || _headers == null || _data!.isEmpty || _headers!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load CSV data'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadCsvData, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnSelectors(),
        const SizedBox(height: 16),
        Expanded(child: _buildPieChart()),
      ],
    );
  }

  Widget _buildColumnSelectors() {
    // Add null checks for selected columns
    final categoryColumn = _selectedCategoryColumn ?? _headers!.first;
    final valueColumn = _selectedValueColumn ?? _headers!.first;

    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            'Category Column:',
            categoryColumn, // Use the safe value
            _headers!,
            (value) => setState(() => _selectedCategoryColumn = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            'Value Column:',
            valueColumn, // Use the safe value
            _headers!,
            (value) => setState(() => _selectedValueColumn = value),
          ),
        ),
        if (_headers!.length > 2) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              'Filter By (Optional):',
              _selectedFilterColumn ?? 'None',
              ['None', ..._headers!],
              (value) {
                setState(() {
                  _selectedFilterColumn = value == 'None' ? null : value;
                  _selectedFilterValue = null;
                });
              },
            ),
          ),
        ],
        if (_selectedFilterColumn != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              'Filter Value:',
              _selectedFilterValue ?? 'Any',
              ['Any', ...getUniqueValues(_selectedFilterColumn!)],
              (value) => setState(() => _selectedFilterValue = value == 'Any' ? null : value),
            ),
          ),
        ],
      ],
    );
  }

  List<String> getUniqueValues(String column) {
    final index = _headers!.indexOf(column);
    final values = _data!.map((row) => row[index].toString()).toSet().toList();
    return values;
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
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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

  Widget _buildPieChart() {
    if (_data == null || _headers == null || _data!.isEmpty || _headers!.isEmpty) {
      return const Center(child: Text('No data available for chart generation'));
    }

    if (_selectedCategoryColumn == null || _selectedValueColumn == null) {
      return const Center(child: Text('Please select category and value columns'));
    }

    final categoryIndex = _headers!.indexOf(_selectedCategoryColumn!);
    final valueIndex = _headers!.indexOf(_selectedValueColumn!);

    if (categoryIndex < 0 || valueIndex < 0) {
      return Center(
        child: Text('Invalid columns selected: $_selectedCategoryColumn, $_selectedValueColumn'),
      );
    }

    var filteredData = _data!;
    if (_selectedFilterColumn != null && _selectedFilterValue != null) {
      final filterIndex = _headers!.indexOf(_selectedFilterColumn!);
      if (filterIndex >= 0) {
        filteredData =
            _data!
                .where(
                  (row) =>
                      row.length > filterIndex &&
                      row[filterIndex].toString() == _selectedFilterValue,
                )
                .toList();
      }
    }

    if (filteredData.isEmpty) {
      return const Center(child: Text('No data available for the selected filters'));
    }

    final Map<String, double> categoryValues = {};
    for (var row in filteredData) {
      if (row.length <= categoryIndex || row.length <= valueIndex) {
        continue; // this line is skipping invalid rows
      }

      final category = row[categoryIndex]?.toString() ?? 'Unknown';
      final rawValue = row[valueIndex];
      double value = 0.0;

      if (rawValue is num) {
        value = rawValue.toDouble();
      } else if (rawValue != null) {
        value = double.tryParse(rawValue.toString()) ?? 0.0;
      }

      categoryValues[category] = (categoryValues[category] ?? 0) + value;
    }
    _sectionData = categoryValues;
    _totalValue = categoryValues.values.fold(0, (sum, value) => sum + value);

    if (categoryValues.isEmpty) {
      return const Center(child: Text('No valid data to display in chart'));
    }

    try {
      final sections = <PieChartSectionData>[];
      final colors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.cyan,
        Colors.amber,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
        Colors.lightBlue,
        Colors.lime,
      ];

      final showTitles = widget.chartOptions['showTitles'] ?? true;
      final sectionRadius = widget.chartOptions['sectionRadius'] ?? 100.0;
      final titleSize = widget.chartOptions['titleSize'] ?? 15.0;
      final titleColor = widget.chartOptions['titleColor'] ?? Colors.white;
      final titlePositionOffset = widget.chartOptions['titlePositionOffset'] ?? 0.6;
      final defaultSectionColor = widget.chartOptions['defaultSectionColor'] ?? Colors.blue;
      final showSectionBorder = widget.chartOptions['showSectionBorder'] ?? false;
      final sectionBorderColor = widget.chartOptions['sectionBorderColor'] ?? Colors.white;
      final sectionBorderWidth = widget.chartOptions['sectionBorderWidth'] ?? 1.0;
      final useGradient = widget.chartOptions['useGradient'] ?? false;
      final centerSpaceRadius = widget.chartOptions['centerSpaceRadius'] ?? 40;
      final centerSpaceColor = widget.chartOptions['centerSpaceColor'] ?? Colors.transparent;
      final sectionsSpace = widget.chartOptions['sectionsSpace'] ?? 2.0;
      final startDegreeOffset = widget.chartOptions['startDegreeOffset'] ?? 0.0;
      final enableTouch = widget.chartOptions['enableTouch'] ?? true;

      // anim settings
      final animationDuration = Duration(
        milliseconds: (widget.chartOptions['animationDuration'] ?? 500).toInt(),
      );
      final animationCurve = _getAnimationCurve(widget.chartOptions['animationCurve'] ?? 0);

      // tooltip settings
      final showTooltip = widget.chartOptions['showTooltip'] ?? true;

      _sections = [];
      int colorIndex = 0;
      categoryValues.forEach((category, value) {
        final color = useGradient
            ? colors[colorIndex % colors.length]
            : (widget.chartOptions['sectionColor'] != null && colorIndex == 0)
            ? widget.chartOptions['sectionColor']
            : colors[colorIndex % colors.length];
        final section = PieChartSectionData(
          color: color,
          value: value,
          title: showTitles ? '$category\n${value.toStringAsFixed(1)}' : '',
          radius: sectionRadius,
          titleStyle: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
          titlePositionPercentageOffset: titlePositionOffset,
          borderSide: showSectionBorder
              ? BorderSide(
            color: sectionBorderColor,
            width: sectionBorderWidth,
          )
              : BorderSide.none,
        );

        _sections.add(section);
        colorIndex++;
      });

      // final animationDuration = Duration(milliseconds: )

      return PieChart(
        PieChartData(
          sections: _sections,
          centerSpaceRadius: centerSpaceRadius,
          centerSpaceColor: centerSpaceColor,
          sectionsSpace: sectionsSpace,
          startDegreeOffset: startDegreeOffset,
          pieTouchData: PieTouchData(
            enabled: enableTouch,
            touchCallback: showTooltip ? _handlePieTouch : null,
          ),
        ),
        duration: animationDuration,
        curve: animationCurve,
      );
    } catch (e) {
      debugPrint('Error building pie chart: $e');
      return Center(child: Text('Error building chart: ${e.toString()}'));
    }
  }

  Curve _getAnimationCurve(int curveOption) {
    switch (curveOption) {
      case 1:
        return Curves.easeInOut;
      case 2:
        return Curves.bounceIn;
      default:
        return Curves.linear;
    }
  }

  void _handlePieTouch(FlTouchEvent event, PieTouchResponse? response) {
    if (response == null || response.touchedSection == null) {
      return;
    }

    // this would avoid triggering at every moment and only responds to touch downs
    if (!(event is FlTapDownEvent || event is FlPanDownEvent)) {
      return;
    }

    final touchedIndex = response.touchedSection!.touchedSectionIndex;
    if (touchedIndex < 0) {
      return;
    }

    setState(() {
      for (int i = 0; i < _sections.length; i++) {
        _sections[i] = _sections[i].copyWith(
          radius: widget.chartOptions['sectionRadius'] ?? 100.0,
          titlePositionPercentageOffset: widget.chartOptions['titlePositionOffset'] ?? 0.6,
        );
      }

      if (touchedIndex >= 0 && touchedIndex < _sections.length) {
        _sections[touchedIndex] = _sections[touchedIndex].copyWith(
          radius: (widget.chartOptions['sectionRadius'] ?? 100.0) * 1.1,
          titlePositionPercentageOffset: (widget.chartOptions['titlePositionOffset'] ?? 0.6) * 0.9,
        );

        _showTooltip(context, touchedIndex);
      }
    });
  }

  void _showTooltip(BuildContext context, int sectionIndex) {
    if (sectionIndex < 0 || _sectionData == null || sectionIndex >= _sectionData!.length) {
      return;
    }

    final entries = _sectionData!.entries.toList();
    if (sectionIndex >= entries.length) {
      return;
    }

    final entry = entries[sectionIndex];
    final category = entry.key;
    final value = entry.value;
    final percentage = value / _totalValue * 100;

    final tooltipBgColor = widget.chartOptions['tooltipBgColor'] ?? Colors.white;
    final tooltipRadius = widget.chartOptions['tooltipRadius'] ?? 8.0;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);

    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + 100,
        left: position.dx + 100,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(tooltipRadius),
          color: tooltipBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Value: ${value.toStringAsFixed(2)}'),
                Text('Percentage: ${percentage.toStringAsFixed(1)}%')
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry?.remove();
    });
  }
}
