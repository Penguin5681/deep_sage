import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PieChartOptionsOverlay extends StatefulWidget {
  final Function(Map<String, dynamic>) onOptionsChanged;
  final Map<String, dynamic> initialOptions;

  const PieChartOptionsOverlay({
    super.key,
    required this.onOptionsChanged,
    this.initialOptions = const {},
  });

  @override
  State<PieChartOptionsOverlay> createState() => _PieChartOptionsOverlayState();
}

class _PieChartOptionsOverlayState extends State<PieChartOptionsOverlay> {
  late Map<String, dynamic> options;

  // Track expanded state of sections
  final Map<String, bool> _expandedSections = {
    'layout': true,
    'sections': false,
    'titles': false,
    'effects': false,
    'interaction': false,
  };

  @override
  void initState() {
    super.initState();
    // Set default options
    options = {
      // Layout
      'centerSpaceRadius': 40.0,
      'centerSpaceColor': Colors.transparent,
      'sectionsSpace': 2.0,
      'startDegreeOffset': 0.0,

      // Sections
      'sectionColor': Colors.blue,
      'showSectionBorder': false,
      'sectionBorderColor': Colors.white,
      'sectionBorderWidth': 1.0,
      'sectionRadius': 100.0,

      // Titles
      'showTitles': true,
      'titleColor': Colors.white,
      'titleSize': 14.0,
      'titlePositionOffset': 0.6,

      // Visual Effects
      'useGradient': false,
      'animationDuration': 500,
      'animationCurve': 0, // 0: linear, 1: easeInOut, 2: bounceIn

      // Interaction
      'enableTouch': true,
      'showTooltip': true,
      'tooltipBgColor': Colors.teal,
      'tooltipRadius': 8.0,
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
                'Pie Chart Options',
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
                  // Layout Section
                  _buildExpandableSection(
                    'Chart Layout',
                    'layout',
                    [
                      _buildSlider('Center Space Radius', 'centerSpaceRadius', options['centerSpaceRadius'], 0.0, 100.0),
                      _buildColorPicker('Center Space Color', 'centerSpaceColor', options['centerSpaceColor']),
                      _buildSlider('Sections Space', 'sectionsSpace', options['sectionsSpace'], 0.0, 10.0),
                      _buildSlider('Start Angle (degrees)', 'startDegreeOffset', options['startDegreeOffset'], 0.0, 360.0),
                    ],
                    theme,
                    textColor,
                  ),

                  // Sections Style
                  _buildExpandableSection(
                    'Sections Style',
                    'sections',
                    [
                      _buildColorPicker('Default Section Color', 'sectionColor', options['sectionColor']),
                      _buildSlider('Section Radius', 'sectionRadius', options['sectionRadius'], 50.0, 150.0),
                      _buildSwitch('Show Section Border', 'showSectionBorder', options['showSectionBorder']),
                      if (options['showSectionBorder']) ...[
                        _buildColorPicker('Border Color', 'sectionBorderColor', options['sectionBorderColor']),
                        _buildSlider('Border Width', 'sectionBorderWidth', options['sectionBorderWidth'], 0.5, 5.0),
                      ],
                    ],
                    theme,
                    textColor,
                  ),

                  // Title Settings
                  _buildExpandableSection(
                    'Title Settings',
                    'titles',
                    [
                      _buildSwitch('Show Titles', 'showTitles', options['showTitles']),
                      if (options['showTitles']) ...[
                        _buildColorPicker('Title Color', 'titleColor', options['titleColor']),
                        _buildSlider('Title Size', 'titleSize', options['titleSize'], 8.0, 24.0),
                        _buildSlider('Title Position', 'titlePositionOffset', options['titlePositionOffset'], 0.1, 1.0),
                      ],
                    ],
                    theme,
                    textColor,
                  ),

                  // Visual Effects
                  _buildExpandableSection(
                    'Visual Effects',
                    'effects',
                    [
                      _buildSwitch('Use Gradient', 'useGradient', options['useGradient']),
                      _buildSlider('Animation Duration (ms)', 'animationDuration', options['animationDuration'].toDouble(), 100, 1500),
                      _buildDropdown(
                        'Animation Curve',
                        'animationCurve',
                        options['animationCurve'],
                        [
                          {'value': 0, 'label': 'Linear'},
                          {'value': 1, 'label': 'Ease In Out'},
                          {'value': 2, 'label': 'Bounce In'},
                        ],
                        theme,
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
                      _buildSwitch('Enable Touch', 'enableTouch', options['enableTouch']),
                      if (options['enableTouch']) ...[
                        _buildSwitch('Show Tooltip', 'showTooltip', options['showTooltip']),
                        if (options['showTooltip']) ...[
                          _buildColorPicker('Tooltip Background', 'tooltipBgColor', options['tooltipBgColor']),
                          _buildSlider('Tooltip Corner Radius', 'tooltipRadius', options['tooltipRadius'], 0.0, 20.0),
                        ],
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
          // In _PieChartOptionsOverlayState class, modify the "Generate Chart" button:
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Pass back the options when Generate Chart is clicked
                  Navigator.of(context).pop(options);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLight ? Colors.blueGrey[700] : Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                _expandedSections[sectionKey] = !(_expandedSections[sectionKey] ?? false);
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, String optionKey, double value, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(1)),
          ],
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
      Colors.amber,
      Colors.teal,
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
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => _showCustomColorPicker(context, optionKey, value),
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

  void _showCustomColorPicker(BuildContext context, String optionKey, Color initialColor) {
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
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
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

  Widget _buildRangeInput(String label, String optionKey, double value, ThemeData theme, Color textColor) {
    final controller = TextEditingController(text: value.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    ThemeData theme
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
                items: options.map((option) {
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