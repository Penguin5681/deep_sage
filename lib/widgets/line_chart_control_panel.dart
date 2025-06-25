import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LineChartControlPanel extends StatefulWidget {
  final Map<String, dynamic> currentOptions;
  final Function(Map<String, dynamic>) onOptionsChanged;

  const LineChartControlPanel({
    super.key,
    required this.currentOptions,
    required this.onOptionsChanged,
  });

  @override
  State<LineChartControlPanel> createState() => _LineChartControlPanelState();
}

class _LineChartControlPanelState extends State<LineChartControlPanel> {
  late Map<String, dynamic> options;

  @override
  void initState() {
    super.initState();
    options = Map<String, dynamic>.from(widget.currentOptions);
  }

  @override
  void didUpdateWidget(covariant LineChartControlPanel oldWidget) {
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
            'Line Chart Controls',
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
                  _buildControlSection('Line', [
                    _buildColorPickerControl(
                      'Line Color',
                      'lineColor',
                      options['lineColor'] ?? Colors.blue,
                    ),
                    _buildSliderControl(
                      'Line Width',
                      'lineWidth',
                      (options['lineWidth'] ?? 3.0).toDouble(),
                      1.0,
                      10.0,
                    ),
                    _buildSwitchControl(
                      'Curved Line',
                      'isCurved',
                      options['isCurved'] ?? true,
                    ),
                  ]),
                  _buildControlSection('Dots', [
                    _buildSwitchControl(
                      'Show Dots',
                      'showDots',
                      options['showDots'] ?? true,
                    ),
                    if (options['showDots'] == true) ...[
                      _buildColorPickerControl(
                        'Dot Color',
                        'dotColor',
                        options['dotColor'] ?? Colors.blue,
                      ),
                      _buildSliderControl(
                        'Dot Size',
                        'dotSize',
                        (options['dotSize'] ?? 5.0).toDouble(),
                        2.0,
                        10.0,
                      ),
                    ],
                  ]),
                  _buildControlSection('Grid & Tooltip', [
                    _buildSwitchControl(
                      'Show Grid Lines',
                      'gridLines',
                      options['gridLines'] ?? true,
                    ),
                    _buildSwitchControl(
                      'Show Tooltip',
                      'showTooltip',
                      options['showTooltip'] ?? true,
                    ),
                  ]),
                  _buildControlSection('Axis Bounds', [
                    _buildMinMaxControl('Min Y', 'minY', options['minY'], options['autoScale'] ?? true),
                    _buildMinMaxControl('Max Y', 'maxY', options['maxY'], options['autoScale'] ?? true),
                    _buildSwitchControl(
                      'Auto Scale',
                      'autoScale',
                      options['autoScale'] ?? true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Auto Scale will add padding to ensure all data points are visible',
                    ),
                  ]),
                  _buildControlSection('Background', [
                    _buildColorPickerControl(
                      'Background Color',
                      'backgroundColor',
                      options['backgroundColor'] ?? Colors.transparent,
                    ),
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
        const SizedBox(height: 8),
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

  Widget _buildColorPickerControl(String label, String optionKey, Color value) {
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

  Widget _buildMinMaxControl(String label, String optionKey, dynamic value, bool autoScale) {
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
              enabled: !autoScale,
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
