import 'dart:async';
import 'dart:io';

import 'package:deep_sage/core/models/dataset_file.dart';
import 'package:deep_sage/core/services/directory_path_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:path/path.dart' as path;

import '../../../core/models/hive_models/recent_imports_model.dart';

class FolderRecent extends StatefulWidget {
  final Function(int)? onNavigate;

  const FolderRecent({super.key, required this.onNavigate});

  @override
  State<FolderRecent> createState() => _FolderRecentState();
}

class _FolderRecentState extends State<FolderRecent> {
  // Hive boxes
  final Box starredBox = Hive.box('starred_datasets');
  final Box hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  // Datastore
  late String selectedRootDirectoryPath = '';
  late bool isRootDirectorySelected = false;
  List<DatasetFile> recentDatasetFiles = [];
  bool isLoading = true;

  // Stream subscriptions
  late StreamSubscription<String> pathSubscription;
  StreamSubscription<FileSystemEvent>? directoryWatcher;

  @override
  void initState() {
    super.initState();
    _loadRootDirectoryPath().then((_) {
      if (selectedRootDirectoryPath.isNotEmpty) {
        _fetchRecentFiles(selectedRootDirectoryPath);
        _setupDirectoryWatcher(selectedRootDirectoryPath);
      }
    });

    pathSubscription = DirectoryPathService().pathStream.listen((newPath) {
      if (newPath != selectedRootDirectoryPath) {
        setState(() {
          selectedRootDirectoryPath = newPath;
          isRootDirectorySelected = newPath.isNotEmpty;
        });
        _fetchRecentFiles(newPath);
        _setupDirectoryWatcher(newPath);
      }
    });
  }

