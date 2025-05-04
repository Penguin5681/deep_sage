import 'package:flutter/material.dart';

class PieChartMatplotlibOptionsOverlay extends StatefulWidget {
  final Map<String, dynamic>? initialOptions;
  final Function(Map<String, dynamic> options) onOptionsChanged;

  const PieChartMatplotlibOptionsOverlay({
    super.key,
    this.initialOptions,
    required this.onOptionsChanged,
  });

  @override
  State<PieChartMatplotlibOptionsOverlay> createState() => _PieChartMatplotlibOptionsOverlayState();
}

class _PieChartMatplotlibOptionsOverlayState extends State<PieChartMatplotlibOptionsOverlay> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;

  // Column selection
  String? _selectedCategoryColumn;
  String? _selectedValueColumn;

  // Filter settings
  bool _enableFiltering = false;
  String _filterType = 'topN';
  int _topNValue = 5;
  double _minValue = 0;
  double _maxValue = 100;

  // Appearance settings
  String _colorPalette = 'Default';
  bool _enableExplode = false;
  double _startAngle = 0;
  bool _enableShadow = false;
  bool _isDonutChart = false;
  double _donutHoleSize = 0.5;

  // Labels and legends
  bool _showLabels = true;
  bool _showPercentages = true;
  bool _showValues = false;
  double _labelFontSize = 12;
  String _labelPosition = 'auto';
  String _legendPosition = 'right';

  // Sorting
  String _sortingOption = 'descending';

  // Output options
  String _outputFormat = 'PNG';
  double _outputDpi = 300;
  bool _transparentBackground = false;

  // Mock data for dropdowns
  final List<String> _mockColumns = ['name', 'category', 'revenue', 'sales', 'profit', 'region'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Pie Chart');
    _subtitleController = TextEditingController(text: '');

    // Set default columns
    _selectedCategoryColumn = _mockColumns.isNotEmpty ? _mockColumns.first : null;
    _selectedValueColumn = _mockColumns.length > 1 ? _mockColumns[1] : _selectedCategoryColumn;

    // Initialize with provided options if available
    if (widget.initialOptions != null) {
      _loadInitialOptions();
    }
  }

  void _loadInitialOptions() {
    final options = widget.initialOptions!;

    _titleController.text = options['title'] ?? 'Pie Chart';
    _subtitleController.text = options['subtitle'] ?? '';
    _selectedCategoryColumn = options['categoryColumn'] ?? _selectedCategoryColumn;
    _selectedValueColumn = options['valueColumn'] ?? _selectedValueColumn;

    _enableFiltering = options['enableFiltering'] ?? false;
    _filterType = options['filterType'] ?? 'topN';
    _topNValue = options['topNValue'] ?? 5;
    _minValue = options['minValue']?.toDouble() ?? 0;
    _maxValue = options['maxValue']?.toDouble() ?? 100;

    _colorPalette = options['colorPalette'] ?? 'Default';
    _enableExplode = options['enableExplode'] ?? false;
    _startAngle = options['startAngle']?.toDouble() ?? 0;
    _enableShadow = options['enableShadow'] ?? false;
    _isDonutChart = options['isDonutChart'] ?? false;
    _donutHoleSize = options['donutHoleSize']?.toDouble() ?? 0.5;

    _showLabels = options['showLabels'] ?? true;
    _showPercentages = options['showPercentages'] ?? true;
    _showValues = options['showValues'] ?? false;
    _labelFontSize = options['labelFontSize']?.toDouble() ?? 12;
    _labelPosition = options['labelPosition'] ?? 'auto';
    _legendPosition = options['legendPosition'] ?? 'right';

    _sortingOption = options['sortingOption'] ?? 'descending';

    _outputFormat = options['outputFormat'] ?? 'PNG';
    _outputDpi = options['outputDpi']?.toDouble() ?? 300;
    _transparentBackground = options['transparentBackground'] ?? false;
  }

  Map<String, dynamic> _getUpdatedOptions() {
    return {
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'categoryColumn': _selectedCategoryColumn,
      'valueColumn': _selectedValueColumn,

      'enableFiltering': _enableFiltering,
      'filterType': _filterType,
      'topNValue': _topNValue,
      'minValue': _minValue,
      'maxValue': _maxValue,

      'colorPalette': _colorPalette,
      'enableExplode': _enableExplode,
      'startAngle': _startAngle,
      'enableShadow': _enableShadow,
      'isDonutChart': _isDonutChart,
      'donutHoleSize': _donutHoleSize,

      'showLabels': _showLabels,
      'showPercentages': _showPercentages,
      'showValues': _showValues,
      'labelFontSize': _labelFontSize,
      'labelPosition': _labelPosition,
      'legendPosition': _legendPosition,

      'sortingOption': _sortingOption,

      'outputFormat': _outputFormat,
      'outputDpi': _outputDpi,
      'transparentBackground': _transparentBackground,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Matplotlib Pie Chart Options', style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            child: Text('Apply', style: TextStyle(color: theme.colorScheme.primary)),
            onPressed: () {
              debugPrint('${_getUpdatedOptions()}');
              widget.onOptionsChanged(_getUpdatedOptions());
              Navigator.pop(context, _getUpdatedOptions());
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Column Selection
          _buildSectionHeader('Column Selection', Icons.view_column),
          _buildColumnSelection(),
          const SizedBox(height: 20),

          // 2. Data Filtering
          _buildSectionHeader('Data Filtering', Icons.filter_list),
          _buildDataFiltering(),
          const SizedBox(height: 20),

          // 3. Chart Appearance
          _buildSectionHeader('Chart Appearance', Icons.palette),
          _buildChartAppearance(),
          const SizedBox(height: 20),

          // 4. Labels and Legends
          _buildSectionHeader('Labels and Legends', Icons.label),
          _buildLabelsAndLegends(),
          const SizedBox(height: 20),

          // 5. Sorting
          _buildSectionHeader('Sorting', Icons.sort),
          _buildSorting(),
          const SizedBox(height: 20),

          // 6. Chart Title and Description
          _buildSectionHeader('Title and Description', Icons.title),
          _buildTitleAndDescription(),
          const SizedBox(height: 20),

          // 7. Image Output Options
          _buildSectionHeader('Output Options', Icons.image),
          _buildOutputOptions(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: theme.dividerColor),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnSelection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              label: 'Category Column',
              value: _selectedCategoryColumn,
              items: _mockColumns,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryColumn = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Value Column',
              value: _selectedValueColumn,
              items: _mockColumns,
              onChanged: (value) {
                setState(() {
                  _selectedValueColumn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataFiltering() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Data Filtering'),
              value: _enableFiltering,
              onChanged: (value) {
                setState(() {
                  _enableFiltering = value;
                });
              },
            ),
            if (_enableFiltering) ...[
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Filter Type',
                value: _filterType,
                items: const ['topN', 'valueRange', 'specificValues'],
                itemLabels: const ['Top N Items', 'Value Range', 'Specific Values'],
                onChanged: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_filterType == 'topN')
                _buildSlider(
                  label: 'Top N Items',
                  value: _topNValue.toDouble(),
                  min: 2,
                  max: 20,
                  divisions: 18,
                  onChanged: (value) {
                    setState(() {
                      _topNValue = value.toInt();
                    });
                  },
                  valueLabel: _topNValue.toString(),
                ),
              if (_filterType == 'valueRange')
                Column(
                  children: [
                    _buildSlider(
                      label: 'Minimum Value',
                      value: _minValue,
                      min: 0,
                      max: _maxValue,
                      onChanged: (value) {
                        setState(() {
                          _minValue = value;
                        });
                      },
                      valueLabel: _minValue.toStringAsFixed(1),
                    ),
                    _buildSlider(
                      label: 'Maximum Value',
                      value: _maxValue,
                      min: _minValue,
                      max: 1000,
                      onChanged: (value) {
                        setState(() {
                          _maxValue = value;
                        });
                      },
                      valueLabel: _maxValue.toStringAsFixed(1),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartAppearance() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              label: 'Color Palette',
              value: _colorPalette,
              items: const ['Default', 'Pastel', 'Dark', 'Bright', 'Custom'],
              onChanged: (value) {
                setState(() {
                  _colorPalette = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Start Angle',
              value: _startAngle,
              min: 0,
              max: 360,
              divisions: 36,
              onChanged: (value) {
                setState(() {
                  _startAngle = value;
                });
              },
              valueLabel: '${_startAngle.toInt()}°',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Explode Slices'),
              value: _enableExplode,
              onChanged: (value) {
                setState(() {
                  _enableExplode = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Shadow'),
              value: _enableShadow,
              onChanged: (value) {
                setState(() {
                  _enableShadow = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Donut Chart'),
              value: _isDonutChart,
              onChanged: (value) {
                setState(() {
                  _isDonutChart = value;
                });
              },
            ),
            if (_isDonutChart)
              _buildSlider(
                label: 'Donut Hole Size',
                value: _donutHoleSize,
                min: 0.1,
                max: 0.9,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _donutHoleSize = value;
                  });
                },
                valueLabel: _donutHoleSize.toStringAsFixed(1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelsAndLegends() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Labels'),
              value: _showLabels,
              onChanged: (value) {
                setState(() {
                  _showLabels = value;
                });
              },
            ),
            if (_showLabels) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Percentages'),
                value: _showPercentages,
                onChanged: (value) {
                  setState(() {
                    _showPercentages = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Values'),
                value: _showValues,
                onChanged: (value) {
                  setState(() {
                    _showValues = value;
                  });
                },
              ),
              _buildSlider(
                label: 'Label Font Size',
                value: _labelFontSize,
                min: 8,
                max: 20,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    _labelFontSize = value;
                  });
                },
                valueLabel: _labelFontSize.toInt().toString(),
              ),
              _buildDropdown(
                label: 'Label Position',
                value: _labelPosition,
                items: const ['auto', 'inside', 'outside'],
                itemLabels: const ['Auto', 'Inside', 'Outside'],
                onChanged: (value) {
                  setState(() {
                    _labelPosition = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Legend Position',
              value: _legendPosition,
              items: const ['right', 'left', 'top', 'bottom', 'none'],
              itemLabels: const ['Right', 'Left', 'Top', 'Bottom', 'None'],
              onChanged: (value) {
                setState(() {
                  _legendPosition = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSorting() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              label: 'Sort By',
              value: _sortingOption,
              items: const ['descending', 'ascending', 'alphabetical', 'original'],
              itemLabels: const ['Descending Value', 'Ascending Value', 'Alphabetical', 'Original Order'],
              onChanged: (value) {
                setState(() {
                  _sortingOption = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndDescription() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Chart Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputOptions() {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              label: 'Output Format',
              value: _outputFormat,
              items: const ['PNG', 'SVG', 'JPG'],
              onChanged: (value) {
                setState(() {
                  _outputFormat = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Resolution (DPI)',
              value: _outputDpi,
              min: 72,
              max: 600,
              divisions: 22,
              onChanged: (value) {
                setState(() {
                  _outputDpi = value;
                });
              },
              valueLabel: _outputDpi.toInt().toString(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transparent Background'),
              value: _transparentBackground,
              onChanged: (value) {
                setState(() {
                  _transparentBackground = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: List.generate(
                items.length,
                (index) => DropdownMenuItem(
                  value: items[index],
                  child: Text(itemLabels != null ? itemLabels[index] : items[index]),
                ),
              ),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    int? divisions,
    required String valueLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(valueLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }
}