import 'package:flutter/material.dart';

import '../../../widgets/overlay_widgets/bar_chart_option_overlay.dart';
import '../../../widgets/overlay_widgets/line_chart_option_overlay.dart';
import '../../../widgets/overlay_widgets/pie_chart_option_overlay.dart';

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  String _selectedChartLibrary = 'FL Chart'; // Default value

  @override
  Widget build(BuildContext context) {
    // Access the current theme
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Heading
            Text(
              'Create Visualization',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Select a chart type and customize your visualization.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Chart Library Selection Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chart Type heading
                Text(
                  'Chart Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 18,
                  ),
                ),
                // Dropdown for Chart Library
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedChartLibrary,
                      icon: Icon(Icons.arrow_drop_down, color: textColor),
                      dropdownColor: theme.cardColor,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedChartLibrary = newValue!;
                          // You can add logic here to react to the change
                          debugPrint('Selected chart library: $_selectedChartLibrary');
                        });
                      },
                      items: <String>['FL Chart', 'Matplotlib']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ChartTypeCard(
                    icon: Icons.show_chart,
                    iconColor: textColor,
                    title: 'Line Chart',
                    description: 'Track changes over time or compare trends.',
                   onTap: () {
                     showModalBottomSheet(
                       context: context,
                       isScrollControlled: true,
                       backgroundColor: Colors.transparent,
                       builder: (context) => DraggableScrollableSheet(
                         initialChildSize: 0.9,
                         minChildSize: 0.5,
                         maxChildSize: 0.95,
                         builder: (_, controller) => Container(
                           decoration: BoxDecoration(
                             color: theme.scaffoldBackgroundColor,
                             borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                           ),
                           child: LineChartOptionsOverlay(
                             onOptionsChanged: (options) {
                               // Store or use the updated options
                               debugPrint('Chart options updated: $options');
                             },
                           ),
                         ),
                       ),
                     );
                   },
                  ),
                ),
                const SizedBox(width: 16),

                // Bar Chart
                Expanded(
                  child: ChartTypeCard(
                    icon: Icons.bar_chart,
                    iconColor: textColor,
                    title: 'Bar Chart',
                    description: 'Compare values across categories.',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, controller) => Container(
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: BarChartOptionsOverlay(
                              onOptionsChanged: (options) {
                                // Store or use the updated options
                                debugPrint('Bar chart options updated: $options');
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Pie Chart
                Expanded(
                  child: ChartTypeCard(
                    icon: Icons.pie_chart,
                    iconColor: textColor,
                    title: 'Pie Chart',
                    description: 'Show proportions and percentages.',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, controller) => Container(
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: PieChartOptionsOverlay(
                              onOptionsChanged: (options) {
                                debugPrint('Pie chart options updated: $options');
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // const SizedBox(width: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChartTypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const ChartTypeCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;
    final buttonBg = isLight ? Colors.black : Colors.white;
    final buttonFg = isLight ? Colors.white : Colors.black;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subTextColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Button
            ElevatedButton(
              onPressed: () {
                // Handle button press
                onTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}
