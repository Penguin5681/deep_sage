import 'dart:async';
import 'dart:io';

import 'package:deep_sage/core/config/helpers/file_transfer_util.dart';
import 'package:deep_sage/core/models/dataset_file.dart';
import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/services/directory_path_service.dart';
import 'package:deep_sage/views/core_screens/explorer/file_explorer_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import 'package:path/path.dart' as path;

class FolderAll extends StatefulWidget {
  final Function(int)? onNavigate;

  const FolderAll({super.key, required this.onNavigate});

  @override
  State<FolderAll> createState() => _FolderAllState();
}

class _FolderAllState extends State<FolderAll> {
  final TextEditingController searchBarController = TextEditingController();
  final Box starredBox = Hive.box('starred_datasets');
  final Box hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);
  final List<Map<String, String>> folders = [];

  late bool anyFilesPresent = true;
  late bool isRootDirectorySelected = false;
  late String selectedRootDirectoryPath = '';
  late String rootDirectory = hiveBox.get('selectedRootDirectoryPath') ?? '';
  late List<Map<String, String>> folderList = [];
  late StreamSubscription<String> pathSubscription;

  StreamSubscription<FileSystemEvent>? directoryWatcher;
  bool isExplorerVisible = false;
  String selectedFolderForExplorer = '';
  List<DatasetFile> datasetFiles = [];
  List<StreamSubscription<FileSystemEvent>> fileWatchers = [];
  Set<String> watchedDirectories = {};

  @override
  void initState() {
    super.initState();
    _loadRootDirectoryPath().then((_) {
      if (selectedRootDirectoryPath.isNotEmpty) {
        getDirectoryFileCounts(selectedRootDirectoryPath);
        setupDirectoryWatcher(selectedRootDirectoryPath);
        scanForDatasetFiles(selectedRootDirectoryPath);
      }
    });

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

  Future<void> _scanDirectory(
    String directoryPath,
    List<DatasetFile> files,
  ) async {
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
          if (['.json', '.csv', '.xlsx', '.xls'].contains(extension)) {
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

  void setupDirectoryWatcher(String dirPath) {
    directoryWatcher?.cancel();

    if (dirPath.isEmpty) return;

    try {
      directoryWatcher = Directory(dirPath).watch(recursive: true).listen((
        event,
      ) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            getDirectoryFileCounts(dirPath);
            scanForDatasetFiles(dirPath);
            debugPrint(
              'Something happened in the root: ${event.path} - ${event.type}',
            );
          }
        });
      });
    } catch (ex) {
      debugPrint('setupDirectoryWatcher(): $ex');
    }
  }

  void setupFileWatcher(String directoryPath) {
    try {
      final subscription = Directory(
        directoryPath,
      ).watch(recursive: true).listen((event) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            final filePath = event.path;
            final extension = path.extension(filePath).toLowerCase();

            if ([".json", ".csv", ".xlsx", ".xls"].contains(extension)) {
              scanForDatasetFiles(selectedRootDirectoryPath);
              debugPrint(
                'Something happened to your file niga: ${event.path} - ${event.type}',
              );
            } else if (event.type == FileSystemEvent.create &&
                Directory(event.path).existsSync()) {
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
      throw DirectoryNotFoundException(
        'Directory does not exist: ${rootDir.path}',
      );
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

  @override
  void dispose() {
    for (var watcher in fileWatchers) {
      watcher.cancel();
    }
    directoryWatcher?.cancel();
    pathSubscription.cancel();
    super.dispose();
  }

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
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
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
                      initialPath: path.join(
                        selectedRootDirectoryPath,
                        selectedFolderForExplorer,
                      ),
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
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
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
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 20.0,
                              ),
                              child: _buildSearchBar(),
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    FilePickerResult? result = await FilePicker
                                        .platform
                                        .pickFiles(
                                          dialogTitle: 'Select dataset(s)',
                                          allowMultiple: true,
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            "json",
                                            "csv",
                                            "txt"
                                          ],
                                          lockParentWindow: true,
                                        );
                                    if (result != null &&
                                        result.files.isNotEmpty) {
                                      List<String> filePaths =
                                          result.files
                                              .where(
                                                (file) => file.path != null,
                                              )
                                              .map((file) => file.path!)
                                              .toList();

                                      if (filePaths.isNotEmpty) {
                                        for (String path in filePaths) {
                                          debugPrint('Selected file: $path');
                                        }

                                        try {
                                          List<String> newPaths =
                                              await FileTransferUtil.moveFiles(
                                                sourcePaths: filePaths,
                                                destinationDirectory:
                                                    selectedRootDirectoryPath,
                                                overwriteExisting: false,
                                              );

                                          debugPrint(
                                            'Files moved successfully to: $newPaths',
                                          );
                                          scanForDatasetFiles(
                                            selectedRootDirectoryPath,
                                          );
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.blue.shade600,
                                      width: 2,
                                    ),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  Widget _buildUploadedDatasetsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filesMetaData = datasetFiles.map((file) => file.toMap()).toList();

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Uploaded Datasets',
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
                filesMetaData.isEmpty
                    ? Center(
                      child: Text(
                        'No datasets found!',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    )
                    : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.depth == 0) {
                          return true;
                        }
                        return false;
                      },
                      child: ListView.separated(
                        physics: ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: filesMetaData.length,
                        separatorBuilder:
                            (context, index) => Divider(
                              color:
                                  isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                              height: 1,
                            ),
                        itemBuilder: (context, index) {
                          final fileData = filesMetaData[index];
                          debugPrint('$fileData');
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Color(0xFF1F222A) : Colors.white,
                              border:
                                  index == filesMetaData.length - 1
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
                                  _getFileIcon(fileData['fileType'] ?? ''),
                                  size: 24,
                                  color: _getFileColor(
                                    fileData['fileType'] ?? '',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    fileData['fileName'] ?? '',
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
                                        fileData['fileType'] ?? '',
                                      ).withValues(
                                        alpha: isDarkMode ? 0.2 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      fileData['fileType'] ?? '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: _getFileColor(
                                          fileData['fileType'] ?? '',
                                        ),
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
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
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
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
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
                                            : (isDarkMode
                                                ? Colors.grey[400]
                                                : null),
                                  ),
                                  onPressed: () {
                                    final index = datasetFiles.indexWhere(
                                      (file) =>
                                          file.filePath == fileData['filePath'],
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
                                  onPressed:
                                      () =>
                                          _openFileDetails(datasetFiles[index]),
                                  tooltip: "More options",
                                  splashRadius: 20,
                                ),
                              ],
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

  Future<void> _openFileDetails(DatasetFile file) async {
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
              color:
                  color ?? (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
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

  void _handleImportDataset(String filePath) async {
    // todo: i will have to manage an onNavigate type function for folder_all and visualization screen
    // alr, what plan do we have here?
    // imma make a section called, recent imports or history, i think history looks pretty odd
    // since we are not immediately performing any operations on data
    // imma save this as an hive object
    // i need to create an hive model first
    // what fields to include?? file name, file path, time of import
    // gotta make sure that this shit is backwards compatible
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

    if (widget.onNavigate != null) {
      widget.onNavigate!(3);
    }
  }

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

  Future<void> _saveStarredStatus(String filePath, bool isStarred) async {
    await starredBox.put(filePath, isStarred);
    if (!isStarred) {
      await starredBox.delete(filePath);
    }
  }

  Future<bool> _loadStarredStatus(String filePath) async {
    return starredBox.get(filePath, defaultValue: false);
  }

  Future<void> updateStarredFilePath(String oldPath, String newPath) async {
    bool wasTheFileStarredBefore = await _loadStarredStatus(oldPath);
    if (wasTheFileStarredBefore) {
      await starredBox.delete(oldPath);
      await starredBox.put(newPath, true);
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
                        padding: const EdgeInsets.only(
                          right: 16.0,
                          bottom: 8.0,
                        ),
                        child: SizedBox(
                          width: 280,
                          child: _buildFolderCard(folders[index], isDarkMode),
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

  Widget _buildFolderCard(Map<String, String> folder, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2A2D37) : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.0,
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
                  child: Icon(
                    Icons.folder,
                    color: Colors.blue[400],
                    size: 24.0,
                  ),
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
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
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
    );
  }

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

  Widget _buildPlaceholder({
    required Function() onUploadClicked,
    required Function() onImportClicked,
  }) {
    return Column(
      children: [
        const Text(
          'No Files Yet',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26.0),
        ),
        const Text(
          'This folder is empty. Upload files to get started with your data analysis.',
        ),
        const SizedBox(height: 18.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onUploadClicked,
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
                "Import from Kaggle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

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
                                    Theme.of(context).brightness ==
                                            Brightness.dark
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
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                            ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color:
                                        isDarkModeEnabled
                                            ? Colors.grey[800]
                                            : Colors.grey[100],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            String?
                                            selectedDir = await FilePicker
                                                .platform
                                                .getDirectoryPath(
                                                  dialogTitle:
                                                      'Select root directory for datasets',
                                                );
                                            if (selectedDir != null) {
                                              setDialogState(() {
                                                selectedRootDirectoryPath =
                                                    selectedDir;
                                              });

                                              setState(() {
                                                selectedRootDirectoryPath =
                                                    selectedDir;
                                                isRootDirectorySelected = true;
                                              });

                                              final hiveBox = Hive.box(
                                                dotenv
                                                    .env['API_HIVE_BOX_NAME']!,
                                              );
                                              await hiveBox.put(
                                                'selectedRootDirectoryPath',
                                                selectedDir,
                                              );
                                            }
                                          },
                                          child: Icon(
                                            Icons.folder_open_outlined,
                                            color:
                                                isDarkModeEnabled
                                                    ? Colors.white
                                                    : Colors.black,
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
            result.paths
                .where((path) => path != null)
                .map((path) => path!)
                .toList();
        debugPrint('Source paths to move: $sourcePaths');
        debugPrint('Destination directory: $selectedRootDirectoryPath');

        if (sourcePaths.isNotEmpty) {
          try {
            final destDir = Directory(selectedRootDirectoryPath);
            if (!await destDir.exists()) {
              await destDir.create(recursive: true);
              debugPrint(
                'Created destination directory: $selectedRootDirectoryPath',
              );
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

class DirectoryNotFoundException implements Exception {
  final String message;

  DirectoryNotFoundException(this.message);

  @override
  String toString() => message;
}
