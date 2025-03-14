import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class DirectoryTreeNode {
  /// The name of the directory node
  final String name;

  /// The full path to the directory
  final String path;

  /// List of child nodes (subdirectories)
  List<DirectoryTreeNode> children;

  /// Whether this node is currently expanded in the UI
  bool isExpanded;

  /// Whether this node can be expanded (has subdirectories)
  bool isExpandable;

  /// Creates a directory tree node
  ///
  /// [name] The display name of the directory
  /// [path] The full filesystem path
  /// [children] Optional list of child nodes
  /// [isExpanded] Whether the node is initially expanded
  /// [isExpandable] Whether the node can be expanded
  DirectoryTreeNode({
    required this.name,
    required this.path,
    List<DirectoryTreeNode> children = const [],
    this.isExpanded = false,
    this.isExpandable = false,
  }) : children = List.of(children);
}

/// Widget that displays a file explorer with directory tree and file listing
class FileExplorerView extends StatefulWidget {
  /// The starting directory path for the explorer
  final String initialPath;

  /// Callback function when the explorer is closed
  final VoidCallback onClose;

  /// Creates a file explorer view
  ///
  /// [initialPath] The starting directory path
  /// [onClose] Callback for when the explorer is closed
  const FileExplorerView({
    super.key,
    required this.initialPath,
    required this.onClose,
  });

  @override
  State<FileExplorerView> createState() => _FileExplorerViewState();
}

class _FileExplorerViewState extends State<FileExplorerView> {
  /// Current directory path being displayed
  String currentPath = '';

  /// Path of the currently selected file
  String selectedFilePath = '';

  /// Position of the splitter between directory tree and content view (0.0-1.0)
  double splitPosition = 0.3;

  /// All files and directories in the current directory
  List<FileSystemEntity> folderContents = [];

  /// List of directories only
  List<FileSystemEntity> directoryList = [];

  /// Filtered list of files and directories based on allowed extensions
  List<FileSystemEntity> filteredContents = [];

  /// Root node for the directory tree structure
  DirectoryTreeNode? rootNode;

  /// Flag indicating if the directory tree is being loaded
  bool isLoadingTree = true;

  /// Flag indicating if the main view is being loaded
  bool isLoadingScreen = true;

