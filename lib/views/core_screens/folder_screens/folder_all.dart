import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deep_sage/core/config/helpers/file_transfer_util.dart';
import 'package:deep_sage/core/models/dataset_file.dart';
import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/services/core_services/dataset_sync_service/aws_s3_operation_service.dart';
import 'package:deep_sage/core/services/core_services/dataset_sync_service/dataset_sync_management_service.dart';
import 'package:deep_sage/core/services/directory_path_service.dart';
import 'package:deep_sage/views/core_screens/explorer/file_explorer_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:path/path.dart' as path;

/// The `FolderAll` widget is a stateful widget that displays a list of
/// all folders and files within a designated root directory.
///
/// It allows the user to navigate, upload, and manage datasets.
class FolderAll extends StatefulWidget {
  final Function(int)? onNavigate;

  const FolderAll({super.key, required this.onNavigate});

  @override
  State<FolderAll> createState() => _FolderAllState();
}

class _FolderAllState extends State<FolderAll> {
  /// Controller for the search bar used to filter files.
  final TextEditingController searchBarController = TextEditingController();

  /// Hive box for managing starred datasets.
  final Box starredBox = Hive.box('starred_datasets');

  /// Hive box for storing general API-related data.
  final Box hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  /// Hive box for managing the history of recent imports.
  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  /// List to hold folder information (name and file count).
  final List<Map<String, String>> folders = [];

  /// Indicates whether any files are present in the current directory.
  late bool anyFilesPresent = true;

  /// Indicates whether a root directory has been selected.
  late bool isRootDirectorySelected = false;

  /// The currently selected root directory path.
  late String selectedRootDirectoryPath = '';

  /// The root directory path (retrieved from Hive or defaults to an empty string).
  late String rootDirectory = hiveBox.get('selectedRootDirectoryPath') ?? '';

  /// List of folder details including name and files in it
  late List<Map<String, String>> folderList = [];

  /// Subscription for the directory path stream.
  late StreamSubscription<String> pathSubscription;

  late int hoveredFolderIndex = -1;

  /// Watcher for changes in the root directory.
  StreamSubscription<FileSystemEvent>? directoryWatcher;

  /// Visibility flag for the file explorer.
  bool isExplorerVisible = false;

  /// The currently selected folder for the file explorer.
  String selectedFolderForExplorer = '';

  /// List of dataset files in the current directory.
  List<DatasetFile> datasetFiles = [];

  /// List of file watchers to monitor file changes.
  List<StreamSubscription<FileSystemEvent>> fileWatchers = [];

  /// Set of directories being watched for changes.
  Set<String> watchedDirectories = {};

  /// List of dataset files filtered according to the applied search criteria.
  List<DatasetFile> filteredDatasetFiles = [];

  /// Map of file paths to their download statuses.
  final Map<String, String> _downloadingFiles = {};

  /// Indicates if a syncing operation is currently in progress.
  bool _isSyncing = false;

  /// Initializes the state of the `FolderAll` widget.
  ///
  /// This method is called when the widget is first inserted into the widget tree.
  /// It performs the following tasks:
  /// - Loads the root directory path.
  /// - If a root directory is selected:
  ///   - Gets the file counts for the directory.
  ///   - Sets up a watcher for changes in the directory.
  ///   - Scans the directory for dataset files.
  /// - Sets up a listener for changes in the directory path using the `DirectoryPathService`.
  ///   - If a new path is received and it's different from the current path,
  ///     it updates the state and performs necessary operations.
  @override
  void initState() {
    super.initState();
    _loadRootDirectoryPath().then((_) {
      if (selectedRootDirectoryPath.isNotEmpty) {
        getDirectoryFileCounts(selectedRootDirectoryPath);
        setupDirectoryWatcher(selectedRootDirectoryPath);
        scanForDatasetFiles(selectedRootDirectoryPath).then((_) {
          updateFilesSyncStatus();
        });
      }
    });

    filteredDatasetFiles = datasetFiles;

    searchBarController.addListener(_filterDatasetFiles);

    pathSubscription = DirectoryPathService().pathStream.listen((newPath) {
      if (newPath != selectedRootDirectoryPath) {
        setState(() {
          selectedRootDirectoryPath = newPath;
          isRootDirectorySelected = newPath.isNotEmpty;
        });
        getDirectoryFileCounts(newPath);
        setupDirectoryWatcher(newPath);
      }
    });
  }

  /// Filters the list of dataset files based on the search query in the search bar.
  ///
  /// This method is called whenever the text in the `searchBarController` changes.
  /// It updates the `filteredDatasetFiles` list to include only the files whose
  /// name or type contains the search query. If the query is empty, all dataset
  /// files are included in the filtered list. The filtering is case-insensitive.
  ///
  /// This method updates the UI state using `setState`.
  void _filterDatasetFiles() {
    final query = searchBarController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredDatasetFiles = List.from(datasetFiles);
      } else {
        filteredDatasetFiles =
            datasetFiles.where((file) {
              return file.fileName.toLowerCase().contains(query) ||
                  file.fileType.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  /// Scans the specified [rootPath] for dataset files and updates the UI.
  ///
  /// This function searches for files with specific extensions (.json, .csv,
  /// .xlsx, .xls) in the given directory and its subdirectories. It updates
  /// the `datasetFiles` list and the `anyFilesPresent` flag based on the scan
  /// results. If an error occurs during the scanning process, it prints an
  /// error message to the debug console.
  /// This function also updates the [DatasetManagerService] class used in dashboard
  Future<void> scanForDatasetFiles(String rootPath) async {
    if (rootPath.isEmpty) return;
    List<DatasetFile> files = [];
    try {
      await _scanDirectory(rootPath, files);
      setState(() {
        datasetFiles = files;
        _filterDatasetFiles();
        anyFilesPresent = files.isNotEmpty;
      });
      updateFilesSyncStatus();
    } catch (ex) {
      debugPrint('Error scanning files: $ex');
    }
  }

  /// Recursively scans a [directoryPath] for dataset files and adds them to
  /// the provided [files] list.
  ///
  /// This function traverses the directory structure, identifying files that
  /// match the supported dataset file extensions. It also sets up file watchers
  /// for directories that haven't been watched yet. If an error occurs during
  /// the scanning process, it prints an error message to the debug console.
  /// This function performs deep file traversal
  Future<void> _scanDirectory(String directoryPath, List<DatasetFile> files) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return;

    if (!watchedDirectories.contains(directoryPath)) {
      setupFileWatcher(directoryPath);
      watchedDirectories.add(directoryPath);
    }

    try {
      await for (var entity in dir.list()) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.json', '.csv', '.txt'].contains(extension)) {
            final fileStats = await entity.stat();
            final fileSize = await _getFileSize(entity.path, fileStats.size);
            final isStarred = await _loadStarredStatus(entity.path);
            debugPrint('Is the file starred: $isStarred');

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

  /// Returns a human-readable file size string for the given [bytes].
  ///
  /// Converts the number of bytes into KB, MB, or GB as appropriate, and
  /// formats the result to one decimal place.
  ///
  /// Args:
  /// - `filepath` (String): The path to the file being sized.
  /// - `bytes` (int): The size of the file in bytes.
  ///
  /// Returns:
  /// - `String`: The file size formatted as 'X B', 'X.X KB', 'X.X MB', or 'X.X GB'.
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

  /// Sets up a directory watcher for the given [dirPath].
  ///
  /// This function creates a `DirectoryWatcher` that listens for changes in
  /// the specified directory. When changes occur, it triggers a series of
  /// actions:
  /// - Waits for a short delay (500 milliseconds) to avoid multiple calls.
  /// - Checks if the widget is still mounted.
  /// - Gets the updated file counts for the directory.
  /// - Scans for dataset files.
  /// - Prints a debug message indicating the event and its type.
  /// The previous watcher is cancelled if it exist
  void setupDirectoryWatcher(String dirPath) {
    directoryWatcher?.cancel();

    if (dirPath.isEmpty) return;

    try {
      directoryWatcher = Directory(dirPath).watch(recursive: true).listen((event) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            getDirectoryFileCounts(dirPath);
            scanForDatasetFiles(dirPath);
            debugPrint('Something happened in the root: ${event.path} - ${event.type}');
          }
        });
      });
    } catch (ex) {
      debugPrint('setupDirectoryWatcher(): $ex');
    }
  }

