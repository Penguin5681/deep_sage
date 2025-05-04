import 'package:flutter/material.dart';

class PieChartControlPanel extends StatefulWidget {
  final Map<String, dynamic> currentOptions;
  final Function(Map<String, dynamic>) onOptionsChanged;

  const PieChartControlPanel({
    super.key,
    required this.currentOptions,
    required this.onOptionsChanged,
  });

  @override
  State<PieChartControlPanel> createState() => _PieChartControlPanelState();
}

class _PieChartControlPanelState extends State<PieChartControlPanel> {
  late Map<String, dynamic> options;

  @override
  void initState() {
    super.initState();
    options = Map<String, dynamic>.from(widget.currentOptions);
  }

  @override
  void didUpdateWidget(covariant PieChartControlPanel oldWidget) {
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
            'Pie Chart Controls',
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
                  _buildControlSection('Layout', [
                    _buildSliderControl(
                      'Center Space Radius',
                      'centerSpaceRadius',
                      options['centerSpaceRadius'] ?? 40.0,
                      0.0,
                      100.0,
                    ),
                    _buildSliderControl(
                      'Sections Space',
                      'sectionsSpace',
                      options['sectionsSpace'] ?? 2.0,
                      0.0,
                      10.0,
                    ),
                    _buildSliderControl(
                      'Start Angle (degrees)',
                      'startDegreeOffset',
                      options['startDegreeOffset'] ?? 0.0,
                      0.0,
                      360.0,
                    ),
                  ]),
                  _buildControlSection('Sections', [
                    _buildSliderControl(
                      'Section Radius',
                      'sectionRadius',
                      options['sectionRadius'] ?? 100.0,
                      50.0,
                      150.0,
                    ),
                    _buildSwitchControl(
                      'Show Section Border',
                      'showSectionBorder',
                      options['showSectionBorder'] ?? false,
                    ),
                    if (options['showSectionBorder'] == true) ...[
                      _buildSliderControl(
                        'Border Width',
                        'sectionBorderWidth',
                        options['sectionBorderWidth'] ?? 1.0,
                        0.5,
                        5.0,
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
}
