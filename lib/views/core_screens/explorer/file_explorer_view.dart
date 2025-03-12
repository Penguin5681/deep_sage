import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class DirectoryTreeNode {
  final String name;
  final String path;
  List<DirectoryTreeNode> children;
  bool isExpanded;
  bool isExpandable;

  DirectoryTreeNode({
    required this.name,
    required this.path,
    List<DirectoryTreeNode> children = const [],
    this.isExpanded = false,
    this.isExpandable = false,
  }) : children = List.of(children);
}

class FileExplorerView extends StatefulWidget {
  final String initialPath;
  final VoidCallback onClose;

  const FileExplorerView({
    super.key,
    required this.initialPath,
    required this.onClose,
  });

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
  DirectoryTreeNode? rootNode;
  bool isLoadingTree = true;
  bool isLoadingScreen = true;

  final List<String> allowedExtensions = ['json', 'csv', 'xlsx', 'xls'];

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
    loadDirectoryContents(currentPath);
    buildDirectoryTreeNode(widget.initialPath);
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

      updateTreeSelection(dirPath);
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

  Future<void> buildDirectoryTreeNode(String rootPath) async {
    setState(() => isLoadingTree = true);

    try {
      final _ = Directory(rootPath);
      final name = path.basename(rootPath);

      rootNode = DirectoryTreeNode(
        name: name.isEmpty ? 'Root' : name,
        path: rootPath,
        isExpanded: true,
      );

      await _loadChildDirectories(rootNode!);
    } catch (e) {
      debugPrint('Error building directory tree: $e');
    } finally {
      setState(() => isLoadingTree = false);
    }
  }

  Future<void> _loadChildDirectories(DirectoryTreeNode node) async {
    try {
      final dir = Directory(node.path);
      final List<DirectoryTreeNode> directories = [];

      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final childNode = DirectoryTreeNode(
            name: path.basename(entity.path),
            path: entity.path,
          );

          final hasSubDirs = await _directoryHasSubDirectories(entity);
          childNode.isExpandable = hasSubDirs;

          directories.add(childNode);
        }
      }

      directories.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        node.children = directories;
      });
    } catch (e) {
      debugPrint('Error loading child directories: $e');
    }
  }

  Future<bool> _directoryHasSubDirectories(Directory dir) async {
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) return true;
      }
    } catch (e) {
      debugPrint('Error checking subdirectories: $e');
    }
    return false;
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8.0, spreadRadius: 1.0),
        ],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                Text(
                  'File Explorer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  width:
                      MediaQuery.of(context).size.width * 0.7 * splitPosition,
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
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
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
                    final navigatePath = path.joinAll(
                      pathParts.sublist(0, index + 1),
                    );
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
    if (isLoadingTree) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rootNode == null) {
      return const Center(child: Text('Unable to load directory structure'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _buildDirectoryTree(rootNode!, 0),
      ),
    );
  }

  Widget _buildDirectoryTree(DirectoryTreeNode node, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            setState(() {
              node.isExpanded = !node.isExpanded;
            });
            if (node.isExpanded && node.children.isEmpty) {
              await _loadChildDirectories(node);
            }
            loadDirectoryContents(node.path);
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 8.0 * level,
              top: 4,
              bottom: 4,
              right: 8,
            ),
            color:
                currentPath == node.path
                    ? Colors.transparent
                    : Colors.transparent,
            child: Row(
              children: [
                Icon(
                  node.isExpandable
                      ? (node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right)
                      : Icons.circle,
                  size: node.isExpandable ? 16 : 8,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.folder,
                  size: 16,
                  color:
                      currentPath == node.path
                          ? Colors.blue[700]
                          : Colors.blue[400],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: currentPath == node.path ? Colors.blue : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isExpanded)
          ...node.children.map(
            (child) => _buildDirectoryTree(child, level + 1),
          ),
      ],
    );
  }

  void updateTreeSelection(String dirPath) {
    if (rootNode == null) return;

    void traverseAndExpand(
      DirectoryTreeNode node,
      List<String> segments,
      int index,
    ) {
      if (index >= segments.length) return;

      final currentSegment = segments[index];
      final child = node.children.firstWhere(
        (n) => n.name == currentSegment,
        orElse: () => DirectoryTreeNode(name: '', path: ''),
      );

      if (child.path.isNotEmpty) {
        child.isExpanded = true;
        if (child.children.isEmpty) {
          _loadChildDirectories(child).then((_) {
            traverseAndExpand(child, segments, index + 1);
          });
        } else {
          traverseAndExpand(child, segments, index + 1);
        }
      }
    }

    final segments =
        path.split(dirPath).where((p) => p != rootNode!.name).toList();
    traverseAndExpand(rootNode!, segments, 0);
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
          title: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing:
              isDirectory
                  ? null
                  : Text(
                    getFileSize(entity),
                    style: const TextStyle(fontSize: 10),
                  ),
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
// 7. building the left pane would require to keep a track of root node and the directories under them