  /// Sets up a file watcher for a directory to monitor changes in its files.
  ///
  /// This function creates a `DirectoryWatcher` for the specified
  /// [directoryPath] and listens for events such as file creation, deletion,
  /// or modification. When an event occurs:
  ///
  /// - A delay of 500 milliseconds is introduced to avoid rapid updates.
  /// - It checks if the widget is still mounted.
  /// - If the event is related to a supported file type (.json, .csv, .xlsx,
  ///   .xls), it rescans for dataset files in the root directory.
  /// - If the event is a directory creation event, it recursively sets up a
  ///   file watcher for the new directory and adds it to the list of watched
  ///   directories.
  /// - Prints debug messages to track the events and their types.
  /// - Adds the newly created `StreamSubscription` to the list of `fileWatchers`
  ///   for future management.
  void setupFileWatcher(String directoryPath) {
    try {
      final subscription = Directory(directoryPath).watch(recursive: true).listen((event) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            final filePath = event.path;
            final extension = path.extension(filePath).toLowerCase();

            if (['.json', '.csv', '.txt'].contains(extension)) {
              scanForDatasetFiles(selectedRootDirectoryPath);
              debugPrint('Something happened to your file niga: ${event.path} - ${event.type}');
            } else if (event.type == FileSystemEvent.create && Directory(event.path).existsSync()) {
              setupFileWatcher(event.path);
              watchedDirectories.add(event.path);
              scanForDatasetFiles(selectedRootDirectoryPath);
            }
          }
        });
      });
      fileWatchers.add(subscription);
    } catch (ex) {
      debugPrint('Error setting up file stalker: $ex');
    }
  }

  /// Loads the root directory path from Hive.
  ///
  /// This function retrieves the 'selectedRootDirectoryPath' from the Hive box
  /// associated with the API. It then updates the state to reflect whether a
  /// root directory has been selected or not. If a root directory path is
  /// found and it is not empty, it updates the
  /// `selectedRootDirectoryPath` and `isRootDirectorySelected` accordingly.
  Future<void> _loadRootDirectoryPath() async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final savedPath = hiveBox.get('selectedRootDirectoryPath');

    setState(() {
      if (savedPath != null && savedPath.toString().isNotEmpty) {
        selectedRootDirectoryPath = savedPath;
        isRootDirectorySelected = true;
      }
    });
  }

  /// Retrieves file counts for the specified directory and its subdirectories.
  ///
  /// This function counts the number of files in the given [directoryPath] and
  /// its subdirectories, and populates the `folders` list with the folder
  /// names and their respective file counts. It also checks for the presence
  /// of any files or folders and updates the `anyFilesPresent` flag
  /// accordingly.
  ///
  /// Args:
  /// - `directoryPath` (String): The path to the directory for which file
  ///   counts should be retrieved.
  ///
  /// Throws:
  Future<void> getDirectoryFileCounts(String directoryPath) async {
    if (directoryPath.isEmpty) {
      setState(() {
        folderList = [];
        folders.clear();
      });
      return;
    }

    final Directory rootDir = Directory(directoryPath);

    if (!await rootDir.exists()) {
      throw DirectoryNotFoundException('Directory does not exist: ${rootDir.path}');
    }

    List<Map<String, String>> result = [];
    int totalRootFiles = 0;

    try {
      List<FileSystemEntity> entities = await rootDir.list().toList();

      for (var entity in entities) {
        if (entity is File) {
          totalRootFiles++;
        }
      }

      List<Directory> directories = entities.whereType<Directory>().toList();

      for (var directory in directories) {
        String folderName = path.basename(directory.path);
        int fileCount = 0;

        await for (var entity in directory.list()) {
          if (entity is File) {
            fileCount++;
          }
        }

        result.add({'name': folderName, 'files': '$fileCount files'});
      }

      setState(() {
        folderList = result;
        folders.clear();
        folders.addAll(result);
      });

      setState(() {
        anyFilesPresent = folders.isNotEmpty || totalRootFiles > 0;
      });

      debugPrint('Root directory contains $totalRootFiles files');
      for (var folder in result) {
        debugPrint('${folder['name']}: ${folder['files']}');
      }
    } catch (e) {
      throw Exception('Error scanning directories: $e');
    }
  }

  /// Performs cleanup when the widget is being removed from the widget tree.
  ///
  /// This method:
  /// - Cancels all file watchers in the [fileWatchers] list to stop monitoring file changes
  /// - Cancels the [directoryWatcher] if it exists to stop monitoring directory changes
  /// - Cancels the [pathSubscription] to stop listening for directory path updates
  /// - Calls the parent class's dispose method
  ///
  /// This cleanup is important to prevent memory leaks and ensure proper resource management
  /// by canceling any active stream subscriptions before the widget is disposed.
  @override
  void dispose() {
    searchBarController.removeListener(_filterDatasetFiles);
    for (var watcher in fileWatchers) {
      watcher.cancel();
    }
    directoryWatcher?.cancel();
    pathSubscription.cancel();
    super.dispose();
  }

  /// Builds the main content of the widget.
  ///
  /// This method constructs the UI elements that display the file explorer,
  /// dataset lists, and folder views. It conditionally renders different
  /// sections based on the presence of files and whether the explorer is
  /// visible.
  ///
  /// The UI includes:
  /// - A file explorer (if `isExplorerVisible` is true).
  /// - A scrollable list of datasets.
  /// - A search bar to filter datasets.
  /// - Buttons to upload new datasets or search public datasets.
  /// - A section to display folders and their contents.
  /// - A placeholder view if no files are present.
  ///
  /// The layout is designed to accommodate both small and large datasets,
  /// providing efficient scrolling and interaction.
  ///
  /// Args:
  /// - `context`: The BuildContext for the current location in the widget tree.
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (isExplorerVisible)
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedFolderForExplorer,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isExplorerVisible = false;
                            });
                          },
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.close),
                          constraints: BoxConstraints(),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FileExplorerView(
                      initialPath: path.join(selectedRootDirectoryPath, selectedFolderForExplorer),
                      onClose: () {
                        setState(() {
                          isExplorerVisible = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 35.0, top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (anyFilesPresent)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                                      dialogTitle: 'Select dataset(s)',
                                      allowMultiple: true,
                                      type: FileType.custom,
                                      allowedExtensions: ["json", "csv", "txt"],
                                      lockParentWindow: true,
                                    );
                                    if (result != null && result.files.isNotEmpty) {
                                      List<String> filePaths =
                                          result.files
                                              .where((file) => file.path != null)
                                              .map((file) => file.path!)
                                              .toList();

                                      if (filePaths.isNotEmpty) {
                                        for (String path in filePaths) {
                                          debugPrint('Selected file: $path');
                                        }

                                        try {
                                          List<String> newPaths = await FileTransferUtil.moveFiles(
                                            sourcePaths: filePaths,
                                            destinationDirectory: selectedRootDirectoryPath,
                                            overwriteExisting: false,
                                          );

                                          debugPrint('Files moved successfully to: $newPaths');
                                          scanForDatasetFiles(selectedRootDirectoryPath);
                                          setState(() {
                                            anyFilesPresent = true;
                                          });
                                        } catch (ex) {
                                          debugPrint('Cannot move files: $ex');
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    "Upload Dataset",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.blue.shade600, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    foregroundColor: Colors.blue.shade600,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    "Search Public Datasets",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () async {
                                    await _showSyncedDatasetsDialog(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.blue.shade600, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    foregroundColor: Colors.blue.shade600,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    "Import Synced Datasets with AWS",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed:
                                      _isSyncing
                                          ? null
                                          : () async {
                                            setState(() {
                                              _isSyncing = true;
                                            });

                                            try {
                                              await downloadAllFromCloud();
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  _isSyncing = false;
                                                });
                                              }
                                            }
                                          },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.blue.shade600, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    foregroundColor: Colors.blue.shade600,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isSyncing)
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.blue.shade600,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      if (_isSyncing) const SizedBox(width: 8),
                                      ValueListenableBuilder<Map<String, String>>(
                                        valueListenable: DownloadService().activeDownloads,
                                        builder: (context, downloads, child) {
                                          final downloadCount = downloads.length;
                                          return Text(
                                            _isSyncing
                                                ? downloadCount > 0
                                                    ? "Syncing ($downloadCount)"
                                                    : "Syncing..."
                                                : "Auto Sync",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            if (folders.isNotEmpty) _buildFoldersSection(),
                            _buildUploadedDatasetsList(),
                          ],
                        ),
                      if (!anyFilesPresent)
                        _buildPlaceholder(
                          onUploadClicked: () {
                            if (!isRootDirectorySelected) {
                              _showRootDirectoryDialog(context);
                            } else {
                              _uploadFiles();
                            }
                          },
                          onImportClicked: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar widget for filtering datasets.
  ///
  /// This widget is a `SizedBox` containing a `TextField` that allows users to
  /// search for files by name or type. It includes:
  /// - A fixed width of 300 pixels.
  /// - A `TextEditingController` to manage the text input.
  /// - An `InputDecoration` for visual styling, including:
  ///   - A hint text "Search files by name or type".
  ///   - A suffix icon for search (magnifying glass).
  ///   - An outline border with rounded corners.
  ///
  /// Returns a `SizedBox` containing the styled `TextField`.
  Widget _buildSearchBar() {
    return SizedBox(
      width: 300,
      child: TextField(
        style: TextStyle(),
        controller: searchBarController,
        decoration: InputDecoration(
          hintText: "Search files by name or type",
          suffixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
      ),
    );
  }

  /// Builds the list of uploaded datasets, including headers and file details.
  ///
  /// This widget displays a structured view of the uploaded datasets, with
  /// headers for file name, type, size, and modification time. It also
  /// includes interactive elements like icons for file operations and
  /// favorite-star toggling.
  Widget _buildUploadedDatasetsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filesMetaData = filteredDatasetFiles.map((file) => file.toMap()).toList();

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'Uploaded Datasets',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 10.0), child: _buildSearchBar()),
            ],
          ),

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
                    'Modified',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
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
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                  blurRadius: 2.0,
                  spreadRadius: 0.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child:
                filesMetaData.isEmpty
                    ? Center(
                      child: Text(
                        'No datasets found!',
                        style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    )
                    : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.depth == 0) {
                          return true;
                        }
                        return false;
                      },
                      child: AnimationLimiter(
                        child: ListView.separated(
                          physics: ClampingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: filesMetaData.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                height: 1,
                              ),
                          itemBuilder: (context, index) {
                            final fileData = filesMetaData[index];
                            debugPrint('$fileData');
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 16.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
                                      border:
                                          index == filesMetaData.length - 1
                                              ? Border(
                                                bottom: BorderSide(color: Colors.transparent),
                                              )
                                              : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getFileIcon(fileData['fileType'] ?? ''),
                                          size: 24,
                                          color: _getFileColor(fileData['fileType'] ?? ''),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            fileData['fileName'] ?? '',
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
                                            padding: EdgeInsets.only(top: 4.0, bottom: 4.0),
                                            decoration: BoxDecoration(
                                              color: _getFileColor(
                                                fileData['fileType'] ?? '',
                                              ).withValues(alpha: isDarkMode ? 0.2 : 0.1),
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Text(
                                              fileData['fileType'] ?? '',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: _getFileColor(fileData['fileType'] ?? ''),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            fileData['fileSize'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color:
                                                  isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            fileData['modified'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color:
                                                  isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 100.0),
                                            child: _buildSyncStatusIndicator(
                                              filesMetaData[index]['syncStatus'] ?? "NotSynced",
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            datasetFiles[index].isStarred
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 20,
                                            color:
                                                datasetFiles[index].isStarred
                                                    ? Colors.amber
                                                    : (isDarkMode ? Colors.grey[400] : null),
                                          ),
                                          onPressed: () {
                                            final index = datasetFiles.indexWhere(
                                              (file) => file.filePath == fileData['filePath'],
                                            );
                                            if (index != -1) {
                                              setState(() {
                                                datasetFiles[index].isStarred =
                                                    !datasetFiles[index].isStarred;
                                              });
                                              _saveStarredStatus(
                                                datasetFiles[index].filePath,
                                                datasetFiles[index].isStarred,
                                              );
                                            }
                                          },
                                          tooltip: "Add to favorites",
                                          splashRadius: 20,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.more_vert,
                                            size: 20,
                                            color: isDarkMode ? Colors.grey[400] : null,
                                          ),
                                          onPressed: () => _openFileDetails(datasetFiles[index]),
                                          tooltip: "More options",
                                          splashRadius: 20,
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
          ),
        ],
      ),
    );
  }

  /// Returns a widget that indicates the synchronization status.
  ///
  /// Depending on the given [status], it returns an icon with the corresponding
  /// color and tooltip text indicating the synchronization state (e.g., "Synced",
  /// "NotSynced"). The indicator also considers the current theme (dark/light)
  /// for proper color adjustments.
  Widget _buildSyncStatusIndicator(String status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    IconData iconData;
    Color iconColor;
    String tooltipText;

    switch (status) {
      case "Synced":
        iconData = Icons.cloud_done;
        iconColor = Colors.green;
        tooltipText = "Synced to cloud";
        break;
      case "Syncing":
        iconData = Icons.sync;
        iconColor = Colors.blue;
        tooltipText = "Syncing to cloud";
        break;
      case "Failed":
        iconData = Icons.cloud_off;
        iconColor = Colors.red;
        tooltipText = "Sync failed";
        break;
      case "NotSynced":
      default:
        iconData = Icons.cloud_upload_outlined;
        iconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
        tooltipText = "Not synced";
        break;
    }

    return Tooltip(message: tooltipText, child: Icon(iconData, color: iconColor, size: 20));
  }

  /// Opens a dialog to display detailed information about the selected file.
  ///
  /// This function is triggered when the user wants to view more details
  /// about a specific file, such as its size, type, modification date, and
  /// available actions.
  ///
  /// Args:
  ///   - `file`: The `DatasetFile` object containing the file's information.
  Future<void> _openFileDetails(DatasetFile file) async {
    showDialog(context: context, builder: (context) => _buildFileDetailsDialog(file));
  }

  Future<void> _showSyncedDatasetsDialog(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to access your synced datasets')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching your synced datasets...'),
            ],
          ),
        );
      },
    );

    try {
      final DatasetSyncManagementService syncService = DatasetSyncManagementService();
      final datasets = await syncService.getRecordedDatasets(userId: user.id);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;

      if (datasets['datasets'] == null || (datasets['datasets'] as List).isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Synced Datasets'),
              content: const Text('You don\'t have any datasets synced with the cloud.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
              ],
            );
          },
        );
        return;
      }

      await _showDatasetSelectionDialog(context, datasets['datasets'], user.id);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch synced datasets: ${e.toString()}'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
    }
  }

  /// Displays a dialog that allows the user to select a dataset from the available list.
  ///
  /// Retrieves the root directory path from Hive and verifies that it is properly set.
  /// If the root directory is not configured, it prompts the user via a snack bar.
  /// Otherwise, it presents a dialog with the dataset list for selection and import.
  ///
  /// Parameters:
  /// - [context]: The build context for displaying the dialog.
  /// - [datasets]: A list of dataset items to choose from.
  /// - [userId]: The unique identifier of the current user.
  ///
  /// Returns a [Future] that completes when the dialog is dismissed.
  Future<void> _showDatasetSelectionDialog(
    BuildContext context,
    List<dynamic> datasets,
    String userId,
  ) async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final rootDirectoryPath = hiveBox.get('selectedRootDirectoryPath');

    if (rootDirectoryPath == null || rootDirectoryPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a root directory in settings first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Your Synced Datasets'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: datasets.length,
                  itemBuilder: (context, index) {
                    final dataset = datasets[index];
                    final datasetName = dataset['dataset_name'] ?? 'Unnamed Dataset';
                    final isDownloading = _downloadingFiles.containsKey(datasetName);

                    return ListTile(
                      title: Text(datasetName),
                      subtitle: Text('Size: ${dataset['file_size'] ?? 'Unknown'}'),
                      trailing:
                          isDownloading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _downloadDataset(context, dataset, userId, rootDirectoryPath);
                                },
                              ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Downloads a dataset from the cloud.
  ///
  /// This function downloads the dataset specified in [dataset] and stores it in the
  /// directory provided by [rootDirectoryPath]. The [userId] is used to identify the
  /// current user for naming or authentication purposes.
  ///
  /// Parameters:
  /// - context: The BuildContext used for UI operations and dialogs.
  /// - dataset: A map containing dataset information such as 'dataset_name', 'file_size',
  ///   and 'file_type'.
  /// - userId: The identifier of the current user.
  /// - rootDirectoryPath: The path where the dataset file will be saved.
  ///
  /// Returns:
  /// A Future that completes when the download operation finishes.
  Future<void> _downloadDataset(
    BuildContext context,
    Map<String, dynamic> dataset,
    String userId,
    String rootDirectoryPath,
  ) async {
    final datasetName =
        dataset['dataset_name'] ?? 'dataset_${DateTime.now().millisecondsSinceEpoch}';
    final fileType = dataset['file_type'] ?? 'csv';

    String fileName = datasetName;
    String extension = fileType.toLowerCase();

    if (fileName.toLowerCase().endsWith('.$extension')) {
      fileName = fileName.substring(0, fileName.length - extension.length - 1);
    }

    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      fileName = fileName.substring(0, lastDotIndex);
    }

    final destinationPath = path.join(rootDirectoryPath, '$fileName.$extension');

    if (File(destinationPath).existsSync()) {
      debugPrint("$destinationPath already exists locally");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName.$extension already exists locally'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _openContainingFolder(destinationPath),
            ),
          ),
        );
      }
      DownloadService().completeDownload(datasetName);
      return;
    }

    final downloadService = DownloadService();
    downloadService.startDownload(datasetName, 'downloading');

    try {
      final syncService = DatasetSyncManagementService();
      final s3Path = dataset['s3_path'] ?? '';

      if (s3Path.isEmpty) {
        throw Exception('S3 path is missing from dataset information');
      }

      await syncService.downloadRecordedDataset(
        userId: userId,
        s3Path: s3Path,
        destinationPath: destinationPath,
      );

      downloadService.completeDownload(datasetName);

      await Future.delayed(const Duration(milliseconds: 500));
      await scanForDatasetFiles(rootDirectoryPath);
      await updateFilesSyncStatus();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded $fileName.$extension successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _openContainingFolder(destinationPath),
            ),
          ),
        );
      }
    } catch (e) {
      downloadService.completeDownload(datasetName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download $fileName.$extension: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Download error: $e');
    }
  }

  /// Downloads all synced datasets from the cloud to the local filesystem
  ///
  /// This function retrieves all datasets associated with the current user from the cloud,
  /// checks which ones don't exist locally, and downloads them to the root directory.
  /// It shows progress via the DownloadService and displays appropriate notifications.
  ///
  /// Side effects:
  /// - Updates the DownloadService with current download statuses
  /// - Creates local files in the root directory
  /// - Shows notifications about download progress
  Future<void> downloadAllFromCloud() async {
    final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
    final apiBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final userId = userBox.get('userId');
    final rootDirectoryPath = apiBox.get('selectedRootDirectoryPath');

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You need to be signed in to sync files')));
      }
      return;
    }

    if (rootDirectoryPath == null || rootDirectoryPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a root directory first')));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing to sync all files...')));
    }

    try {
      final datasetSyncService = DatasetSyncManagementService();
      final response = await datasetSyncService.getRecordedDatasets(userId: userId);
      final List<dynamic> cloudDatasets = response['datasets'] ?? [];

      if (cloudDatasets.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No synced datasets found in the cloud')));
        }
        return;
      }

      final List<Map<String, dynamic>> datasetsToDownload = [];
      for (var dataset in cloudDatasets) {
        final datasetName = dataset['dataset_name'];
        final fileType = dataset['file_type'] ?? 'csv';
        final s3Path = dataset['s3_path'];

        if (datasetName == null || s3Path == null) continue;

        String localFilePath = path.join(rootDirectoryPath, datasetName);
        if (!localFilePath.toLowerCase().endsWith('.$fileType')) {
          localFilePath = '$localFilePath.$fileType';
        }

        if (!File(localFilePath).existsSync()) {
          datasetsToDownload.add({
            'name': datasetName,
            's3_path': s3Path,
            'file_type': fileType,
            'destination_path': localFilePath,
          });
        }
      }

      if (datasetsToDownload.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All cloud datasets are already synced locally')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${datasetsToDownload.length} files...')),
        );
      }

      final downloadService = DownloadService();
      int successCount = 0;
      int failCount = 0;

      await Future.forEach(datasetsToDownload, (dataset) async {
        final datasetName = dataset['name'];
        final s3Path = dataset['s3_path'];
        final destinationPath = dataset['destination_path'];

        try {
          downloadService.startDownload(datasetName, 'downloading');

          await datasetSyncService.downloadRecordedDataset(
            userId: userId,
            s3Path: s3Path,
            destinationPath: destinationPath,
          );

          successCount++;
          downloadService.completeDownload(datasetName);
        } catch (e) {
          failCount++;
          downloadService.updateDownloadStatus(datasetName, 'failed');
          debugPrint('Failed to download $datasetName: $e');

          Future.delayed(const Duration(seconds: 2), () {
            downloadService.completeDownload(datasetName);
          });
        }
      });

      await scanForDatasetFiles(rootDirectoryPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync complete: $successCount downloaded, $failCount failed'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during bulk download: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: ${e.toString()}')));
      }
    }
  }

  /// Builds a dialog widget to display detailed information about a dataset file.
  ///
  /// This dialog shows file meta-data such as file name, type, size, and modified date.
  /// It is styled based on the current theme settings.
  ///
  /// Parameters:
  /// - file: The dataset file for which details are displayed.
  ///
  /// Returns:
  /// A [Widget] representing the file details dialog.
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
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
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

            _buildOptionButton(
              icon: Icons.download,
              label: "Import Dataset",
              onClick: () {
                _handleImportDataset(file.filePath);
                Navigator.pop(context);
              },
              isDarkMode: isDarkMode,
              color: Colors.blue.shade600,
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              icon: Icons.edit,
              label: "Rename Dataset",
              onClick: () {
                Navigator.pop(context);
                _handleRenameDataset(file.filePath);
              },
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              icon: Icons.delete,
              label: "Delete Dataset",
              onClick: () {
                Navigator.pop(context);
                _handleDeleteDataset(file.filePath);
              },
              isDarkMode: isDarkMode,
              color: Colors.red.shade600,
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              icon: Icons.cloud_upload,
              label: "Sync to Cloud",
              onClick: () {
                Navigator.pop(context);
                _handleSyncFile(file.filePath);
              },
              isDarkMode: isDarkMode,
              color: Colors.purple.shade600,
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
                    foregroundColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
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

  /// Checks if a file is already synced with cloud storage.
  ///
  /// Evaluates whether the file identified by its path (or unique identifier)
  /// has been successfully synchronized with the cloud.
  ///
  /// Returns `true` if the file is already synced; otherwise, returns `false`.
  Future<bool> _isFileAlreadySynced(String filePath) async {
    try {
      final file = datasetFiles.firstWhere((file) => file.filePath == filePath);
      final fileName = file.fileName;
      final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
      final userId = userBox.get('userId');

      if (userId == null) {
        debugPrint('Unable to check sync status: missing user ID');
        return false;
      }

      final response = await DatasetSyncManagementService().getRecordedDatasets(userId: userId);

      final List<dynamic> datasets = response['datasets'] ?? [];

      for (var dataset in datasets) {
        final String datasetName = dataset['dataset_name'] ?? '';
        if (datasetName == fileName) {
          debugPrint('This file is already synced to cloud => $fileName');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if file is synced: $e');
      return false;
    }
  }

  /// Handles syncing of a file with the cloud.
  ///
  /// This method initiates the cloud synchronization process for the file located at
  /// [filePath]. On successful sync, the file's sync status is updated accordingly.
  /// Any errors during the process are logged and handled appropriately.
  ///
  /// Parameters:
  /// - filePath: The local path of the file to be synced.
  void _handleSyncFile(String filePath) async {
    final file = datasetFiles.firstWhere((file) => file.filePath == filePath);
    final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
    final apiBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

    if (await _isFileAlreadySynced(filePath)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.fileName} is already synced to cloud'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      final index = datasetFiles.indexWhere((f) => f.filePath == filePath);
      if (index != -1) {
        datasetFiles[index].syncStatus = "Syncing";
      }
    });

    try {
      final accessKey = apiBox.get('aws_access_key');
      final secretKey = apiBox.get('aws_secret_key');
      final region = apiBox.get('aws_region');
      final bucketName = apiBox.get('aws_bucket');
      final userId = userBox.get('userId') ?? 'unknown_user';

      if (accessKey.isEmpty || secretKey.isEmpty || bucketName.isEmpty) {
        throw Exception('Missing AWS credentials');
      }

      // Use the service to upload the file
      final awsService = AWSS3OperationService();
      final responseData = await awsService.uploadDataset(
        file: File(filePath),
        userId: userId,
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        bucketName: bucketName,
      );

      setState(() {
        final index = datasetFiles.indexWhere((f) => f.filePath == filePath);
        if (index != -1) {
          datasetFiles[index].syncStatus = "Synced";
        }
      });

      updateFilesSyncStatus();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.fileName} has been synced to cloud'),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('File synced successfully: ${responseData['file_url']}');
    } catch (e) {
      debugPrint('Error syncing file: $e');

      setState(() {
        final index = datasetFiles.indexWhere((f) => f.filePath == filePath);
        if (index != -1) {
          datasetFiles[index].syncStatus = "Failed";
        }
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync ${file.fileName}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Retrieves the list of datasets synced to S3 and updates the sync status
  /// of local files.
  ///
  /// This function fetches a list of datasets that have been previously synced
  /// to S3 from the server API, then updates the sync status of matching local
  /// files in the [datasetFiles] list. It compares the file names to determine
  /// which files have been synced.
  ///
  /// The function handles various error cases including network issues and
  /// authentication problems, and ensures the UI is updated with the latest
  /// sync status information.
  Future<void> updateFilesSyncStatus() async {
    try {
      final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);

      final userId = userBox.get('userId');
      final baseUrl = dotenv.env['DEV_BASE_URL']!;

      if (userId == null) {
        debugPrint('Unable to update sync status: missing user credentials');
        return;
      }

      final url = Uri.parse(
        '$baseUrl/api/aws/s3/get-recorded-datasets',
      ).replace(queryParameters: {'user_id': userId.toString()});

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> datasets = data['datasets'] ?? [];

        if (datasets.isEmpty) {
          debugPrint('No synced datasets found for user $userId');
          return;
        }

        final Map<String, String> syncedFiles = {};

        for (var dataset in datasets) {
          final String datasetName = dataset['dataset_name'] ?? '';
          if (datasetName.isNotEmpty) {
            syncedFiles[datasetName] = "Synced";
          }
        }

        if (mounted) {
          setState(() {
            for (int i = 0; i < datasetFiles.length; i++) {
              String baseName = datasetFiles[i].fileName;
              // I had to make this temp fix, cuz I didn't figure out the root case for .csv.csv
              int firstDotIndex = baseName.indexOf('.');
              if (firstDotIndex != -1) {
                baseName = baseName.substring(0, firstDotIndex);
              }

              bool found = false;
              syncedFiles.forEach((key, value) {
                String cleanKey = key;
                int keyDotIndex = cleanKey.indexOf('.');
                if (keyDotIndex != -1) {
                  cleanKey = cleanKey.substring(0, keyDotIndex);
                }

                if (cleanKey == baseName) {
                  datasetFiles[i].syncStatus = "Synced";
                  found = true;
                }
              });

              if (!found && datasetFiles[i].syncStatus != "Syncing") {
                datasetFiles[i].syncStatus = "NotSynced";
              }
            }
            _filterDatasetFiles();
          });
        }

        debugPrint('Successfully updated sync status for ${syncedFiles.length} files');
      } else {
        debugPrint('Failed to fetch synced datasets. Status code: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating sync status: $e');
    }
  }

  /// Builds a widget for displaying a file information item.
  ///
  /// This widget displays a file information row containing a label and its corresponding
  /// value with styling that adapts to the current theme mode.
  ///
  /// Parameters:
  /// - `label`: A String representing the label for the file info (e.g., "Type", "Size").
  /// - `value`: A String representing the value displayed next to the label.
  /// - `isDarkMode`: A bool indicating whether the dark theme is enabled.
  ///
  /// Returns:
  /// A Widget that shows the file info item.
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
              style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an option button for file operations.
  ///
  /// This widget displays an icon and a text label, and triggers the provided [onClick]
  /// callback when pressed. Its appearance is adjusted based on [isDarkMode] and an optional [color].
  ///
  /// Parameters:
  /// - icon: The icon to display on the button.
  /// - label: The text label for the button.
  /// - onClick: The callback to invoke when the button is tapped.
  /// - isDarkMode: A boolean flag to determine the style for dark mode.
  /// - color: An optional color to customize the appearance.
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Function onClick,
    required bool isDarkMode,
    Color? color,
  }) {
    return InkWell(
      onTap: () => onClick(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color ?? (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the containing folder of a specified file in the system's file explorer.
  ///
  /// This function determines the operating system and uses the appropriate
  /// command to open the directory where the file resides. It supports Windows,
  /// macOS, and Linux. If the platform is not supported, it prints an error message.
  /// It also logs the directory path being opened or any errors encountered.
  ///
  /// Args:
  ///   - `filePath`: The path to the file whose containing folder needs to be opened.
  ///
  /// Side Effects:
  ///   - Opens a new window in the system's file explorer.
  Future<void> _openContainingFolder(String filePath) async {
    final directory = path.dirname(filePath);
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', [directory]);
      } else if (Platform.isMacOS) {
        Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [directory]);
      } else {
        debugPrint('Platform not supported for opening folders');
      }
      debugPrint('Opening folder: $directory');
    } catch (e) {
      debugPrint('Error opening folder: $e');
    }
  }

  /// Opens a specified file in the system's default application for that file type.
  ///
  /// This function determines the operating system and uses the appropriate
  /// command to open the file. It supports Windows, macOS, and Linux. If the
  /// platform is not supported, it prints an error message. It also logs the
  /// file path being opened or any errors encountered.
  ///
  /// Args:
  ///   - `filePath`: The path to the file that needs to be opened.
  ///
  /// Side Effects:
  ///   - Opens the file in the default application associated with its type.
  Future<void> _openFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', [filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [filePath]);
      } else {
        debugPrint('Platform not supported for opening files');
      }
      debugPrint('Opening file: $filePath');
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  /// Handles the import of a dataset, updating recent import history and navigating to the Data View screen.
  ///
  /// This function performs the following actions:
  /// 1. Retrieves the dataset file information from the `datasetFiles` list based on the given `filePath`.
  /// 2. Prints a debug message indicating which dataset is being imported.
  /// 3. Manages the recent import history stored in the `recentImportsBox`:
  ///    - If there are existing imports, it retrieves them, ensuring the data type is correct.
  ///    - Creates a new `RecentImportsModel` instance with details of the current import.
  ///    - Inserts the new import at the beginning of the list.
  ///    - Limits the number of recent imports to 10, removing the oldest if necessary.
  /// 4. Updates the `recentImportsBox` with the modified list of recent imports.
  /// 5. Updates the `recentImportsBox` with information about the currently selected dataset, including its name, path, and type.
  /// 6. If a navigation callback (`widget.onNavigate`) is provided, it calls this callback with the index `3`,
  ///    which is intended to navigate to the Data View screen.
  ///
  /// Args:
  ///   - `filePath`: The path to the dataset file being imported.
  ///
  /// Throws:
  ///   - If no file matches the provided path or if there is an error during data storage.
  ///
  /// Side Effects:
  ///   - Updates the recent imports list in the `recentImportsBox`.
  ///   - Stores current dataset details in the `recentImportsBox`.
  ///   - May trigger navigation to another screen via `widget.onNavigate`.
  ///
  /// Returns:
  ///   - `void`
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

    recentImports.removeWhere((import) => import.filePath == file.filePath);

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

    if (widget.onNavigate != null) {
      widget.onNavigate!(3);
    }
  }

  /// Handles the renaming of a dataset file.
  ///
  /// This function is called when a user initiates a rename operation for a
  /// dataset. It performs the following steps:
  /// 1. Finds the `DatasetFile` object corresponding to the provided `filePath`.
  /// 2. Creates a `TextEditingController` initialized with the current file name.
  /// 3. Displays a dialog with a text field for the user to enter a new file name.
  /// 4. Validates that the new name is not empty and is different from the current name.
  /// 5. Appends the original file extension to the new name if it's missing.
  /// 6. Constructs the full new file path.
  /// 7. Renames the file using the `File.rename()` method.
  /// 8. Updates the starred file path using `updateStarredFilePath`.
  /// 9. Rescans the directory to refresh the file list with the new name.
  /// 10. Shows an error snackbar if any exceptions are thrown during the process.
  ///
  /// Args:
  ///   - `filePath`: The path to the dataset file to be renamed.
  ///
  void _handleRenameDataset(String filePath) {
    final file = datasetFiles.firstWhere((file) => file.filePath == filePath);

    TextEditingController renameController = TextEditingController(text: file.fileName);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rename Dataset'),
            content: TextField(
              controller: renameController,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Enter new name', border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (renameController.text.isNotEmpty && renameController.text != file.fileName) {
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Failed to rename file: $e')));
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
  /// This function is called when a user initiates a delete operation for a
  /// dataset. It performs the following steps:
  /// 1. Finds the `DatasetFile` object corresponding to the provided `filePath`.
  /// 2. Displays an alert dialog to confirm the deletion with the user.
  /// 3. If confirmed, deletes the file from the file system.
  /// 4. If the file is starred, removes it from the `starredBox`.
  /// 5. Rescans the directory to refresh the file list.
  /// 6. Displays a snackbar with an error message if the deletion fails.
  /// 7. Closes the dialog after the deletion or on error.
  ///
  /// Args:
  ///   - `filePath`: The path to the dataset file to be deleted.
  ///
  /// Returns:
  ///   - `void`
  ///
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
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed to delete file: $e')));
                    Navigator.pop(context);
                  }
                },
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  /// Saves the starred status of a file in the `starredBox`.
  ///
  /// This function is responsible for managing the starred status of a file.
  /// It does the following:
  /// 1. Stores the `isStarred` status of the file using the `filePath` as a key.
  /// 2. If `isStarred` is false, it ensures the file is removed from the box.
  ///
  /// Args:
  ///   - `filePath`: The path to the file whose starred status is being saved.
  ///   - `isStarred`: A boolean indicating whether the file should be starred or not.
  ///
  /// Throws:
  ///   - Any exception that `starredBox.put` or `starredBox.delete` may throw.
  ///
  /// Side Effects:
  ///   - Modifies the contents of the `starredBox` Hive box.
  ///
  /// Returns:
  ///   - `Future<void>`
  Future<void> _saveStarredStatus(String filePath, bool isStarred) async {
    await starredBox.put(filePath, isStarred);
    if (!isStarred) {
      await starredBox.delete(filePath);
    }
  }

  /// Loads the starred status of a file from the `starredBox`.
  ///
  /// This function is used to retrieve the starred status of a file.
  /// It uses the `filePath` as the key to look up the file's status in the `starredBox`.
  /// If the file is not found, it defaults to `false`.
  ///
  /// Args:
  ///   - `filePath`: The path to the file whose starred status is being retrieved.
  ///
  /// Returns:
  ///   - `Future<bool>`: `true` if the file is starred, `false` otherwise.
  Future<bool> _loadStarredStatus(String filePath) async {
    return starredBox.get(filePath, defaultValue: false);
  }

  /// Updates the starred file path in the `starredBox` when a file is renamed.
  ///
  /// This function handles the process of updating the starred status for a file
  /// that has been renamed. It does the following:
  /// 1. Checks if the file was starred before it was renamed by loading its starred status
  ///    using the `oldPath`.
  /// 2. If the file was starred, it removes the old entry using `oldPath` as the key and
  ///    creates a new entry with `newPath` as the key and `true` as the value.
  ///
  /// Args:
  ///   - `oldPath`: The original file path before renaming.
  ///   - `newPath`: The new file path after renaming.
  ///
  /// Side Effects:
  ///   - Modifies the contents of the `starredBox` Hive box.
  Future<void> updateStarredFilePath(String oldPath, String newPath) async {
    bool wasTheFileStarredBefore = await _loadStarredStatus(oldPath);
    if (wasTheFileStarredBefore) {
      await starredBox.delete(oldPath);
      await starredBox.put(newPath, true);
    }
  }

  /// Returns the appropriate icon data based on the given [fileType].
  ///
  /// This function determines which icon to display based on the file type
  /// extension. It maps common data file types (CSV, JSON, XLSX) to specific
  /// Material Icons. If the file type is not recognized, it returns a generic
  /// file icon.
  ///
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

  /// Returns the appropriate color based on the given [fileType].
  ///
  /// This function determines which color to use based on the file type
  /// extension. It maps common data file types (CSV, JSON, XLSX) to specific
  /// colors. If the file type is not recognized, it returns a default grey
  /// color.
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

  /// Builds the section of the UI that displays a list of folders.
  ///
  /// This widget creates a horizontal list of folder cards, each representing
  /// a subfolder within the root directory. It allows users to scroll through
  /// the folders and select one to view its contents. The UI adapts to the
  /// current theme (light/dark).
  ///
  Widget _buildFoldersSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ScrollController folderScrollController = ScrollController();

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Text(
                  'Folders',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 180,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollStartNotification ||
                      scrollNotification is ScrollUpdateNotification ||
                      scrollNotification is ScrollEndNotification) {
                    return true;
                  }
                  return false;
                },
                child: Scrollbar(
                  controller: folderScrollController,
                  thickness: 6,
                  radius: const Radius.circular(8),
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: folderScrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                        child: SizedBox(
                          width: 280,
                          child: _buildFolderCard(folders[index], isDarkMode, index),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an individual card representing a folder.
  ///
  /// This function constructs a UI element that displays a folder's name and
  /// file count, and includes a button to open the folder in the file
  /// explorer. The card's appearance changes based on whether the app is in
  /// dark mode or not.
  ///
  /// Args:
  ///   - `folder`: A map containing folder details, including 'name' and 'files'.
  ///   - `isDarkMode`: A boolean indicating whether dark mode is enabled.
  Widget _buildFolderCard(Map<String, String> folder, bool isDarkMode, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoveredFolderIndex = index),
      onExit: (_) => setState(() => hoveredFolderIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform:
            hoveredFolderIndex == index ? Matrix4.translationValues(0, -5, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2A2D37) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!, width: 1.0),
          boxShadow: [
            BoxShadow(
              color:
                  hoveredFolderIndex == index
                      ? (isDarkMode
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.1))
                      : (isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05)),
              blurRadius: hoveredFolderIndex == index ? 8.0 : 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF3A3E4A) : Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(Icons.folder, color: Colors.blue[400], size: 24.0),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          folder['files']!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  openFileExplorer(folder['name']!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Color(0xFF3A3E4A) : Colors.white,
                  foregroundColor: isDarkMode ? Colors.white : Colors.blue[700],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Open"),
                    SizedBox(width: 4.0),
                    Icon(Icons.arrow_forward, size: 16.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the file explorer for a specific folder.
  ///
  /// This function displays a dialog that presents a file explorer view,
  /// allowing users to interact with the files and subfolders within the
  /// specified folder.
  ///
  /// Args:
  ///   - `folderName`: The name of the folder to open in the file explorer.
  void openFileExplorer(String folderName) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.all(32),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              child: FileExplorerView(
                initialPath: path.join(selectedRootDirectoryPath, folderName),
                onClose: () => Navigator.pop(context),
              ),
            ),
          ),
    );
  }

  /// Builds a placeholder widget for when there are no files in the directory.
  ///
  /// This function creates a visual placeholder indicating that the current
  /// directory is empty. It includes text prompting the user to upload files
  /// and two action buttons: one for uploading files and another for importing
  /// from Kaggle.
  ///
  /// Args:
  ///   - `onUploadClicked`: A callback function to execute when the "Upload File(s)" button is clicked.
  ///   - `onImportClicked`: A callback function to execute when the "Import from Kaggle" button is clicked.
  ///
  /// Returns: A `Widget` representing the placeholder interface.
  Widget _buildPlaceholder({
    required Function() onUploadClicked,
    required Function() onImportClicked,
  }) {
    return Column(
      children: [
        const Text('No Files Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26.0)),
        const Text('This folder is empty. Upload files to get started with your data analysis.'),
        const SizedBox(height: 18.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onUploadClicked,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Upload File(s)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 15.0),
            OutlinedButton(
              onPressed: onImportClicked,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade600, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                foregroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                "Import from Kaggle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 15.0),
            OutlinedButton(
              onPressed: () async {
                await _showSyncedDatasetsDialog(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade600, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                foregroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                "Import Synced Datasets with AWS",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 15.0),
            OutlinedButton(
              onPressed:
                  _isSyncing
                      ? null
                      : () async {
                        setState(() {
                          _isSyncing = true;
                        });

                        try {
                          await downloadAllFromCloud();
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSyncing = false;
                            });
                          }
                        }
                      },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade600, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                foregroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSyncing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.blue.shade600, strokeWidth: 2),
                    ),
                  if (_isSyncing) const SizedBox(width: 8),
                  ValueListenableBuilder<Map<String, String>>(
                    valueListenable: DownloadService().activeDownloads,
                    builder: (context, downloads, child) {
                      final downloadCount = downloads.length;
                      return Text(
                        _isSyncing
                            ? downloadCount > 0
                                ? "Syncing ($downloadCount)"
                                : "Syncing..."
                            : "Auto Sync",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Displays a dialog to select the root directory for datasets.
  ///
  /// This function creates and shows a modal dialog that allows the user to
  /// choose a root directory for their datasets. It includes:
  /// - A title and description explaining the purpose of the directory.
  /// - A field to display the currently selected directory.
  /// - A button to browse and select a new directory.
  /// - Buttons to confirm the selection or cancel.
  ///
  /// Args: `context`: The `BuildContext` for the dialog.
  void _showRootDirectoryDialog(BuildContext context) {
    final isDarkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 600,
                height: MediaQuery.of(context).size.height - 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey
                                        : Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.folder_open, size: 17.0),
                              ),
                            ),
                          ),
                          const Text(
                            'Select root directory for datasets',
                            style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Choose a location where all your datasets will be stored. This directory will serve as the base for all dataset operations',
                            maxLines: 2,
                            softWrap: true,
                            style: TextStyle(fontSize: 17.0),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedRootDirectoryPath.isEmpty
                                              ? "No path selected"
                                              : selectedRootDirectoryPath,
                                          style: TextStyle(
                                            color:
                                                isDarkModeEnabled
                                                    ? Colors.grey[400]
                                                    : Colors.grey[500],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () async {
                                            String? selectedDir = await FilePicker.platform
                                                .getDirectoryPath(
                                                  dialogTitle: 'Select root directory for datasets',
                                                );
                                            if (selectedDir != null) {
                                              setDialogState(() {
                                                selectedRootDirectoryPath = selectedDir;
                                              });

                                              setState(() {
                                                selectedRootDirectoryPath = selectedDir;
                                                isRootDirectorySelected = true;
                                              });

                                              final hiveBox = Hive.box(
                                                dotenv.env['API_HIVE_BOX_NAME']!,
                                              );
                                              await hiveBox.put(
                                                'selectedRootDirectoryPath',
                                                selectedDir,
                                              );
                                            }
                                          },
                                          child: Icon(
                                            Icons.folder_open_outlined,
                                            color: isDarkModeEnabled ? Colors.white : Colors.black,
                                            size: 18.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    selectedRootDirectoryPath.isEmpty
                                        ? null
                                        : () {
                                          Navigator.of(dialogContext).pop();
                                          _uploadFiles();
                                        },
                                child: Text('Confirm'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Handles the process of uploading files to the selected root directory.
  ///
  /// This function allows the user to pick multiple files using a file picker
  /// and then moves those files to the designated root directory. It also
  /// handles the creation of the root directory if it does not exist.
  /// The function updates the UI to reflect the new file uploads
  ///
  /// It updates the anyFilesPresent
  void _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ["json", "csv", "txt"],
        dialogTitle: 'Select datasets to upload',
      );

      if (result != null && result.files.isNotEmpty) {
        List<String> sourcePaths =
            result.paths.where((path) => path != null).map((path) => path!).toList();
        debugPrint('Source paths to move: $sourcePaths');
        debugPrint('Destination directory: $selectedRootDirectoryPath');

        if (sourcePaths.isNotEmpty) {
          try {
            final destDir = Directory(selectedRootDirectoryPath);
            if (!await destDir.exists()) {
              await destDir.create(recursive: true);
              debugPrint('Created destination directory: $selectedRootDirectoryPath');
            }

            List<String> newPaths = await FileTransferUtil.moveFiles(
              sourcePaths: sourcePaths,
              destinationDirectory: selectedRootDirectoryPath,
              overwriteExisting: false,
            );

            if (newPaths.isNotEmpty) {
              debugPrint('Files moved successfully to: $newPaths');
              scanForDatasetFiles(selectedRootDirectoryPath);
              setState(() {
                anyFilesPresent = true;
              });
            } else {
              debugPrint('No files were moved successfully');
            }
          } catch (ex) {
            debugPrint('Error moving files: $ex');
          }
        }
      } else {
        debugPrint('No files selected or picker was canceled');
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }
}

/// Custom exception to indicate that a specified directory was not found.
///
/// This exception is thrown when a function or method attempts to access a
/// directory that does not exist. It includes a detailed error message to help
/// diagnose the issue.
class DirectoryNotFoundException implements Exception {
  /// The detailed error message describing the missing directory.
  final String message;

  /// Creates a `DirectoryNotFoundException` with the given error [message].
  DirectoryNotFoundException(this.message);

  /// Returns a string representation of this exception, which is the error [message].
  @override
  String toString() => message;
}
