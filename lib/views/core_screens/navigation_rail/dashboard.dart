import 'dart:io';

import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;

import '../../../core/models/dataset_file.dart';

/// Dashboard widget that displays data overview and dataset file management.
///
/// It shows dataset statistics, a list of recent imports, and allows users
/// to manage their datasets by uploading, importing, renaming, or deleting files.
class Dashboard extends StatefulWidget {
  final Function(int) onNavigate;

  const Dashboard({super.key, required this.onNavigate});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  /// The path of the currently selected root directory for datasets.
  String selectedRootDirectoryPath = '';

  /// Indicates whether a root directory has been selected by the user.
  bool isRootDirectorySelected = false;

  /// Indicates whether there are any files present in the selected root directory.
  bool anyFilesPresent = false;

  /// A list of folders found in the selected root directory.
  List<Map<String, String>> folders = [];

  /// A list of [DatasetFile] objects representing the files found in the selected root directory.
  List<DatasetFile> datasetFiles = [];

  /// The Hive box for managing starred dataset files.
  late final Box starredBox;

  /// The Hive box for managing recently imported dataset files.
  late final Box recentImportsBox;

  /// Controller for the search text field.
  late TextEditingController searchController;

  late int hoveredIndex = -1;

  /// Controller for the scrollable list view.
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize search controller and other components.

    searchController = TextEditingController();
    _initializeBoxes();
    _loadRootDirectory();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources.
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeBoxes() async {
    starredBox = Hive.box('starred_datasets');
    // Load environment variables and set the recent imports history.
    recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

    final currentDataset = recentImportsBox.get('currentDatasetName');
    if (currentDataset != null) {
      setState(() {
        anyFilesPresent = true;
      });
    }
  }

  Future<void> _loadRootDirectory() async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final rootDir = hiveBox.get('selectedRootDirectoryPath');

