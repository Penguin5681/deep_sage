import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BarChartOptionsOverlay extends StatefulWidget {
  final Function(Map<String, dynamic>) onOptionsChanged;
  final Map<String, dynamic> initialOptions;

  const BarChartOptionsOverlay({
    super.key,
    required this.onOptionsChanged,
    this.initialOptions = const {},
  });

  @override
  State<BarChartOptionsOverlay> createState() => _BarChartOptionsOverlayState();
}

class _BarChartOptionsOverlayState extends State<BarChartOptionsOverlay> {
  late Map<String, dynamic> options;

  final Map<String, bool> _expandedSections = {
    'barStyle': true,
    'groupSettings': false,
    'axes': false,
    'visual': false,
    'interaction': false,
  };

  @override
  void initState() {
    super.initState();
    options = {
      // Bar Style
      'barColor': Colors.blue,
      'barGradient': false,
      'barWidth': 16.0,
      'borderRadius': 4.0,
      'showBorder': false,
      'borderColor': Colors.black,
      'borderWidth': 1.0,

      // Group Settings
      'groupsSpace': 16.0,
      'barsSpace': 4.0,
      'alignment': 0, // 0: start, 1: center, 2: end
      // Axes Settings
      'minY': 0.0,
      'maxY': 100.0,
      'baselineY': 0.0,

      // Visual Elements
      'backgroundColor': Colors.transparent,
      'showGrid': true,
      'showBorderData': false,

      // Interaction
      'enableTouch': true,
      'showTooltip': true,
      'allowBackgroundBarTouch': true,
    };

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
    final _ = isLight ? Colors.black54 : Colors.white70;

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
                'Bar Chart Options',
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

          // Options in a scrollable container
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Bar Style Section
                  _buildExpandableSection(
                    'Bar Style',
                    'barStyle',
                    [
                      _buildColorPicker(
                        'Bar Color',
                        'barColor',
                        options['barColor'],
                      ),
                      _buildSwitch(
                        'Use Gradient',
                        'barGradient',
                        options['barGradient'],
                      ),
                      _buildSlider(
                        'Bar Width',
                        'barWidth',
                        options['barWidth'],
                        4.0,
                        30.0,
                      ),
                      _buildSlider(
                        'Corner Radius',
                        'borderRadius',
                        options['borderRadius'],
                        0.0,
                        12.0,
                      ),
                      _buildSwitch(
                        'Show Border',
                        'showBorder',
                        options['showBorder'],
                      ),
                      if (options['showBorder']) ...[
                        _buildColorPicker(
                          'Border Color',
                          'borderColor',
                          options['borderColor'],
                        ),
                        _buildSlider(
                          'Border Width',
                          'borderWidth',
                          options['borderWidth'],
                          0.5,
                          3.0,
                        ),
                      ],
                    ],
                    theme,
                    textColor,
                  ),

                  // Group Settings Section
                  _buildExpandableSection(
                    'Group Settings',
                    'groupSettings',
                    [
                      _buildSlider(
                        'Groups Spacing',
                        'groupsSpace',
                        options['groupsSpace'],
                        4.0,
                        40.0,
                      ),
                      _buildSlider(
                        'Bars Spacing',
                        'barsSpace',
                        options['barsSpace'],
                        0.0,
                        16.0,
                      ),
                      _buildDropdown(
                        'Bar Alignment',
                        'alignment',
                        options['alignment'],
                        [
                          {'value': 0, 'label': 'Start'},
                          {'value': 1, 'label': 'Center'},
                          {'value': 2, 'label': 'End'},
                        ],
                        theme,
                      ),
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
                      _buildRangeInput(
                        'Baseline Y',
                        'baselineY',
                        options['baselineY'],
                        theme,
                        textColor,
                      ),
                    ],
                    theme,
                    textColor,
                  ),

                  // Visual Elements
                  _buildExpandableSection(
                    'Visual Elements',
                    'visual',
                    [
                      _buildColorPicker(
                        'Background Color',
                        'backgroundColor',
                        options['backgroundColor'],
                      ),
                      _buildSwitch(
                        'Show Grid Lines',
                        'showGrid',
                        options['showGrid'],
                      ),
                      _buildSwitch(
                        'Show Chart Border',
                        'showBorderData',
                        options['showBorderData'],
                      ),
                    ],
                    theme,
                    textColor,
                  ),

                  // Interaction
                  _buildExpandableSection(
                    'Interaction',
                    'interaction',
                    [
                      _buildSwitch(
                        'Enable Touch',
                        'enableTouch',
                        options['enableTouch'],
                      ),
                      if (options['enableTouch']) ...[
                        _buildSwitch(
                          'Show Tooltips',
                          'showTooltip',
                          options['showTooltip'],
                        ),
                        _buildSwitch(
                          'Allow Background Bar Touch',
                          'allowBackgroundBarTouch',
                          options['allowBackgroundBarTouch'],
                        ),
                      ],
                    ],
                    theme,
                    textColor,
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
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

  Widget _buildDropdown(
    String label,
    String optionKey,
    int value,
    List<Map<String, dynamic>> options,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                items:
                    options.map((option) {
                      return DropdownMenuItem<int>(
                        value: option['value'] as int,
                        child: Text(option['label'] as String),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    _updateOption(optionKey, newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
