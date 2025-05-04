import 'dart:io';

import 'package:deep_sage/core/services/caching_services/chart_rendering_service.dart';
import 'package:deep_sage/views/core_screens/visualization_and_explorer/pie_chart_visualization/dynamic_pie_chart.dart';
import 'package:deep_sage/widgets/overlay_widgets/matplotlib_option_overlays/pie_chart_matplotlib_option_overlay.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/services/core_services/visualization_service.dart';
import '../../../widgets/overlay_widgets/fl_chart_option_overlays/bar_chart_option_overlay.dart';
import '../../../widgets/overlay_widgets/fl_chart_option_overlays/line_chart_option_overlay.dart';
import '../../../widgets/overlay_widgets/fl_chart_option_overlays/pie_chart_option_overlay.dart';
import '../../../widgets/pie_chart_control_panel.dart';

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedChartLibrary = 'FL Chart';
  late String? currentDatasetPath = '';
  late String? currentDatasetType = '';
  late String? currentDatasetName = '';
  bool _isDatasetSelected = false;

  Widget? _currentChart;
  Map<String, dynamic>? _currentChartOptions;
  String? _currentChartType;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final VisualizationService _visualizationService = VisualizationService();
  String? _generatedChartImagePath;
  bool _isGeneratingChart = false;

  Map<String, dynamic>? _pieChartOptions;

  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  final ChartRenderingService _chartRenderingService = ChartRenderingService();

  void loadDatasetMetadata() {
    currentDatasetPath = recentImportsBox.get('currentDatasetPath');
    currentDatasetType = recentImportsBox.get('currentDatasetType');
    currentDatasetName = recentImportsBox.get('currentDatasetName');

    _isDatasetSelected =
        currentDatasetPath != null &&
        currentDatasetPath!.isNotEmpty &&
        currentDatasetName != null &&
        currentDatasetName!.isNotEmpty;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadDatasetMetadata();

    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreChartState());

    if (_isDatasetSelected) {
      _chartRenderingService.startRenderingService(currentDatasetPath!);
    }
  }

  @override
  void dispose() {
    _chartRenderingService.stopRenderingService();
    super.dispose();
  }

  void _showPieChart(Map<String, dynamic> options) {
    bool isNewChartRequest =
        _currentChartType != 'pie' || _currentChart == null;

    if ((currentDatasetPath == null || currentDatasetPath!.isEmpty) &&
        isNewChartRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please import a dataset first')),
      );
      return;
    }

    final preRenderedChart = _chartRenderingService.getPreRenderedChart(
      options,
    );

    if (preRenderedChart != null) {
      setState(() {
        _currentChart = preRenderedChart;
        _currentChartOptions = options;
        _currentChartType = 'pie';
      });
      _saveChartState();
      return;
    }

    setState(() {
      _isGeneratingChart = true;
      _currentChart = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating chart...'),
          ],
        ),
      );
    });

    final file = File(currentDatasetPath!);
    file.exists().then((exists) {
      if (!exists) {
        setState(() {
          _isGeneratingChart = false;
          _currentChart = const Center(
            child: Text('Dataset file not found. Please import a new dataset.'),
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dataset file not found')));
        return;
      }

      if (_selectedChartLibrary == 'Matplotlib') {
        _visualizationService
            .generatePieChart(file, options)
            .then((imagePath) {
              setState(() {
                _generatedChartImagePath = imagePath;
                _currentChart = Image.network(
                  imagePath,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 50),
                          const SizedBox(height: 16),
                          Text('Error loading chart: $error'),
                        ],
                      ),
                    );
                  },
                );
                _currentChartOptions = options;
                _currentChartType = 'pie';
                _isGeneratingChart = false;
              });

              _saveChartState();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chart generated successfully')),
              );
            })
            .catchError((error) {
              setState(() {
                _isGeneratingChart = false;
                _currentChart = Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Failed to generate chart: ${error.toString()}'),
                    ],
                  ),
                );
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${error.toString()}')),
              );
            });
      } else {
        setState(() {
          _currentChart = DynamicPieChart(
            filePath: currentDatasetPath!,
            chartOptions: options,
            key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          );
          _currentChartOptions = options;
          _currentChartType = 'pie';
          _isGeneratingChart = false;
        });

        _saveChartState();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chart generated successfully')),
        );
      }
    });
  }

  void _saveChartState() {
    if (_currentChartType != null && _currentChartOptions != null) {
      final serializableOptions = Map<String, dynamic>.from(
        _currentChartOptions!,
      );

      serializableOptions.forEach((key, value) {
        if (value is Color) {
          serializableOptions[key] = value.value;
        }
      });

      final chartStateBox = Hive.box(dotenv.env['CHART_STATE_BOX']!);
      chartStateBox.put('chartType', _currentChartType);
      chartStateBox.put('chartOptions', serializableOptions);
      chartStateBox.put('datasetPath', currentDatasetPath);
    }
  }

  void _restoreChartState() {
    final chartStateBox = Hive.box(dotenv.env['CHART_STATE_BOX']!);
    final savedChartType = chartStateBox.get('chartType');
    final savedOptions = chartStateBox.get('chartOptions');
    final savedDatasetPath = chartStateBox.get('datasetPath');

    if (savedChartType == 'pie' &&
        savedOptions != null &&
        savedDatasetPath != null &&
        savedDatasetPath == currentDatasetPath) {
      final restoredOptions = Map<String, dynamic>.from(savedOptions);

      final colorKeys = [
        'centerSpaceColor',
        'sectionColor',
        'sectionBorderColor',
        'titleColor',
        'tooltipBgColor',
      ];

      for (var key in colorKeys) {
        if (restoredOptions.containsKey(key) && restoredOptions[key] is int) {
          restoredOptions[key] = Color(restoredOptions[key]);
        }
      }

      setState(() {
        _currentChart = DynamicPieChart(
          filePath: currentDatasetPath!,
          chartOptions: restoredOptions,
        );
        _currentChartOptions = restoredOptions;
        _currentChartType = savedChartType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                    color:
                        theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.dividerColor, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedChartLibrary,
                      icon: Icon(Icons.arrow_drop_down, color: textColor),
                      dropdownColor: theme.cardColor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedChartLibrary = newValue!;
                          // You can add logic here to react to the change
                          debugPrint(
                            'Selected chart library: $_selectedChartLibrary',
                          );
                        });
                      },
                      items:
                          <String>[
                            'FL Chart',
                            'Matplotlib',
                          ].map<DropdownMenuItem<String>>((String value) {
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
                        builder:
                            (context) => DraggableScrollableSheet(
                              initialChildSize: 0.9,
                              minChildSize: 0.5,
                              maxChildSize: 0.95,
                              builder:
                                  (_, controller) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: LineChartOptionsOverlay(
                                      onOptionsChanged: (options) {
                                        // Store or use the updated options
                                        debugPrint(
                                          'Chart options updated: $options',
                                        );
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
                        builder:
                            (context) => DraggableScrollableSheet(
                              initialChildSize: 0.9,
                              minChildSize: 0.5,
                              maxChildSize: 0.95,
                              builder:
                                  (_, controller) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: BarChartOptionsOverlay(
                                      onOptionsChanged: (options) {
                                        // Store or use the updated options
                                        debugPrint(
                                          'Bar chart options updated: $options',
                                        );
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
                        builder:
                            (context) => DraggableScrollableSheet(
                              initialChildSize: 0.9,
                              minChildSize: 0.5,
                              maxChildSize: 0.95,
                              builder:
                                  (_, controller) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child:
                                        _selectedChartLibrary == "FL Chart"
                                            ? PieChartOptionsOverlay(
                                              initialOptions:
                                                  _pieChartOptions ?? {},
                                              onOptionsChanged: (options) {
                                                setState(() {
                                                  _pieChartOptions = options;
                                                });
                                              },
                                            )
                                            : PieChartMatplotlibOptionsOverlay(
                                              initialOptions:
                                                  _currentChartOptions,
                                              onOptionsChanged: (options) {
                                                setState(() {
                                                  _currentChartOptions =
                                                      options;
                                                });
                                              },
                                            ),
                                  ),
                            ),
                      ).then((result) {
                        if (result != null && result is Map<String, dynamic>) {
                          _showPieChart(result);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),

            const SizedBox(height: 8),

            if (_currentChart != null)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart display (left side)
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _currentChart!,
                        ),
                      ),
                    ),
                    // Chart controls (right side)
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            _currentChartType == 'pie' &&
                                    _currentChartOptions != null
                                ? PieChartControlPanel(
                                  currentOptions: _currentChartOptions!,
                                  onOptionsChanged: (updatedOptions) {
                                    setState(() {
                                      _currentChartOptions = updatedOptions;
                                    });
                                    _showPieChart(updatedOptions);
                                  },
                                )
                                : const Center(
                                  child: Text(
                                    'Select a chart type to see controls',
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
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
