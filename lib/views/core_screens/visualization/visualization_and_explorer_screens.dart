import 'dart:async';
import 'dart:io';

import 'package:deep_sage/views/core_screens/visualization/tabs/data_cleaning_tab.dart';
import 'package:deep_sage/views/core_screens/visualization/tabs/raw_data_tab.dart';
import 'package:deep_sage/views/core_screens/visualization/tabs/visualize_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import '../../../core/models/hive_models/recent_imports_model.dart';

class VisualizationAndExplorerScreens extends StatefulWidget {
  const VisualizationAndExplorerScreens({super.key});

  @override
  State<VisualizationAndExplorerScreens> createState() => _VisualizationAndExplorerScreensState();
}

class _VisualizationAndExplorerScreensState extends State<VisualizationAndExplorerScreens>
    with TickerProviderStateMixin {
  late TabController tabController;
  late int tabControllerIndex;
  late String? currentDataset = '';
  late String? currentDatasetPath = '';
  late String? currentDatasetType = '';

  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);
  final ValueNotifier<String?> selectedDatasetNotifier = ValueNotifier<String?>(null);
  List<StreamSubscription<FileSystemEvent>> fileWatchers = [];
  Set<String> watchedFiles = {};

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabControllerIndex = 0;

    _loadLastSelectedDataset();

    setupImportWatchers();
    recentImportsBox.listenable().addListener(setupImportWatchers);
    selectedDatasetNotifier.addListener(_handleDatasetSelectionChange);
  }

  void _loadLastSelectedDataset() {
    currentDataset = recentImportsBox.get('currentDatasetName');
    currentDatasetPath = recentImportsBox.get('currentDatasetPath');
    currentDatasetType = recentImportsBox.get('currentDatasetType');

    if (currentDatasetPath != null &&
        File(currentDatasetPath!).existsSync() &&
        currentDataset != null) {
      selectedDatasetNotifier.value = currentDataset;
    } else {
      recentImportsBox.delete('currentDatasetName');
      recentImportsBox.delete('currentDatasetPath');
      recentImportsBox.delete('currentDatasetType');
    }
  }

  void _handleDatasetSelectionChange() {
    if (selectedDatasetNotifier.value != null && selectedDatasetNotifier.value != currentDataset) {
      setState(() {
        currentDataset = selectedDatasetNotifier.value;

        recentImportsBox.put('currentDatasetName', currentDataset);
        recentImportsBox.put('currentDatasetPath', currentDatasetPath);
        recentImportsBox.put('currentDatasetType', currentDatasetType);
      });
    }
  }

  void selectDataset(RecentImportsModel import) {
    currentDataset = import.fileName;
    currentDatasetPath = import.filePath;
    currentDatasetType = import.fileType;

    selectedDatasetNotifier.value = import.fileName;

    recentImportsBox.put('currentDatasetName', currentDataset);
    recentImportsBox.put('currentDatasetPath', currentDatasetPath);
    recentImportsBox.put('currentDatasetType', currentDatasetType);
  }

  void setupImportWatchers() {
    for (var watcher in fileWatchers) {
      watcher.cancel();
    }
    fileWatchers.clear();
    watchedFiles.clear();

    final dynamic recentImportsData = recentImportsBox.get('recentImports');
    if (recentImportsData == null) return;

    List<RecentImportsModel> recentImports = [];
    if (recentImportsData is List) {
      recentImports = recentImportsData.cast<RecentImportsModel>();
    } else if (recentImportsData is RecentImportsModel) {
      recentImports = [recentImportsData];
    }

    for (var import in recentImports) {
      if (import.filePath != null && import.filePath!.isNotEmpty) {
        setupFileWatcher(import.filePath!);
      }
    }
  }

  void setupFileWatcher(String filePath) {
    if (watchedFiles.contains(filePath)) return;

    try {
      final file = File(filePath);
      final directory = file.parent;

      if (directory.existsSync()) {
        final subscription = directory.watch(recursive: false).listen((event) {
          if (event.path == filePath || event.path.contains(file.uri.pathSegments.last)) {
            if (event.type == FileSystemEvent.delete || !File(filePath).existsSync()) {
              debugPrint('File was deleted or moved: $filePath');
              setState(() {});
            }
          }
        });

        fileWatchers.add(subscription);
        watchedFiles.add(filePath);
        debugPrint('Watching file for changes: $filePath');
      }
    } catch (ex) {
      debugPrint('Error setting up file watcher: $ex');
    }
  }

  String returnTextBasedOnIndex() {
    String tabName =
        tabControllerIndex == 0
            ? 'Raw Data'
            : tabControllerIndex == 1
            ? 'Data Cleaning'
            : 'Visualize';

    String datasetName = currentDataset ?? 'No Dataset';

    return '$tabName > $datasetName';
  }

  @override
  void dispose() {
    for (var watcher in fileWatchers) {
      watcher.cancel();
    }
    tabController.dispose();
    recentImportsBox.listenable().removeListener(setupImportWatchers);
    selectedDatasetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
            ),
            child: _buildRecentImportsSidebar(isDarkMode),
          ),

          // these are the 3 tabs that i m showing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 35.0, top: 35.0),
                  child: Text('Explorer > ${returnTextBasedOnIndex()}'),
                ),
                TabBar(
                  padding: const EdgeInsets.only(left: 35.0, right: 35.0),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: isDarkMode ? Colors.white : Colors.black,
                  unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey,
                  indicatorColor: isDarkMode ? Colors.white : Colors.black,
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  controller: tabController,
                  tabs: const [
                    Tab(text: 'Raw Data'),
                    Tab(text: 'Data cleaning'),
                    Tab(text: 'Visualize'),
                  ],
                  onTap: ((index) {
                    setState(() {
                      tabControllerIndex = index;
                    });
                  }),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      RawDataTab(selectedDatasetNotifier: selectedDatasetNotifier),
                      DataCleaningTab(),
                      VisualizeTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentImportsSidebar(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recent Imports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: InkWell(
            onTap: _showClearConfirmationDialog,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color:
                    isDarkMode
                        ? Colors.grey[800]!.withValues(alpha: 0.3)
                        : Colors.grey[200]!.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: recentImportsBox.listenable(),
            builder: (context, box, _) {
              final dynamic recentImportsData = box.get('recentImports');
              List<RecentImportsModel> recentImports = [];

              if (recentImportsData != null) {
                if (recentImportsData is List) {
                  recentImports = recentImportsData.cast<RecentImportsModel>();
                } else if (recentImportsData is RecentImportsModel) {
                  recentImports = [recentImportsData];
                }
              }

              recentImports =
                  recentImports
                      .where(
                        (import) => import.filePath != null && File(import.filePath!).existsSync(),
                      )
                      .toList();

              if (recentImports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No recent imports',
                        style: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                      ),
                      Text(
                        'Import datasets to see them here',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: recentImports.length,
                itemBuilder: (context, index) {
                  if (recentImports[index].filePath != null) {
                    setupFileWatcher(recentImports[index].filePath!);
                  }
                  return _buildImportItem(recentImports[index], isDarkMode);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImportItem(RecentImportsModel import, bool isDarkMode) {
    final fileExists = import.filePath != null && File(import.filePath!).existsSync();

    if (!fileExists) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getFileIcon(import.fileType), color: _getFileColor(import.fileType), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      import.fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatImportTime(import.importTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildInfoTag(import.fileType.toUpperCase(), isDarkMode),
              SizedBox(width: 6),
              _buildInfoTag(import.fileSize, isDarkMode),
              Spacer(),
              ElevatedButton(
                onPressed: () async {
                  // todo:  in next commit i'll prolly make the imports work
                  selectDataset(import);
                  tabController.animateTo(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: Size(60, 30),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text('Use', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String text, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
      ),
    );
  }

  String _formatImportTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      case 'xlsx':
        return Icons.grid_on;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Colors.green;
      case 'json':
        return Colors.orange;
      case 'xlsx':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Recent Imports'),
          content: Text(
            'Are you sure you want to clear all recent imports? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearAllRecentImports();
                Navigator.of(context).pop();
              },
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _clearAllRecentImports() {
    recentImportsBox.delete('recentImports');
    recentImportsBox.delete('currentDatasetName');
    recentImportsBox.delete('currentDatasetPath');
    recentImportsBox.delete('currentDatasetType');

    setState(() {
      currentDataset = null;
      currentDatasetPath = null;
      currentDatasetType = null;
    });

    selectedDatasetNotifier.value = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All recent imports have been cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