  @override
  void dispose() {
    directoryWatcher?.cancel();
    pathSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadRootDirectoryPath() async {
    final savedPath = hiveBox.get('selectedRootDirectoryPath');
    setState(() {
      if (savedPath != null && savedPath.toString().isNotEmpty) {
        selectedRootDirectoryPath = savedPath;
        isRootDirectorySelected = true;
      }
    });
  }

  void _setupDirectoryWatcher(String dirPath) {
    directoryWatcher?.cancel();
    if (dirPath.isEmpty) return;

    try {
      directoryWatcher = Directory(dirPath).watch(recursive: true).listen((event) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _fetchRecentFiles(dirPath);
          }
        });
      });
    } catch (ex) {
      debugPrint('setupDirectoryWatcher(): $ex');
    }
  }

  Future<void> _fetchRecentFiles(String rootPath) async {
    if (rootPath.isEmpty) {
      setState(() {
        recentDatasetFiles = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final List<DatasetFile> allFiles = [];
      await _scanDirectory(rootPath, allFiles);

      // Sort files by modification date, newest first
      allFiles.sort((a, b) => b.modified.compareTo(a.modified));

      // Take only the 7 most recent files
      final recentFiles = allFiles.take(7).toList();

      setState(() {
        recentDatasetFiles = recentFiles;
        isLoading = false;
      });
    } catch (ex) {
      debugPrint('Error fetching recent files: $ex');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _scanDirectory(String directoryPath, List<DatasetFile> files) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return;

    try {
      await for (var entity in dir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.json', '.csv', '.txt'].contains(extension)) {
            final fileStats = await entity.stat();
            final fileSize = await _getFileSize(entity.path, fileStats.size);
            final isStarred = await _loadStarredStatus(entity.path);

            files.add(
              DatasetFile(
                fileName: path.basename(entity.path),
                fileType: extension.replaceFirst('.', ''),
                fileSize: fileSize,
                filePath: entity.path,
                modified: fileStats.modified,
                isStarred: isStarred,
              ),
            );
          }
        } else if (entity is Directory) {
          await _scanDirectory(entity.path, files);
        }
      }
    } catch (ex) {
      debugPrint('Unable to scan directories: $ex');
    }
  }

  Future<String> _getFileSize(String filepath, int bytes) async {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<bool> _loadStarredStatus(String filePath) async {
    return starredBox.get(filePath, defaultValue: false);
  }

  Future<void> _saveStarredStatus(String filePath, bool isStarred) async {
    await starredBox.put(filePath, isStarred);
    if (!isStarred) {
      await starredBox.delete(filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 35.0, top: 16.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildRecentDatasets()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Added Datasets',
          style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
        ),
        Text(
          'The 7 most recently added datasets in your root directory',
          style: TextStyle(
            fontSize: 16.0,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDatasets() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (!isRootDirectorySelected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No root directory selected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Set a root directory to view recent datasets'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showRootDirectorySelectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Select Root Directory'),
            ),
          ],
        ),
      );
    }

    if (recentDatasetFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recent datasets found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Upload some datasets to see them here'),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 2.0,
            spreadRadius: 0.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF2A2D37) : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Size',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Added Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(width: 80),
              ],
            ),
          ),
          Expanded(
            child: AnimationLimiter(
              child: ListView.separated(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: recentDatasetFiles.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[200], height: 1),
                itemBuilder: (context, index) {
                  final file = recentDatasetFiles[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(file.fileType),
                                size: 24,
                                color: _getFileColor(file.fileType),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  file.fileName,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: _getFileColor(
                                      file.fileType,
                                    ).withValues(alpha: isDarkMode ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    file.fileType,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: _getFileColor(file.fileType),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  file.fileSize,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  DateFormat('MMM dd, yyyy - HH:mm').format(file.modified),
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  file.isStarred ? Icons.star : Icons.star_border,
                                  size: 20,
                                  color:
                                      file.isStarred
                                          ? Colors.amber
                                          : (isDarkMode ? Colors.grey[400] : null),
                                ),
                                onPressed: () {
                                  setState(() {
                                    file.isStarred = !file.isStarred;
                                    _saveStarredStatus(file.filePath, file.isStarred);
                                  });
                                },
                                tooltip: "Add to favorites",
                                splashRadius: 20,
                              ),
                              TextButton(
                                onPressed: () => _handleImportDataset(file),
                                child: Text(
                                  'Import',
                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      case 'txt':
        return Icons.text_snippet;
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
      case 'txt':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleImportDataset(DatasetFile file) async {
    debugPrint('Importing dataset: ${file.filePath}');

    // Get existing imports or initialize empty list
    List<dynamic> recentImports = recentImportsBox.get('recentImports') ?? [];

    // Create new import record
    final newImport = RecentImportsModel(
      fileName: file.fileName,
      fileType: file.fileType,
      fileSize: file.fileSize,
      importTime: DateTime.now(),
      filePath: file.filePath,
    );

    // Update imports list
    if (recentImports is! List<RecentImportsModel>) {
      recentImports = <RecentImportsModel>[];
    }

    recentImports.insert(0, newImport);

    // Limit to 10 records
    if (recentImports.length > 10) {
      recentImports = recentImports.sublist(0, 10);
    }

    // Save to Hive
    await recentImportsBox.put('recentImports', recentImports);
    await recentImportsBox.put('currentDatasetName', file.fileName);
    await recentImportsBox.put('currentDatasetPath', file.filePath);
    await recentImportsBox.put('currentDatasetType', file.fileType);

    // Navigate to Data View
    if (widget.onNavigate != null) {
      widget.onNavigate!(3);
    }
  }

  void _showRootDirectorySelectionDialog() {
    // Show dialog for root directory selection
    // Implementation would be similar to that in FolderAll
    // For brevity, I'm keeping this as a stub

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Root Directory'),
            content: Text('Choose a location where your datasets will be stored.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  // Directory selection logic would go here
                  Navigator.pop(context);
                },
                child: Text('Select Directory'),
              ),
            ],
          ),
    );
  }
}