  /// List of file extensions that should be shown in the explorer
  final List<String> allowedExtensions = ['json', 'csv', 'txt'];

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
    loadDirectoryContents(currentPath);
    buildDirectoryTreeNode(widget.initialPath);
  }

  /// Loads the contents of a directory at the specified path
  ///
  /// This method populates [folderContents] with all files and directories
  /// at the given [dirPath], updates the current path, and applies content filtering.
  /// It also updates the directory tree selection to match the current path.
  ///
  /// [dirPath] The directory path to load
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

  /// Filters the folder contents based on allowed file extensions
  ///
  /// This method populates [filteredContents] with all directories and
  /// only files that have extensions matching [allowedExtensions].
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

  /// Builds the directory tree structure starting from the specified root path
  ///
  /// This method initializes the [rootNode] of the directory tree by:
  /// 1. Setting the loading state to true
  /// 2. Creating a root node with the directory name (or 'Root' if empty)
  /// 3. Loading all child directories recursively using [_loadChildDirectories]
  /// 4. Setting the loading state back to false when complete
  ///
  /// [rootPath] The file system path to use as the root of the directory tree
  ///
  /// Throws various IO exceptions that are caught and logged during directory access
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

  /// Loads the child directories for a given node in the directory tree
  ///
  /// This method:
  /// 1. Attempts to list all entities in the directory represented by [node]
  /// 2. Filters for only directories (not files)
  /// 3. Creates child nodes for each subdirectory
  /// 4. Checks if each subdirectory has its own children to determine expandability
  /// 5. Sorts the directories alphabetically by name
  /// 6. Updates the node's children collection with the found directories
  ///
  /// [node] The parent directory node to load children for
  ///
  /// The method handles any exceptions that occur during directory access
  /// and logs them via debugPrint.
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

  /// Checks if a directory contains any subdirectories
  ///
  /// This method efficiently checks if [dir] contains at least one subdirectory
  /// by streaming the directory contents and returning true as soon as a Directory
  /// entity is found.
  ///
  /// [dir] The directory to check for subdirectories
  ///
  /// Returns a [Future<bool>] that resolves to true if at least one subdirectory exists,
  /// false otherwise
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

  /// Builds a filter bar showing the file types currently visible in the explorer
  ///
  /// This widget creates a horizontal container with badges for each supported
  /// file type (JSON, CSV, and text files).
  ///
  /// Returns a [Widget] containing the file type filter UI
  Widget buildFileTypeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).cardColor.withValues(alpha: 0.4),
      child: Row(
        children: [
          Text("Showing:     ", style: TextStyle(fontSize: 12)),
          buildFileTypeBadge("JSON", Colors.orange),
          const SizedBox(width: 6),
          buildFileTypeBadge("CSV", Colors.green),
          const SizedBox(width: 6),
          buildFileTypeBadge("Text", Colors.blue),
        ],
      ),
    );
  }

  /// Builds a badge widget for displaying a file type filter
  ///
  /// Creates a visually distinct badge with the specified [label] and [color].
  /// The badge has a rounded rectangle shape with a border and background
  /// color derived from the provided [color] with different alpha values.
  ///
  /// [label] The text to display inside the badge (e.g. "JSON", "CSV")
  /// [color] The base color for the badge styling
  ///
  /// Returns a [Widget] representing the styled file type badge
  Widget buildFileTypeBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
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

  /// Builds a breadcrumb navigation bar showing the current directory path
  ///
  /// This method creates a horizontally scrollable breadcrumb UI that:
  /// 1. Splits the current path into segments
  /// 2. Renders each segment as a clickable button
  /// 3. Highlights the last segment (current directory)
  /// 4. Allows navigation to any parent directory by clicking its segment
  ///
  /// The breadcrumb shows the full path hierarchy from root to the current directory,
  /// with forward slashes separating each level.
  ///
  /// Returns a [Widget] containing the styled breadcrumb navigation UI
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

  /// Builds the folder tree view widget, showing a tree structure of directories
  ///
  /// This method:
  /// 1. Displays a loading indicator if [isLoadingTree] is true.
  /// 2. Shows an error message if [rootNode] is null (directory tree failed to load).
  /// 3. Otherwise, it builds a scrollable directory tree using [_buildDirectoryTree].
  ///
  /// The folder tree view allows users to navigate through the directory hierarchy,
  /// expand/collapse directories, and select directories to load their contents.
  ///
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

  /// Builds a single node in the directory tree
  ///
  /// This method recursively creates a view for a [DirectoryTreeNode] and its
  /// children. Each node is rendered as an expandable/collapsible item with
  /// an icon and the directory name.
  ///
  /// The node can be tapped to:
  /// - Expand or collapse the node
  /// - Load child directories if expanded and not yet loaded
  /// - Load the contents of the selected directory into the content view
  ///
  /// The node's appearance (padding, icon, text) is customized based on:
  /// - The level of the node in the tree ([level])
  /// - Whether the node is currently expanded
  /// - Whether the node is the currently selected path
  /// - Whether the node has children (isExpandable)
  ///
  /// [node] The [DirectoryTreeNode] to render
  /// [level] The level of the node in the directory tree (0 for root, 1 for direct child, etc.)
  ///
  /// Returns a [Widget] representing the node and its sub-tree in the UI
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

  /// Updates the directory tree selection to highlight the currently active directory.
  ///
  /// This method:
  /// 1. Splits the [dirPath] into segments to traverse the directory hierarchy.
  /// 2. Traverses the tree using the `traverseAndExpand` recursive function.
  /// 3. For each segment, finds the corresponding child node in the tree.
  /// 4. Expands the child node if found.
  /// 5. If the child node has no children, loads its child directories before proceeding.
  ///
  /// [dirPath] The directory path that should be highlighted in the tree.
  ///
  /// The `traverseAndExpand` function:
  /// - Takes a [node], a list of [segments], and an [index] to traverse the tree.
  /// - Base cases:
  ///   - If `rootNode` is null, it does nothing (early exit).
  ///   - If `index` exceeds the `segments` length, traversal ends.
  /// - Retrieves the current segment and attempts to find a child node with a matching name.
  /// - If a matching child is found, it's marked as expanded.
  /// - If the child node has no children, loads them recursively.
  /// - Recursively calls itself to process the next segment.
  ///
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

  /// Builds the main content view showing the files and directories in the current directory.
  ///
  /// This method creates a list of [ListTile] widgets representing the files
  /// and directories within the currently selected folder. Each item in the list
  /// can be tapped to either:
  /// - Load the contents of a subdirectory (if it's a directory).
  /// - Mark a file as selected (if it's a file).
  ///
  /// If no files or directories are present (empty `filteredContents`), it displays
  /// a message indicating that files will appear here.
  ///
  /// The view includes:
  /// - Icons to distinguish between files and directories
  /// - The file/directory name
  /// - File size (for files)
  /// - Visual feedback for the currently selected file
  /// - Optimized layout with dense list tiles
  ///
  /// This content view is the main area where users interact with the file explorer's
  /// listing of the files and directories in the current location.
  ///
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

  /// Returns the appropriate icon for a given file based on its extension.
  ///
  /// This method examines the [fileName]'s extension and returns an
  /// [IconData] representing a standard icon associated with that type.
  /// It supports CSV, JSON, and TXT files, defaulting to a generic
  /// file icon for all others.
  ///
  /// [fileName] The name of the file to determine the icon for.
  /// Returns the icon data corresponding to the file type.
  IconData getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.csv':
        return Icons.table_chart;
      case '.json':
        return Icons.data_object;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Returns the appropriate color for a given file based on its extension.
  ///
  /// This method examines the [fileName]'s extension and returns a
  /// [Color] representing a standard color associated with that type.
  /// It supports CSV, JSON, and TXT files, defaulting to grey for all others.
  ///
  /// [fileName] The name of the file to determine the color for.
  ///
  /// Returns the color corresponding to the file type.
  Color getFileColor(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.csv':
        return Colors.green;
      case '.json':
        return Colors.orange;
      case '.txt':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Returns a human-readable string representing the file size of a given entity.
  ///
  /// This method takes a [FileSystemEntity] and if it's a [File], calculates the
  /// size in bytes. It then returns the size formatted in a more readable format
  /// (B, KB, MB, GB). If any error occurs during file size retrieval, or if the
  /// entity is not a file, it returns 'Unknown' or an empty string respectively.
  ///
  /// [entity] The file system entity to get the size for.
  ///
  /// Returns a string representing the formatted file size or 'Unknown' if the size
  /// could not be determined, or an empty string if the entity is not a file.
  ///
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
