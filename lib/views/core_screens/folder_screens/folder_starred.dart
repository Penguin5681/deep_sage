import 'dart:io';
import 'package:flutter/material.dart';
import 'package:deep_sage/core/models/dataset_file.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class FolderStarred extends StatefulWidget {
  const FolderStarred({super.key});

  @override
  State<FolderStarred> createState() => _FolderStarredState();
}

class _FolderStarredState extends State<FolderStarred> {
  final TextEditingController searchBarController = TextEditingController();
  List<DatasetFile> starredDatasetFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarredDatasets();
  }

  Future<void> _loadStarredDatasets() async {
    setState(() {
      isLoading = true;
    });

    try {
      final starredBox = await Hive.openBox('starred_datasets');
      List<DatasetFile> files = [];

      for (var key in starredBox.keys) {
        if (starredBox.get(key) == true) {
          String filePath = key.toString();
          File file = File(filePath);

          if (await file.exists()) {
            final fileStats = await file.stat();
            final extension = path.extension(filePath).toLowerCase();
            final fileSize = await _getFileSize(filePath, fileStats.size);

            files.add(
              DatasetFile(
                fileName: path.basename(filePath),
                fileType: extension.replaceFirst('.', ''),
                fileSize: fileSize,
                filePath: filePath,
                modified: fileStats.modified,
                isStarred: true,
              ),
            );
          }
        }
      }

      setState(() {
        starredDatasetFiles = files;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading starred datasets: $e');
      setState(() {
        isLoading = false;
      });
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

  Future<void> _removeFromStarred(String filePath) async {
    final starredBox = await Hive.openBox('starred_datasets');
    await starredBox.put(filePath, false);
    await _loadStarredDatasets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                  child: _buildSearchBar(),
                ),
                _buildStarredDatasetsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 300,
      child: TextField(
        style: TextStyle(),
        controller: searchBarController,
        decoration: InputDecoration(
          hintText: "Search starred files",
          suffixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
      ),
    );
  }

  Widget _buildStarredDatasetsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Starred Datasets',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
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
                    'Modified',
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

          Container(
            height: 300,
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.3 : 0.05,
                  ),
                  blurRadius: 2.0,
                  spreadRadius: 0.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : starredDatasetFiles.isEmpty
                    ? Center(
                      child: Text(
                        'No starred datasets found!',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    )
                    : ListView.separated(
                      physics: ClampingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: starredDatasetFiles.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            height: 1,
                          ),
                      itemBuilder: (context, index) {
                        final file = starredDatasetFiles[index];
                        // final fileData = file.toMap();

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode ? Color(0xFF1F222A) : Colors.white,
                            border:
                                index == starredDatasetFiles.length - 1
                                    ? Border(
                                      bottom: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    )
                                    : null,
                          ),
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
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
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
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(file.modified),
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  _removeFromStarred(file.filePath);
                                },
                                tooltip: "Remove from favorites",
                                splashRadius: 20,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: isDarkMode ? Colors.grey[400] : null,
                                ),
                                onPressed: () => _openFileDetails(file),
                                tooltip: "More options",
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Icons.insert_drive_file;
      case 'json':
        return Icons.data_object;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      default:
        return Icons.description;
    }
  }

  Color _getFileColor(String fileType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (fileType.toLowerCase()) {
      case 'csv':
        return Colors.green.shade600;
      case 'json':
        return Colors.orange.shade600;
      case 'xlsx':
      case 'xls':
        return Colors.blue.shade600;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }

  Future<void> _openFileDetails(DatasetFile file) async {
    // Show file details dialog or navigate to details screen
    showDialog(
      context: context,
      builder: (context) => _buildFileDetailsDialog(file),
    );
  }

  Widget _buildFileDetailsDialog(DatasetFile file) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDarkMode ? Color(0xFF1F222A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getFileColor(file.fileType).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(file.fileType),
                    color: _getFileColor(file.fileType),
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        file.filePath,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildFileInfoItem("Type", file.fileType.toUpperCase(), isDarkMode),
            _buildFileInfoItem("Size", file.fileSize, isDarkMode),
            _buildFileInfoItem(
              "Last Modified",
              DateFormat('MMMM dd, yyyy - HH:mm').format(file.modified),
              isDarkMode,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.folder_open),
                  label: Text("Show in folder"),
                  onPressed: () {
                    _openContainingFolder(file.filePath);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDarkMode
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.open_in_new),
                  label: Text("Open file"),
                  onPressed: () {
                    _openFile(file.filePath);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoItem(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openContainingFolder(String filePath) async {
    final directory = path.dirname(filePath);
    try {
      // This would require a platform-specific implementation
      // For example using url_launcher package
      debugPrint('Opening folder: $directory');
      // Implementation depends on platform (Windows, macOS, Linux)
    } catch (e) {
      debugPrint('Error opening folder: $e');
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      // This would require a platform-specific implementation
      // For example using url_launcher package
      debugPrint('Opening file: $filePath');
      // Implementation depends on platform (Windows, macOS, Linux)
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  @override
  void dispose() {
    searchBarController.dispose();
    super.dispose();
  }
}
