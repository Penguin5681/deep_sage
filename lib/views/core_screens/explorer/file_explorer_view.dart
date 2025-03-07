import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class FileExplorerView extends StatefulWidget {
  final String initialPath;
  final VoidCallback onClose;

  const FileExplorerView({super.key, required this.initialPath, required this.onClose});

  @override
  State<FileExplorerView> createState() => _FileExplorerViewState();
}

class _FileExplorerViewState extends State<FileExplorerView> {
  String currentPath = '';
  String selectedFilePath = '';
  double splitPosition = 0.3;
  List<FileSystemEntity> folderContents = [];
  List<FileSystemEntity> directoryList = [];
  List<FileSystemEntity> filteredContents = [];

  final List<String> allowedExtensions = ['json', 'csv', 'xlsx', 'xls'];

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
    loadDirectoryContents(currentPath);
    buildDirectoryTree(widget.initialPath);
  }

  Future<void> loadDirectoryContents(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      final contents = await dir.list().toList();

      setState(() {
        currentPath = dirPath;
        folderContents = contents;
        filterContents();
      });
    } catch (ex) {
      if (kDebugMode) {
        debugPrint('loadDirectoryContents(): Something went wrong => $ex');
      }
    }
  }

  void filterContents() {
    filteredContents =
        folderContents.where((entity) {
          if (entity is Directory) return true;

          if (entity is File) {
            final extension = path.extension(entity.path).toLowerCase();
            return allowedExtensions.contains(extension.replaceAll('.', ''));
          }
          return false;
        }).toList();
  }

  Future<void> buildDirectoryTree(String rootPath) async {
    try {
      final rootDir = Directory(rootPath);
      final entities = await rootDir.list().toList();

      setState(() {
        directoryList = entities.whereType<Directory>().toList();
      });
    } catch (ex) {
      if (kDebugMode) {
        debugPrint('buildDirectoryTree(): Something went wrong => $ex');
      }
    }
  }

  Widget buildFileTypeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).cardColor.withValues(alpha: 0.4),
      child: Row(
        children: [
          Text("Showing: ", style: TextStyle(fontSize: 12)),
          buildFileTypeBadge("JSON", Colors.orange),
          const SizedBox(width: 6),
          buildFileTypeBadge("CSV", Colors.green),
          const SizedBox(width: 6),
          buildFileTypeBadge("Excel", Colors.blue),
        ],
      ),
    );
  }

  Widget buildFileTypeBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8.0, spreadRadius: 1.0)],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('File Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          // Breadcrumb
          _buildBreadcrumb(),
          buildFileTypeFilter(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7 * splitPosition,
                  child: _buildFolderTreeView(),
                ),

                Container(width: 4, color: Theme.of(context).dividerColor),

                Expanded(child: _buildContentView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final pathParts = path.split(currentPath);
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(pathParts.length, (index) {
            final isLast = index == pathParts.length - 1;
            final segment = pathParts[index];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    final navigatePath = path.joinAll(pathParts.sublist(0, index + 1));
                    loadDirectoryContents(navigatePath);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    segment.isEmpty ? 'Root' : segment,
                    style: TextStyle(
                      color: isLast ? Colors.blue : null,
                      fontWeight: isLast ? FontWeight.bold : null,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!isLast) Text(' / ', style: TextStyle(fontSize: 12)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFolderTreeView() {
    return ListView.builder(
      itemCount: directoryList.length,
      padding: EdgeInsets.all(4.0),
      itemBuilder: (context, index) {
        final directory = directoryList[index];
        final name = path.basename(directory.path);

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
          leading: Icon(Icons.folder, color: Colors.blue[400], size: 16),
          title: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          onTap: () => loadDirectoryContents(directory.path),
          selected: currentPath == directory.path,
        );
      },
    );
  }

  Widget _buildContentView() {
    if (filteredContents.isEmpty) {
      return Center(
        child: Text(
          'Json, Csv, Excel files will appear here',
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredContents.length,
      padding: EdgeInsets.all(4.0),
      itemBuilder: (context, index) {
        final entity = filteredContents[index];
        final name = path.basename(entity.path);
        final isDirectory = entity is Directory;

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
          leading: Icon(
            isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: isDirectory ? Colors.blue[400] : Colors.grey,
            size: 16,
          ),
          title: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          trailing:
              isDirectory ? null : Text(getFileSize(entity), style: const TextStyle(fontSize: 10)),
          onTap: () {
            if (isDirectory) {
              loadDirectoryContents(entity.path);
            } else {
              setState(() {
                selectedFilePath = entity.path;
              });
               }
          },
          selected: selectedFilePath == entity.path,
        );
      },
    );
  }

  IconData getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.csv':
        return Icons.table_chart;
      case '.json':
        return Icons.data_object;
      case '.xlsx':
      case '.xls':
        return Icons.grid_on;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color getFileColor(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.csv':
        return Colors.green;
      case '.json':
        return Colors.orange;
      case '.xlsx':
      case '.xls':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getFileSize(FileSystemEntity entity) {
    if (entity is File) {
      try {
        int bytes = entity.lengthSync();
        if (bytes < 1024) {
          return '$bytes B';
        } else if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else if (bytes < 1024 * 1024 * 1024) {
          return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
        }
      } catch (ex) {
        if (kDebugMode) {
          debugPrint('getFileSize(): $ex');
        }
        return 'Unknown';
      }
    }
    return '';
  }
}

// how do we do this?
// 1. the root path (initial path) to start listing the files and entities.
// 2. start building the tree from the root.
// 3. define the 1:3 ratio for the split view. 30% is good enough for the small and large screens, if not i might add additional conditions based on the screen sizes. (this would be hard coded ofc)
// 4. build a simple ui for the split view for now and we'll see later what to change based on my friends opinion.
// 5. also we gotta build some bread crumbs and the folder tree
// 6. colors what.
