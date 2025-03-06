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
  late bool anyFilesPresent = false;
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 35.0, top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (anyFilesPresent)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildSearchBar(),
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
                                              // Update dialog state
                                              setDialogState(() {
                                                selectedRootDirectoryPath =
                                                    selectedDir;
                                              });

                                              // Update parent widget state
                                              setState(() {
                                                selectedRootDirectoryPath =
                                                    selectedDir;
                                                isRootDirectorySelected = true;
                                              });

                                              // Save to Hive
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
                                          _uploadFiles(); // Proceed with upload
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
        type: FileType.any,
        dialogTitle: 'Select files to upload',
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
