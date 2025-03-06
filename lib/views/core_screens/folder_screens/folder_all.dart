import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';

class FolderAll extends StatefulWidget {
  const FolderAll({super.key});

  @override
  State<FolderAll> createState() => _FolderAllState();
}

class _FolderAllState extends State<FolderAll> {
  final TextEditingController searchBarController = TextEditingController();
  late bool anyFilesPresent = true;
  late bool isRootDirectorySelected = false;
  late String selectedRootDirectoryPath = '';

  @override
  void initState() {
    super.initState();
    _loadRootDirectoryPath();
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
                if (anyFilesPresent)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                        child: _buildSearchBar(),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              "Search Public Datasets",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      _buildFoldersSection(),
                      _buildUploadedDatasetsList(
                        filesMetaData: [
                          {
                            'fileName': 'mnist.csv',
                            'fileType': 'CSV',
                            'size': '24 MB',
                            'modified': '1 hour ago',
                            'starred': 'false',
                          },
                          {
                            'fileName': 'customer_data.json',
                            'fileType': 'JSON',
                            'size': '56 KB',
                            'modified': 'Yesterday',
                            'starred': 'true',
                          },
                          {
                            'fileName': 'sales_report.xlsx',
                            'fileType': 'XLSX',
                            'size': '2.3 MB',
                            'modified': 'Last week',
                            'starred': 'false',
                          },
                          {
                            'fileName': 'mnist.csv',
                            'fileType': 'CSV',
                            'size': '24 MB',
                            'modified': '1 hour ago',
                            'starred': 'false',
                          },
                          {
                            'fileName': 'customer_data.json',
                            'fileType': 'JSON',
                            'size': '56 KB',
                            'modified': 'Yesterday',
                            'starred': 'true',
                          },
                          {
                            'fileName': 'sales_report.xlsx',
                            'fileType': 'XLSX',
                            'size': '2.3 MB',
                            'modified': 'Last week',
                            'starred': 'false',
                          },
                        ],
                      ),
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

  Widget _buildUploadedDatasetsList({required List<Map<String, String>> filesMetaData}) {
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
              'Recent Datasets',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
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
            child: ListView.separated(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filesMetaData.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[200], height: 1),
              itemBuilder: (context, index) {
                final fileData = filesMetaData[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
                    border:
                        index == filesMetaData.length - 1
                            ? Border(bottom: BorderSide(color: Colors.transparent))
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
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                          fileData['size'] ?? '',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          fileData['modified'] ?? '',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          fileData['starred'] == 'true' ? Icons.star : Icons.star_border,
                          size: 20,
                          color:
                              fileData['starred'] == 'true'
                                  ? Colors.amber
                                  : (isDarkMode ? Colors.grey[400] : null),
                        ),
                        onPressed: () {},
                        tooltip: "Add to favorites",
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                        onPressed: () {},
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
    final folders = [
      {'name': 'Training Data', 'files': '24 files'},
      {'name': 'Testing Sets', 'files': '12 files'},
      {'name': 'Analytics', 'files': '8 files'},
      {'name': 'Archived', 'files': '36 files'},
    ];

    return Container(
      width: MediaQuery.of(context).size.width * 0.89,
      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Folders',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              return _buildFolderCard(folders[index], isDarkMode);
            },
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
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!, width: 1.0),
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
              onPressed: () {},
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
    );
  }

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
                "Import from source",
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

  void _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ["json", "csv", "xlsx"],
        dialogTitle: 'Select datasets to upload',
      );

      if (result != null) {
        setState(() {
          anyFilesPresent = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }
}
