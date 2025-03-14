import 'dart:io';

import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/services/core_services/data_preview_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;

class RawDataTab extends StatefulWidget {
  final ValueNotifier<String?> selectedDatasetNotifier;

  const RawDataTab({super.key, required this.selectedDatasetNotifier});

  @override
  State<RawDataTab> createState() => _RawDataTabState();
}

class _RawDataTabState extends State<RawDataTab> {
  /// Indicates whether a dataset has been imported.
  late bool isDatasetImported = false;

  /// Stores the file path of the imported dataset.
  late String importedDatasetPath = '';

  /// Stores the type of the imported dataset (e.g., 'csv', 'json').
  late String importedDatasetType = '';

  /// A Hive box to store and retrieve recent dataset import history.
  final Box importedDatasets = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  final DataPreviewService _previewService = DataPreviewService();

  /// Stores the preview data loaded from the dataset.
  Map<String, dynamic>? previewData;
  bool isLoading = false;

  /// Retrieves the most recently imported dataset from the stored history.
  ///
  /// It checks if there are any recent imports in the `importedDatasets` Hive box.
  /// If found, it sets the `isDatasetImported`, `importedDatasetPath`, and `importedDatasetType` states accordingly.
  void retrieveRecentDataset() {
    final dynamic recentImportsData = importedDatasets.get('recentImports');

    List<RecentImportsModel> recentImports = [];
    if (recentImportsData is List) {
      recentImports = recentImportsData.cast<RecentImportsModel>();
    } else if (recentImportsData is RecentImportsModel) {
      recentImports = [recentImportsData];
    }

    if (recentImports.isNotEmpty &&
        recentImports[0].filePath != null &&
        recentImports[0].filePath!.isNotEmpty) {
      final recentImport = recentImports[0];
      setState(() {
        isDatasetImported = true;
        importedDatasetPath = recentImport.filePath!;
        importedDatasetType = recentImport.fileType;
      });
    } else {
      setState(() {
        isDatasetImported = false;
        importedDatasetPath = '';
        importedDatasetType = '';
      });
    }
  }

  /// Loads the currently selected dataset based on the stored path and type.
  ///
  /// This method retrieves the `currentDatasetPath` and `currentDatasetType` from the
  /// `importedDatasets` Hive box. If the path exists and the corresponding file exists,
  /// it updates the state to reflect the selected dataset. Otherwise, it attempts to
  /// retrieve the most recent dataset.
  void _loadSelectedDataset() {
    final storedDatasetPath = importedDatasets.get('currentDatasetPath');
    final storedDatasetType = importedDatasets.get('currentDatasetType');

    if (storedDatasetPath != null && File(storedDatasetPath).existsSync()) {
      setState(() {
        isDatasetImported = true;
        importedDatasetPath = storedDatasetPath;
        importedDatasetType = storedDatasetType ?? '';
      });
    } else {
      retrieveRecentDataset();
    }
  }

  /// Handles changes to the selected dataset.
  ///
  /// This method is called when the `selectedDatasetNotifier` emits a new value.
  /// It checks if the stored dataset path is valid. If not, it resets the state.
  /// If the path is valid, it updates the state to reflect the new dataset and
  /// triggers loading of preview data. It also checks if the current dataset is
  /// different from the stored one and resets the `previewData` if it is.
  void _handleDatasetChange() {
    final storedDatasetPath = importedDatasets.get('currentDatasetPath');
    final storedDatasetType = importedDatasets.get('currentDatasetType');

    debugPrint('Dataset changed: ${widget.selectedDatasetNotifier.value}');
    debugPrint('Path: $storedDatasetPath, Type: $storedDatasetType');

    if (storedDatasetPath == null || !File(storedDatasetPath).existsSync()) {
      setState(() {
        isDatasetImported = false;
        importedDatasetPath = '';
        importedDatasetType = '';
        previewData = null;
      });
      return;
    }

    bool isNewDataset = importedDatasetPath != storedDatasetPath;

    setState(() {
      isDatasetImported = true;
      importedDatasetPath = storedDatasetPath;
      importedDatasetType = storedDatasetType ?? '';
      if (isNewDataset) {
        previewData = null;
      }
    });

    _loadPreviewData();
  }

