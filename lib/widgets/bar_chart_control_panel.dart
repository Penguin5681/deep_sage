import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BarChartControlPanel extends StatefulWidget {
  final Map<String, dynamic> currentOptions;
  final Function(Map<String, dynamic>) onOptionsChanged;

  const BarChartControlPanel({
    super.key,
    required this.currentOptions,
    required this.onOptionsChanged,
  });

  @override
  State<BarChartControlPanel> createState() => _BarChartControlPanelState();
}

class _BarChartControlPanelState extends State<BarChartControlPanel> {
  late Map<String, dynamic> options;

  @override
  void initState() {
    super.initState();
    options = Map<String, dynamic>.from(widget.currentOptions);
  }

  @override
  void didUpdateWidget(covariant BarChartControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentOptions != widget.currentOptions) {
      setState(() {
        options = Map<String, dynamic>.from(widget.currentOptions);
      });
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
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bar Chart Controls',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlSection('Bar Style', [
                    _buildColorPickerControl(
                      'Bar Color',
                      'barColor',
                      options['barColor'] ?? Colors.blue,
                    ),
                    _buildSliderControl(
                      'Bar Width',
                      'barWidth',
                      (options['barWidth'] ?? 16.0).toDouble(),
                      4.0,
                      30.0,
                    ),
                    _buildSliderControl(
                      'Corner Radius',
                      'borderRadius',
                      (options['borderRadius'] ?? 4.0).toDouble(),
                      0.0,
                      12.0,
                    ),
                    _buildSwitchControl(
                      'Show Border',
                      'showBorder',
                      options['showBorder'] ?? false,
                    ),
                    if (options['showBorder'] == true) ...[
                      _buildColorPickerControl(
                        'Border Color',
                        'borderColor',
                        options['borderColor'] ?? Colors.black,
                      ),
                      _buildSliderControl(
                        'Border Width',
                        'borderWidth',
                        (options['borderWidth'] ?? 1.0).toDouble(),
                        0.5,
                        3.0,
                      ),
                    ],
                  ]),
                  _buildControlSection('Group Settings', [
                    _buildSliderControl(
                      'Groups Spacing',
                      'groupsSpace',
                      (options['groupsSpace'] ?? 16.0).toDouble(),
                      4.0,
                      40.0,
                    ),
                    _buildSliderControl(
                      'Bars Spacing',
                      'barsSpace',
                      (options['barsSpace'] ?? 4.0).toDouble(),
                      0.0,
                      16.0,
                    ),
                    _buildDropdownControl(
                      'Bar Alignment',
                      'alignment',
                      (options['alignment'] ?? 0),
                      [
                        {'value': 0, 'label': 'Start'},
                        {'value': 1, 'label': 'End'},
                        {'value': 2, 'label': 'Center'},
                      ],
                    ),
                  ]),
                  _buildControlSection('Axes', [
                    _buildMinMaxControl('Min Y', 'minY', options['minY']),
                    _buildMinMaxControl('Max Y', 'maxY', options['maxY']),
                    _buildMinMaxControl('Baseline Y', 'baselineY', options['baselineY']),
                  ]),
                  _buildControlSection('Visual', [
                    _buildColorPickerControl(
                      'Background Color',
                      'backgroundColor',
                      options['backgroundColor'] ?? Colors.transparent,
                    ),
                    _buildSwitchControl(
                      'Show Grid Lines',
                      'showGrid',
                      options['showGrid'] ?? true,
                    ),
                    _buildSwitchControl(
                      'Show Chart Border',
                      'showBorderData',
                      options['showBorderData'] ?? false,
                    ),
                  ]),
                  _buildControlSection('Interaction', [
                    _buildSwitchControl(
                      'Enable Touch',
                      'enableTouch',
                      options['enableTouch'] ?? true,
                    ),
                    if (options['enableTouch'] == true) ...[
                      _buildSwitchControl(
                        'Show Tooltips',
                        'showTooltip',
                        options['showTooltip'] ?? true,
                      ),
                      _buildSwitchControl(
                        'Allow Background Bar Touch',
                        'allowBackgroundBarTouch',
                        options['allowBackgroundBarTouch'] ?? true,
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection(String title, List<Widget> controls) {
    final theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        ...controls,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSliderControl(
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
          onChanged: (newValue) => _updateOption(optionKey, newValue),
          max: max,
          min: min,
          divisions: ((max - min) * 10).toInt(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSwitchControl(String label, String optionKey, bool value) {
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

  Widget _buildColorPickerControl(
    String label,
    String optionKey,
    Color value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          GestureDetector(
            onTap: () async {
              Color? picked = await showDialog<Color>(
                context: context,
                builder: (context) => _ColorPickerDialog(initialColor: value),
              );
              if (picked != null) {
                _updateOption(optionKey, picked);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownControl(
    String label,
    String optionKey,
    int value,
    List<Map<String, dynamic>> options,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          DropdownButton<int>(
            value: value,
            items: options
                .map((option) => DropdownMenuItem<int>(
                      value: option['value'] as int,
                      child: Text(option['label'] as String),
                    ))
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _updateOption(optionKey, newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMinMaxControl(String label, String optionKey, dynamic value) {
    final controller = TextEditingController(
      text: value != null ? value.toString() : '',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'auto',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                double? parsed = double.tryParse(val);
                _updateOption(optionKey, val.isEmpty ? null : parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color color;

  @override
  void initState() {
    super.initState();
    color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: color,
          onColorChanged: (c) => setState(() => color = c),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('Select'),
        ),
      ],
    );
  }
}