    if (rootDir != null && rootDir.isNotEmpty) {
      setState(() {
        selectedRootDirectoryPath = rootDir;
        isRootDirectorySelected = true;
      });

      scanForDatasetFiles(rootDir);
    }
  }

  /// Scans for dataset files within the specified root directory.
  ///
  /// This method recursively searches the directory specified by [rootPath]
  /// for files with extensions '.json', '.csv', or '.txt'. It updates the state
  /// with the list of found [DatasetFile] objects and whether any files were found.
  /// If an error occurs during the scanning process, it prints an error message to the debug console.
  Future<void> scanForDatasetFiles(String rootPath) async {
    if (rootPath.isEmpty) return;
    List<DatasetFile> files = [];
    try {
      await _scanDirectory(rootPath, files);
      setState(() {
        datasetFiles = files;
        anyFilesPresent = files.isNotEmpty;
      });
    } catch (ex) {
      debugPrint('Error scanning files: $ex');
    }
  }

  /// Recursively scans a directory for files and subdirectories.
  ///
  /// This method takes a [directoryPath] and a list of [files] to populate.
  /// It traverses the directory structure, identifying files with the specified
  /// extensions ('.json', '.csv', '.txt'). For each identified file, it creates a
  /// [DatasetFile] object containing relevant details like file name, type, size,
  /// path, modification time, and whether it's starred. It also recursively calls
  /// itself for each subdirectory found. If an error occurs during scanning, it
  /// prints an error message to the debug console.
  ///
  Future<void> _scanDirectory(
    String directoryPath,
    List<DatasetFile> files,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return;

    try {
      await for (var entity in dir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.json', '.csv', '.txt'].contains(extension)) {
            final fileStats = await entity.stat();
            final fileSize = _formatFileSize(fileStats.size);
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

  /// Formats the file size in bytes to a human-readable format.
  ///
  /// This function converts a file size given in [bytes] to a string
  /// representation with appropriate units (B, KB, MB, GB).
  ///
  /// Args:
  ///   bytes (int): The size of the file in bytes.
  ///
  /// Returns: A formatted string representing the file size with units.
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  /// Builds the section of the UI that displays an overview of the data.
  ///
  /// This section includes statistics such as total datasets, starred files,
  /// CSV files, and JSON files. It also shows a list of recent imports if any.
  ///
  /// Returns:
  ///   A [Widget] representing the data overview section.
  Widget _buildDataOverviewSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Data Overview',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),

          Row(
            children: [
              _buildOverviewCard(
                title: 'Total Datasets',
                value: datasetFiles.length.toString(),
                icon: Icons.dataset,
                color: Colors.blue,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 16),
              _buildOverviewCard(
                title: 'Starred Files',
                value:
                    datasetFiles
                        .where((file) => file.isStarred)
                        .length
                        .toString(),
                icon: Icons.star,
                color: Colors.amber,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 16),
              _buildOverviewCard(
                title: 'CSV Files',
                value:
                    datasetFiles
                        .where((file) => file.fileType == 'csv')
                        .length
                        .toString(),
                icon: Icons.table_chart,
                color: Colors.green,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 16),
              _buildOverviewCard(
                title: 'JSON Files',
                value:
                    datasetFiles
                        .where((file) => file.fileType == 'json')
                        .length
                        .toString(),
                icon: Icons.data_object,
                color: Colors.orange,
                isDarkMode: isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (datasetFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Recent Imports',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),

          if (datasetFiles.isNotEmpty)
            ValueListenableBuilder(
              valueListenable: recentImportsBox.listenable(),
              builder: (context, box, _) {
                final recentImports = box.get('recentImports');
                if (recentImports == null ||
                    (recentImports is List && recentImports.isEmpty)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No recent imports yet. Import a dataset to get started.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  );
                }

                List<RecentImportsModel> imports = [];
                if (recentImports is List) {
                  imports = recentImports.cast<RecentImportsModel>();
                } else if (recentImports is RecentImportsModel) {
                  imports = [recentImports];
                }

                return Container(
                  margin: const EdgeInsets.only(top: 12.0),
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imports.length,
                    itemBuilder: (context, index) {
                      final import = imports[index];
                      return _buildRecentImportCard(import, isDarkMode, index);
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Builds an overview card for display in the data overview section.
  ///
  /// This widget creates a card that displays a [title], a [value], an [icon],
  /// and is styled according to the current [isDarkMode] setting. The card's
  /// appearance (color, border, shadow) changes to complement the light or dark
  /// theme of the application.
  ///
  /// Args:
  ///   title (String): The title of the information displayed in the card.
  ///   value (String): The value or numerical data associated with the title.
  ///   icon (IconData): The icon to visually represent the card's content.
  ///   color (Color): The color for the icon and the background of the icon container.
  ///   isDarkMode (bool): Indicates whether the app is in dark mode, affecting the card's styling.
  ///
  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2A2D37) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card that displays a recent import.
  ///
  /// This widget creates a card that displays the details of a recently imported file,
  /// including its type, name, size, and import date. The card's styling changes
  /// depending on whether the application is in dark mode or not.
  ///
  /// Args:
  ///   import (RecentImportsModel): The data model containing information about the recent import.
  ///   isDarkMode (bool): Indicates whether the app is in dark mode, affecting the card's styling.
  ///
  /// Returns:
  ///   A [Widget] representing the recent import card. It includes:
  ///   - File type icon and type label.
  ///   - File name, with an ellipsis overflow for longer names.
  ///   - File size and the date/time of import, formatted for readability.
  ///
  Widget _buildRecentImportCard(
    RecentImportsModel import,
    bool isDarkMode,
    int index,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform:
            hoveredIndex == index
                ? Matrix4.translationValues(0, -5, 0)
                : Matrix4.identity(),
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2A2D37) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min, // Use min size to prevent overflow
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getFileColor(
                          import.fileType,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getFileIcon(import.fileType),
                        color: _getFileColor(import.fileType),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        import.fileType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getFileColor(import.fileType),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Reduced spacing
                Text(
                  import.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3), // Reduced spacing
                Text(
                  '${import.fileSize} · ${_formatDate(import.importTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Formats the given [DateTime] object into a human-readable string representation.
  ///
  /// This function calculates the time difference between the current time and the
  /// provided [date], and returns a string describing the time elapsed since the
  /// given date. The output format depends on the difference:
  /// - If the date is within the same day:
  ///   - If within the same hour: "{minutes} min ago".
  ///   - Otherwise: "{hours} hr ago".
  /// - If the date is within the last 7 days: "{days} days ago".
  /// - Otherwise: "{day}/{month}/{year}".
  ///
  /// Args:
  ///   date (DateTime): The date to format.
  ///
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Builds the main UI for the dashboard.
  ///
  /// This method constructs the primary layout of the dashboard, which can either
  /// display a list of datasets and their overviews if a root directory has been
  /// selected, or a prompt to select a root directory if one hasn't been chosen yet.
  ///
  /// If a root directory is selected:
  ///   - It displays a [SingleChildScrollView] containing a [Column] with:
  ///     - A data overview section built by [_buildDataOverviewSection].
  ///     - A placeholder if no files are present, built by [_buildPlaceholder].
  ///     - A dataset files section if files are present, built by [_buildDatasetFilesSection].
  /// If no root directory is selected:
  ///   - It displays a centered [Column] prompting the user to select a directory,
  ///     with an [ElevatedButton] to trigger [_showRootDirectoryDialog].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isRootDirectorySelected
              ? SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildDataOverviewSection(),
                      if (!anyFilesPresent)
                        _buildPlaceholder(
                          onUploadClicked: _uploadFiles,
                          onImportClicked: () {
                            widget.onNavigate(1);
                          },
                        ),
                      if (anyFilesPresent) _buildDatasetFilesSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Please select a root directory for your datasets',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _showRootDirectoryDialog(context),
                      child: Text('Select Directory'),
                    ),
                  ],
                ),
              ),
    );
  }

  /// Builds the dataset files section of the dashboard.
  ///
  /// This widget displays a list of all dataset files found within the
  /// selected root directory. It includes a search bar to filter files by
  /// name and a table-like view with columns for file name, type, size, and
  /// modification date. Each row in the table also provides actions such as
  /// starring, renaming, deleting, and importing a dataset. The appearance
  /// of the section adapts to the current theme (dark/light mode).
  ///
  /// The method handles:
  /// - Filtering the displayed file list based on the search term.
  /// - Displaying file details like name, type, size, and modified date.
  /// - Providing interactive elements like star toggling and file management actions.
  /// - Adapting to dark or light mode.
  Widget _buildDatasetFilesSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Datasets',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search datasets',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Color(0xFF2A2D37) : Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Filter files based on search term
                        if (value.isEmpty) {
                          scanForDatasetFiles(selectedRootDirectoryPath);
                        } else {
                          // Filter existing files without rescanning
                          final List<DatasetFile> filteredFiles =
                              datasetFiles
                                  .where(
                                    (file) => file.fileName
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                  )
                                  .toList();
                          datasetFiles = filteredFiles;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF2A2D37) : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                // Table header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(width: 40),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Size',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date Modified',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(width: 100),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),

                // File list
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: datasetFiles.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                  itemBuilder: (context, index) {
                    final file = datasetFiles[index];
                    return ListTile(
                      leading: StatefulBuilder(
                        builder: (context, setStarState) {
                          return IconButton(
                            icon: Icon(
                              file.isStarred ? Icons.star : Icons.star_border,
                              color:
                                  file.isStarred
                                      ? Colors.amber
                                      : isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                            ),
                            onPressed: () async {
                              final newStarredStatus = !file.isStarred;
                              await _saveStarredStatus(
                                file.filePath,
                                newStarredStatus,
                              );

                              setStarState(() {
                                file.isStarred = newStarredStatus;
                              });

                              setState(() {
                                datasetFiles[index] = file;
                              });
                            },
                          );
                        },
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              file.fileName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getFileColor(
                                      file.fileType,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    file.fileType.toUpperCase(),
                                    style: TextStyle(
                                      color: _getFileColor(file.fileType),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              file.fileSize,
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatDate(file.modified),
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 20),
                            onPressed:
                                () => _handleRenameDataset(file.filePath),
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20),
                            onPressed:
                                () => _handleDeleteDataset(file.filePath),
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          TextButton(
                            onPressed:
                                () => _handleImportDataset(file.filePath),
                            child: Text(
                              'Import',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Preview or open the file
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Imports the dataset specified by [filePath] into the list of recent imports.
  ///
  /// This function performs the following actions:
  /// 1. Retrieves the [DatasetFile] corresponding to the provided [filePath] from [datasetFiles].
  /// 2. Adds the file to the list of recent imports in the [recentImportsBox].
  /// 3. Updates the current dataset details in [recentImportsBox].
  /// 4. Navigates to the next screen using [widget.onNavigate] with index 3.
  ///
  /// The list of recent imports is capped at a maximum of 10 entries. If the list
  /// exceeds this limit, the oldest entry is removed.
  ///
  /// Args:
  ///   filePath (String): The path to the file that is being imported.
  ///
  /// Returns: void.
  void _handleImportDataset(String filePath) async {
    final file = datasetFiles.firstWhere((file) => file.filePath == filePath);
    debugPrint('Importing dataset: ${file.filePath}');

    List<RecentImportsModel> recentImports = [];
    final existingImports = recentImportsBox.get('recentImports');

    if (existingImports != null) {
      if (existingImports is List) {
        recentImports = existingImports.cast<RecentImportsModel>();
      } else if (existingImports is RecentImportsModel) {
        recentImports = [existingImports];
      }
    }

    final newImport = RecentImportsModel(
      fileName: file.fileName,
      fileType: file.fileType,
      fileSize: file.fileSize,
      importTime: DateTime.now(),
      filePath: file.filePath,
    );

    recentImports.insert(0, newImport);

    if (recentImports.length > 10) {
      recentImports = recentImports.sublist(0, 10);
    }

    await recentImportsBox.put('recentImports', recentImports);

    await recentImportsBox.put('currentDatasetName', file.fileName);
    await recentImportsBox.put('currentDatasetPath', file.filePath);
    await recentImportsBox.put('currentDatasetType', file.fileType);

    widget.onNavigate(3);
  }

  /// Handles the renaming of a dataset file.
  ///
  /// This method performs the following steps:
  /// 1. **Finds the dataset file:** Locates the `DatasetFile` object in `datasetFiles`
  ///    that corresponds to the given `filePath`.
  /// 2. **Creates a text editing controller:** Initializes a `TextEditingController`
  ///    with the current file name for editing.
  /// 3. **Displays a dialog:** Shows an `AlertDialog` to prompt the user for the new
  ///    file name. The dialog contains:
  ///    - A `TextField` for entering the new name, pre-filled with the current name.
  ///    - "Cancel" and "Rename" action buttons.
  /// 4. **Processes the rename action:** When the "Rename" button is pressed:
  ///    - Checks if the entered name is valid (not empty and different from the current name).
  ///    - Appends the original file extension to the new name if missing.
  ///    - Constructs the new file path.
  ///    - Renames the file using `File.rename()`.
  ///    - Updates the starred file path if the file was starred using `updateStarredFilePath()`.
  ///    - Rescans the directory to update the file list using `scanForDatasetFiles()`.
  ///    - Closes the dialog.
  /// 5. **Handles errors:** If any error occurs during the renaming process:
  ///    - Prints an error message to the debug console.
  ///    - Displays a `SnackBar` with an error message.
  ///    - Closes the dialog.
  ///
  /// Parameters:
  ///   `filePath`: The path of the file to be renamed.
  ///
  /// Throws:
  ///   Any exception that might be thrown by the `File.rename()` method or
  ///   by other file operations.
  ///
  void _handleRenameDataset(String filePath) {
    final file = datasetFiles.firstWhere((file) => file.filePath == filePath);

    TextEditingController renameController = TextEditingController(
      text: file.fileName,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rename Dataset'),
            content: TextField(
              controller: renameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter new name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (renameController.text.isNotEmpty &&
                      renameController.text != file.fileName) {
                    String newName = renameController.text;
                    String extension = path.extension(file.filePath);

                    if (!newName.endsWith(extension)) {
                      newName += extension;
                    }

                    String directory = path.dirname(file.filePath);
                    String newPath = path.join(directory, newName);

                    try {
                      File originalFile = File(file.filePath);
                      await originalFile.rename(newPath);

                      await updateStarredFilePath(file.filePath, newPath);

                      scanForDatasetFiles(selectedRootDirectoryPath);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error renaming file: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to rename file: $e')),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text('Rename'),
              ),
            ],
          ),
    );
  }

  /// Handles the deletion of a dataset file.
  ///
  /// This method performs the following steps:
  /// 1. **Finds the dataset file:** Locates the `DatasetFile` object in `datasetFiles`
  ///    that corresponds to the given `filePath`.
  /// 2. **Displays a confirmation dialog:** Shows an `AlertDialog` to prompt the
  ///    user for confirmation before deleting the file. The dialog contains:
  ///    - A message confirming the user wants to delete the specified file.
  ///    - "Cancel" and "Delete" action buttons.
  /// 3. **Processes the delete action:** When the "Delete" button is pressed:
  ///    - Deletes the file from the filesystem using `File.delete()`.
  ///    - If the file is starred, removes it from the starred dataset box.
  ///    - Rescans the directory to update the file list using `scanForDatasetFiles()`.
  ///    - Closes the dialog.
  /// 4. **Handles errors:** If any error occurs during the deletion process:
  ///    - Prints an error message to the debug console.
  ///    - Displays a `SnackBar` with an error message.
  ///    - Closes the dialog.
  ///
  /// Parameters:
  ///   `filePath`: The path of the file to be deleted.
  ///
  /// Throws:
  ///   Any exception that might be thrown by the `File.delete()` method or
  ///   by other file operations.
  ///
  /// Note:
  ///   - This action is irreversible. Once a file is deleted, it cannot be
  ///     recovered through this application.
  ///   - The user is prompted to confirm the deletion to prevent accidental loss
  ///     of data.
  ///   - The file list is updated immediately after a successful deletion to reflect
  ///     the changes in the UI.
  void _handleDeleteDataset(String filePath) {
    final file = datasetFiles.firstWhere((file) => file.filePath == filePath);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Dataset'),
            content: Text(
              'Are you sure you want to delete "${file.fileName}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  try {
                    File fileToDelete = File(file.filePath);
                    await fileToDelete.delete();

                    if (file.isStarred) {
                      await starredBox.delete(file.filePath);
                    }

                    scanForDatasetFiles(selectedRootDirectoryPath);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error deleting file: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete file: $e')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  /// Saves or removes the starred status of a dataset file.
  ///
  /// This method manages the starred status of a file by either adding it to
  /// the `starredBox` (if [isStarred] is true) or removing it from the
  /// `starredBox` (if [isStarred] is false).
  ///
  /// If a file is unstarred (i.e., [isStarred] is false), it is deleted from
  /// the `starredBox` to ensure it's no longer marked as starred.
  ///
  /// Args:
  ///   filePath (String): The path of the file whose starred status is being updated.
  ///   isStarred (bool): The new starred status of the file. True if starred, false otherwise.
  ///
  /// Returns: A [Future] that completes when the starred status has been saved or removed.
  ///
  Future<void> _saveStarredStatus(String filePath, bool isStarred) async {
    await starredBox.put(filePath, isStarred);
    if (!isStarred) {
      await starredBox.delete(filePath);
    }
  }

  /// Loads the starred status of a dataset file from the Hive box.
  ///
  /// This method checks the `starredBox` for a given file path and returns
  /// its starred status. If the file path is not found in the box, it defaults
  /// to false, meaning the file is not starred.
  ///
  /// Args:
  ///   filePath (String): The path of the file for which to load the starred status.
  ///
  /// Returns:
  ///   A [Future<bool>] representing whether the file is starred (true) or not (false).
  ///
  Future<bool> _loadStarredStatus(String filePath) async {
    return starredBox.get(filePath, defaultValue: false);
  }

  /// Updates the starred file path in the `starredBox`.
  ///
  /// This method is used when a file is renamed. If the file was starred
  /// before the rename, this method updates its entry in the `starredBox`
  /// to reflect the new file path.
  ///
  /// Steps:
  /// 1. Checks if the file was starred using [_loadStarredStatus].
  /// 2. If starred, it deletes the old path from the `starredBox`.
  /// 3. Then it adds a new entry with the new path and a value of `true`.
  ///
  /// Args:
  ///   oldPath (String): The original path of the file.
  ///   newPath (String): The new path of the file after it has been renamed.
  ///
  Future<void> updateStarredFilePath(String oldPath, String newPath) async {
    bool wasTheFileStarredBefore = await _loadStarredStatus(oldPath);
    if (wasTheFileStarredBefore) {
      await starredBox.delete(oldPath);
      await starredBox.put(newPath, true);
    }
  }

  /// Retrieves the appropriate icon for a given file type.
  ///
  /// This method uses a switch statement to determine the correct icon
  /// based on the file extension. The method is case-insensitive.
  ///
  /// Args:
  ///   fileType (String): The file type (e.g., 'csv', 'json', 'txt').
  ///
  /// Returns:
  ///   IconData: The icon corresponding to the file type, or a default file icon.
  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      case 'txt':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Determines the color associated with a specific file type.
  ///
  /// This function maps common file types (e.g., 'csv', 'json', 'txt') to
  /// specific colors, helping to visually distinguish between file types in the UI.
  /// The comparison is case-insensitive.
  ///
  /// Args:
  ///   fileType (String): The type of the file (e.g., 'csv', 'json', 'txt').
  ///
  /// Returns: Color: The color associated with the file type, or grey as a default.
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

  /// Builds the placeholder UI when no datasets are found.
  ///
  /// This widget is displayed when there are no dataset files found within
  /// the selected root directory. It prompts the user to either upload new
  /// files or import existing datasets. The appearance of the placeholder is
  /// designed to be visually appealing and user-friendly, with options for
  /// uploading and importing datasets.
  ///
  /// Parameters:
  ///   `onUploadClicked`: A callback function that is invoked when the user
  ///     clicks on the 'Upload Files' button. This should trigger the file
  ///     upload process.
  ///   `onImportClicked`: A callback function that is invoked when the user
  ///     clicks on the 'Search Datasets' button. This should trigger the
  ///     dataset import process or navigate to the dataset search view.
  ///
  Widget _buildPlaceholder({
    required VoidCallback onUploadClicked,
    required VoidCallback onImportClicked,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      padding: EdgeInsets.all(40),
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2A2D37) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            'No datasets found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Upload or import your datasets to get started with analysis and visualization',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onUploadClicked,
                icon: Icon(Icons.upload_file),
                label: Text('Upload Files'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: onImportClicked,
                icon: Icon(Icons.search),
                label: Text('Search Datasets'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Uploads files selected by the user to the selected root directory.
  ///
  /// This method opens a file picker dialog that allows users to select one or
  /// multiple files with specified extensions (csv, json, txt). Once files are
  /// selected, they are copied to the root directory.
  ///
  /// Steps:
  /// 1. Opens the file picker dialog using `FilePicker.platform.pickFiles`.
  /// 2. Filters for files with 'csv', 'json', or 'txt' extensions.
  /// 3. Allows for multiple file selection.
  /// 4. If files are selected, each file is copied to the selected root directory.
  /// 5. `scanForDatasetFiles` is called to update the list of files.
  /// 6. In case of an error, it logs the error and shows a snack bar with the error message.
  ///
  /// Throws: Exception: if there is any error during the upload process.
  Future<void> _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'txt'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            final destPath = path.join(selectedRootDirectoryPath, file.name);
            await File(file.path!).copy(destPath);
          }
        }
        scanForDatasetFiles(selectedRootDirectoryPath);
      }
    } catch (e) {
      debugPrint('Error uploading files: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload files: $e')));
    }
  }

  /// Displays a dialog to allow the user to select a root directory for datasets.
  ///
  /// This function presents the user with a file picker dialog, allowing them
  /// to choose a directory from their file system. Once a directory is chosen,
  /// it is set as the root directory for the application's datasets. This
  /// selected path is stored in a Hive box for persistence across sessions.
  ///
  /// Steps:
  /// 1. Presents a directory picker using `FilePicker.platform.getDirectoryPath()`.
  /// 2. If a directory is selected:
  ///    - Saves the directory path to the Hive box under the key 'selectedRootDirectoryPath'.
  ///    - Updates the state to reflect the selected directory.
  ///    - Initiates a scan for files within the new root directory.
  ///
  /// Parameters:
  ///   `context`: The build context for the current widget tree.
  ///
  Future<void> _showRootDirectoryDialog(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
      await hiveBox.put('selectedRootDirectoryPath', selectedDirectory);

      setState(() {
        selectedRootDirectoryPath = selectedDirectory;
        isRootDirectorySelected = true;
      });

      scanForDatasetFiles(selectedDirectory);
    }
  }
}