  /// Loads preview data for the selected dataset.
  ///
  /// This method attempts to load a preview of the dataset specified by
  /// `importedDatasetPath` and `importedDatasetType`. It updates the `isLoading`
  /// state accordingly and sets `previewData` with the loaded preview or null if
  /// loading fails. It uses `DataPreviewService` to fetch the preview and
  /// handles any exceptions that occur during the process.
  Future<void> _loadPreviewData() async {
    if (!isDatasetImported || importedDatasetPath.isEmpty) {
      setState(() {
        previewData = null;
      });
      return;
    }

    final pathToLoad = importedDatasetPath;
    final typeToLoad = importedDatasetType;

    debugPrint('Loading preview: $pathToLoad ($typeToLoad)');

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _previewService.loadDatasetPreview(
        pathToLoad,
        typeToLoad,
        10,
      );

      debugPrint('typeToLoad $typeToLoad');

      if (mounted) {
        setState(() {
          previewData = result;
          isLoading = false;
        });
        debugPrint('Preview loaded: ${result != null ? 'success' : 'failed'}');
      }
    } catch (ex) {
      if (mounted) {
        setState(() {
          previewData = null;
          isLoading = false;
        });
      }
      debugPrint('Preview error: $ex');
    }
  }

  /// Initializes the state of the widget.
  ///
  /// This method is called when the widget is inserted into the widget tree.
  /// It performs the following actions:
  /// 1. Calls the superclass's `initState`.
  /// 2. Loads the selected dataset.
  /// 3. Adds a listener to `selectedDatasetNotifier` to handle dataset changes.
  @override
  void initState() {
    super.initState();
    _loadSelectedDataset();
    widget.selectedDatasetNotifier.addListener(_handleDatasetChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreviewData();
    });
  }

  /// Disposes of the resources used by the widget.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It performs the following actions:
  /// 1. Removes the `_handleDatasetChange` listener from `selectedDatasetNotifier`.
  /// 2. Calls the superclass's `dispose` to clean up other resources.
  ///
  @override
  void dispose() {
    widget.selectedDatasetNotifier.removeListener(_handleDatasetChange);
    super.dispose();
  }

  /// Builds the widget tree for the Raw Data Tab.
  ///
  /// This widget displays either a message indicating that no dataset has been
  /// imported yet, or it displays the imported dataset's preview and metadata.
  /// The decision of which view to display depends on whether a dataset has
  /// been imported and if the `importedDatasetPath` is not empty.
  ///
  /// Returns a [Scaffold] widget that structures the layout of the raw data tab.
  /// The [Padding] widget around the main content provides visual spacing.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            isDatasetImported && importedDatasetPath.isNotEmpty
                ? _buildDatasetView()
                : _buildNoDatasetView(),
      ),
    );
  }

  /// Builds the view when no dataset has been imported.
  ///
  /// This widget displays a message informing the user that no dataset has
  /// been imported and provides buttons to either import a dataset locally or
  /// browse datasets on Kaggle.
  ///
  /// Returns an [Expanded] widget containing a [Column] with the informational
  /// message and the import action buttons. The layout is designed to center
  /// the content on the screen.
  Widget _buildNoDatasetView() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'No Dataset imported yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26.0),
          ),
          const Text(
            'Import a dataset to begin exploring and analyzing your data',
          ),
          const SizedBox(height: 18.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // todo: upon clicking the button, redirect to folder_screen
                  // todo: on folder_screen, enable double clicking the dataset title

                  // todo: upon double click import the dataset, by import i mean just store the path
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
                child: Text(
                  'Import Locally',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15.0),
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
                  "Browse Kaggle",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the view when a dataset has been imported.
  ///
  /// This widget displays the name of the imported dataset, along with its
  /// metadata (like total rows and file size) and a preview of the data in
  /// a tabular format. It also handles cases where the data is loading or if
  /// there is no data available.
  ///
  /// Returns a [Column] widget that structures the layout of the dataset view.
  Widget _buildDatasetView() {
    final fileName = path.basename(importedDatasetPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dataset: $fileName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
        const SizedBox(height: 16.0),
        _buildMetadataInfo(),
        const SizedBox(height: 8.0),
        Expanded(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : previewData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildDataTable(),
                    ),
                  ),
        ),
      ],
    );
  }

  /// Builds the metadata information section for the imported dataset.
  ///
  /// This widget displays information such as the total number of rows in the
  /// dataset and its file size. It also indicates the number of rows being
  /// shown in the preview. If `previewData` is null or does not contain
  /// metadata, it displays a default message indicating a 10-row preview.
  ///
  /// Returns a [Column] widget containing the dataset's metadata, formatted
  /// for display in the UI.
  Widget _buildMetadataInfo() {
    if (previewData == null || !previewData!.containsKey('metadata')) {
      return Text(
        'Preview (showing up to 10 rows):',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
      );
    }

    final metadata = previewData!['metadata'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total rows: ${metadata['total_rows']} · Size: ${metadata['file_size_formatted']}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Preview (showing up to ${metadata['preview_rows']} rows):',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
        ),
      ],
    );
  }

  /// Builds the data table widget to display the dataset preview.
  ///
  /// This method generates a [DataTable] widget based on the `previewData`.
  /// It extracts the column names and preview rows from the data and creates
  /// a corresponding data table. If `previewData` is null or in an invalid
  /// format, it displays an error message.
  ///
  /// Returns a [DataTable] widget displaying the dataset's preview data.
  Widget _buildDataTable() {
    if (previewData == null ||
        !previewData!.containsKey('preview') ||
        !previewData!.containsKey('columns')) {
      return const Center(child: Text('Invalid data format'));
    }

    final columns = previewData!['columns'] as List<dynamic>;
    final preview = previewData!['preview'] as List<dynamic>;

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 40,
      columns: List<DataColumn>.generate(
        columns.length,
        (index) => DataColumn(
          label: Text(
            columns[index].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      rows: List<DataRow>.generate(preview.length, (rowIndex) {
        final row = preview[rowIndex] as Map<String, dynamic>;
        return DataRow(
          cells: List<DataCell>.generate(
            columns.length,
            (cellIndex) =>
                DataCell(Text(row[columns[cellIndex]]?.toString() ?? '')),
          ),
        );
      }),
    );
  }
}
