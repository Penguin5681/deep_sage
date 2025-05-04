import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LineChartOptionsOverlay extends StatefulWidget {
  final Function(Map<String, dynamic>) onOptionsChanged;
  final Map<String, dynamic> initialOptions;

  const LineChartOptionsOverlay({
    super.key,
    required this.onOptionsChanged,
    this.initialOptions = const {},
  });

  @override
  State<LineChartOptionsOverlay> createState() =>
      _LineChartOptionsOverlayState();
}

class _LineChartOptionsOverlayState extends State<LineChartOptionsOverlay> {
  late Map<String, dynamic> options;

  final Map<String, bool> _expandedSections = {
    'lineStyle': true,
    'dataPoints': false,
    'areaFill': false,
    'axes': false,
    'other': false,
  };

  @override
  void initState() {
    super.initState();
    options = {
      // Line Style
      'lineColor': Colors.blue,
      'lineWidth': 3.0,
      'isCurved': true,
      'curveSmoothness': 0.2,
      'isStepLineChart': false,

      // Data Points
      'showDots': true,
      'dotSize': 5.0,
      'dotColor': Colors.blue,

      // Area Fill
      'showAreaFill': false,
      'fillColor': Colors.blue.withValues(alpha: 0.2),
      'cutOffY': 0.0,

      // Axes
      'minY': 0.0,
      'maxY': 100.0,
      'gridLines': true,

      // Other
      'showTooltip': true,
      'backgroundColor': Colors.transparent,
    };

    // Override with any passed-in initial values
    if (widget.initialOptions.isNotEmpty) {
      options.addAll(widget.initialOptions);
    }
  }

  void _updateOption(String key, dynamic value) {
    setState(() {
      options[key] = value;
      widget.onOptionsChanged(options);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Line Chart Options',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildExpandableSection(
                    'Line Style',
                    'lineStyle',
                    [
                      _buildColorPicker(
                        'Line Color',
                        'lineColor',
                        options['lineColor'],
                      ),
                      _buildSlider(
                        'Line Width',
                        'lineWidth',
                        options['lineWidth'],
                        1.0,
                        10.0,
                      ),
                      _buildSwitch(
                        'Curved Line',
                        'isCurved',
                        options['isCurved'],
                      ),
                      if (options['isCurved'])
                        _buildSlider(
                          'Curve Smoothness',
                          'curveSmoothness',
                          options['curveSmoothness'],
                          0.0,
                          1.0,
                        ),
                      _buildSwitch(
                        'Step Line Chart',
                        'isStepLineChart',
                        options['isStepLineChart'],
                      ),
                    ],
                    theme,
                    textColor,
                  ),

                  _buildExpandableSection(
                    'Data Points',
                    'dataPoints',
                    [
                      _buildSwitch(
                        'Show Data Points',
                        'showDots',
                        options['showDots'],
                      ),
                      if (options['showDots']) ...[
                        _buildSlider(
                          'Dot Size',
                          'dotSize',
                          options['dotSize'],
                          2.0,
                          10.0,
                        ),
                        _buildColorPicker(
                          'Dot Color',
                          'dotColor',
                          options['dotColor'],
                        ),
                      ],
                    ],
                    theme,
                    textColor,
                  ),

                  // Area Fill Section
                  _buildExpandableSection(
                    'Area Fill',
                    'areaFill',
                    [
                      _buildSwitch(
                        'Show Area Fill',
                        'showAreaFill',
                        options['showAreaFill'],
                      ),
                      if (options['showAreaFill']) ...[
                        _buildColorPicker(
                          'Fill Color',
                          'fillColor',
                          options['fillColor'],
                        ),
                        _buildSlider(
                          'Cut-off Y Value',
                          'cutOffY',
                          options['cutOffY'],
                          0.0,
                          100.0,
                        ),
                      ],
                    ],
                    theme,
                    textColor,
                  ),

                  // Axes Section
                  _buildExpandableSection(
                    'Axes Settings',
                    'axes',
                    [
                      _buildRangeInput(
                        'Y-Axis Min',
                        'minY',
                        options['minY'],
                        theme,
                        textColor,
                      ),
                      _buildRangeInput(
                        'Y-Axis Max',
                        'maxY',
                        options['maxY'],
                        theme,
                        textColor,
                      ),
                      _buildSwitch(
                        'Show Grid Lines',
                        'gridLines',
                        options['gridLines'],
                      ),
                    ],
                    theme,
                    textColor,
                  ),

                  // Other Settings
                  _buildExpandableSection(
                    'Other Settings',
                    'other',
                    [
                      _buildSwitch(
                        'Show Tooltips',
                        'showTooltip',
                        options['showTooltip'],
                      ),
                      _buildColorPicker(
                        'Background Color',
                        'backgroundColor',
                        options['backgroundColor'],
                      ),
                    ],
                    theme,
                    textColor,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(options);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLight ? Colors.blueGrey[700] : Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Generate Chart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    String title,
    String sectionKey,
    List<Widget> children,
    ThemeData theme,
    Color textColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      color: theme.cardColor,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _expandedSections[sectionKey] =
                    !(_expandedSections[sectionKey] ?? false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Icon(
                    _expandedSections[sectionKey] ?? false
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
          if (_expandedSections[sectionKey] ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    String optionKey,
    double value,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value.toStringAsFixed(1))],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          onChanged: (newValue) => _updateOption(optionKey, newValue),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSwitch(String label, String optionKey, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: (newValue) => _updateOption(optionKey, newValue),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, String optionKey, Color value) {
    final List<Color> colorOptions = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.indigo,
      Colors.cyan,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final color = colorOptions[index];
                      final isSelected = value.value == color.value;

                      return GestureDetector(
                        onTap: () => _updateOption(optionKey, color),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child:
                              isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Custom color button
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.color_lens, size: 16),
                  label: const Text('Custom'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed:
                      () => _showCustomColorPicker(context, optionKey, value),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: value,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                Text(
                  '#${value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showCustomColorPicker(
    BuildContext context,
    String optionKey,
    Color initialColor,
  ) {
    Color pickerColor = initialColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a custom color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: true,
              displayThumbColor: true,
              portraitOnly: true,
              hexInputBar: true,
              pickerAreaBorderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                _updateOption(optionKey, pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRangeInput(
    String label,
    String optionKey,
    double value,
    ThemeData theme,
    Color textColor,
  ) {
    final controller = TextEditingController(text: value.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (newValue) {
                final parsed = double.tryParse(newValue);
                if (parsed != null) {
                  _updateOption(optionKey, parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
