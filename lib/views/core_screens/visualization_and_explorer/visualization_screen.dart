import 'package:flutter/material.dart';

class VisualizationScreen extends StatelessWidget {
  const VisualizationScreen({super.key});

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

            // Chart Type heading
            Text(
              'Chart Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            // Chart Type cards in a row
            Row(
              children: [
                // Line Chart
                Expanded(
                  child: ChartTypeCard(
                    icon: Icons.show_chart,
                    iconColor: textColor,
                    title: 'Line Chart',
                    description: 'Track changes over time or compare trends.',
                    onTap: () {
                      // Handle Line Chart selection
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
                      // Handle Bar Chart selection
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
                      // Handle Pie Chart selection
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Scatter Chart
                Expanded(
                  child: ChartTypeCard(
                    icon: Icons.scatter_plot,
                    iconColor: textColor,
                    title: 'Scatter Chart',
                    description: 'Vizualize relationships between variables.',
                    onTap: () {
                      // Handle Scatter Chart selection
                    },
                  ),
                ),
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
              onPressed: () {},
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
