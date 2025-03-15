import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/services/core_services/data_preview_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';

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

  /// Full data from the loaded dataset.
  List<List<dynamic>> fullData = [];

  /// Column names extracted from the dataset.
  List<String> columns = [];

  /// Rows of data from the dataset.
  List<Map<String, dynamic>> rows = [];

  /// Controllers for text editing in the data table (if applicable).
  List<List<TextEditingController>> controllers = [];

  /// A Hive box to store and retrieve recent dataset import history.
  final Box importedDatasets = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  final DataPreviewService _previewService = DataPreviewService();

  /// Stores the preview data loaded from the dataset.
  Map<String, dynamic>? previewData;

  /// Indicates if data is currently being loaded from the dataset.
  bool isLoading = false;

  /// Indicates if the table data is currently in editing mode.
  bool isEditing = false;

  /// Indicates if the edited data is currently being saved.
  bool isSaving = false;

  /// A timer used for debouncing text changes in the table.
  ///
  /// It is used to delay actions until the user has stopped typing for a certain duration.
  Timer? debounceTimer;

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

  /// Loads the dataset preview data based on the `importedDatasetPath` and `importedDatasetType`.
  ///
  /// This function does the following:
  /// - Checks if a dataset has been imported and the path is not empty.
  /// - If not imported or path is empty, it clears the state and returns.
  /// - Determines the number of rows to load based on the `isEditing` mode.
  /// - Calls the `_previewService.loadDatasetPreview` method to load a chunk of the dataset.
  /// - If successful, updates the state with the preview data, and initializes edit data if it's a CSV.
  /// - If an error occurs, it clears the preview data and logs the error.
  ///
  Future<void> _loadPreviewData() async {
    if (!isDatasetImported || importedDatasetPath.isEmpty) {
      setState(() {
        previewData = null;
        fullData = [];
        columns = [];
        rows = [];
      });
      return;
    }

    final pathToLoad = importedDatasetPath;
    final typeToLoad = importedDatasetType;

    // Initially load only 10 rows for preview
    final rowsToLoad = isEditing ? 50 : 10;

    debugPrint('Loading preview: $pathToLoad ($typeToLoad) - $rowsToLoad rows');

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _previewService.loadDatasetPreview(
        pathToLoad,
        typeToLoad,
        rowsToLoad,
      );

      if (mounted) {
        setState(() {
          previewData = result;
          isLoading = false;

          if (result != null && typeToLoad.toLowerCase() == 'csv') {
            _initializeEditData();
          }
        });
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

  /// Initializes the edit data structures.
  ///
  /// This method is responsible for preparing the necessary data structures for editing.
  /// It extracts column names and preview rows from `previewData`, and creates
  /// `TextEditingController` instances for each cell in the preview rows. These
  /// controllers are used to capture user input for each cell.
  ///
  /// Additionally, it calls `_loadFullCsvData` if the imported dataset is a CSV,
  /// to load the entire CSV dataset for full data access during editing.
  void _initializeEditData() {
    if (previewData == null ||
        !previewData!.containsKey('preview') ||
        !previewData!.containsKey('columns')) {
      return;
    }

    columns = List<String>.from(previewData!['columns']);
    rows = List<Map<String, dynamic>>.from(previewData!['preview']);

    controllers = [];
    for (var i = 0; i < rows.length; i++) {
      List<TextEditingController> rowControllers = [];
      for (var column in columns) {
        final value = rows[i][column]?.toString() ?? '';
        rowControllers.add(TextEditingController(text: value));
      }
      controllers.add(rowControllers);
    }

    if (importedDatasetType.toLowerCase() == 'csv') {
      _loadFullCsvData();
    }
  }

  /// Loads the full CSV dataset from the file at `importedDatasetPath`.
  ///
  /// This method first loads only the header row to initialize `fullData`. Then, it loads the rows
  /// that are currently visible in the preview (up to the number of rows in the `rows` list).
  /// The method updates `fullData` with the header and the visible rows.
  ///
  /// If there is an error loading the CSV or if the file is empty, it prints an error message to the debug console.
  ///
  /// This method is only intended to be used for CSV files.
  ///
  Future<void> _loadFullCsvData() async {
    try {
      // Only load header row initially
      final headerChunk = await loadCsvChunk(importedDatasetPath, 0, 1);
      if (headerChunk == null || headerChunk.isEmpty) {
        debugPrint("Failed to load CSV header");
        return;
      }

      // Initialize fullData with header row
      fullData = [headerChunk[0]];

      // Now load only the rows we need for editing (those visible in the preview)
      final visibleRowsChunk = await loadCsvChunk(
        importedDatasetPath,
        1,
        rows.length,
      );
      if (visibleRowsChunk != null && visibleRowsChunk.isNotEmpty) {
        fullData.addAll(visibleRowsChunk);
      }

      debugPrint("Loaded header + ${rows.length} rows for editing");
    } catch (ex) {
      debugPrint("Error loading CSV data: $ex");
    }
  }

  /// Toggles the editing mode of the dataset preview.
  ///
  /// This method checks if the imported dataset is a CSV file. If it is not, it displays a SnackBar
  /// message indicating that only CSV files can be edited in place and then returns.
  ///
  /// If the dataset is a CSV, it toggles the `isEditing` state and calls `_loadPreviewData()`
  /// to refresh the preview data. This refresh is necessary because the UI needs to switch
  /// between the editable table and the read-only table views. The UI then rebuilds,
  /// displaying the appropriate table format based on the new `isEditing` state.
  void _toggleEditing() {
    if (importedDatasetType.toLowerCase() != 'csv') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only CSV files can be edited in-place')),
      );
      return;
    }

    setState(() {
      isEditing = !isEditing;

      _loadPreviewData();
    });
  }

  /// Saves changes made to a cell in the editable data table.
  ///
  /// This method updates the in-memory representation of the dataset (`rows`)
  /// with a new value for a specific cell. It also debounces the saving of
  /// the full CSV data to avoid frequent writes. After a delay of 1000 milliseconds,
  /// it calls `_saveFullCsvData()` to persist all changes to the file.
  ///
  /// - [rowIndex]: The index of the row in the `rows` list.
  /// - [colIndex]: The index of the column in the `columns` list.
  /// - [newValue]: The new string value to be assigned to the cell.
  ///
  void _saveChanges(int rowIndex, int colIndex, String newValue) {
    if (debounceTimer?.isActive ?? false) {
      debounceTimer!.cancel();
    }

    rows[rowIndex][columns[colIndex]] = newValue;

    debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _saveFullCsvData();
    });
  }

  /// Saves the full CSV data after edits.
  ///
  /// This method is responsible for persisting changes made to the dataset in the
  /// editable table back to the original CSV file. It iterates through each cell
  /// in the `controllers` list and updates the corresponding value in the `rows`
  /// list with the current text in the controllers.
  ///
  /// Once all in-memory changes are made, it reads the original CSV file, modifies
  /// the necessary lines, and writes the updated data back to the file.
  ///
  /// The method updates the `isSaving` state to indicate ongoing save operations
  /// and displays success or error SnackBar messages to notify the user of the
  /// outcome. It handles potential exceptions during the saving process and
  /// prints error details to the debug console. Finally, it resets the `isSaving`
  /// state to false.
  ///

  Future<void> _saveFullCsvData() async {
    setState(() {
      isSaving = true;
    });

    try {
      for (var i = 0; i < rows.length && i < controllers.length; i++) {
        for (var j = 0; j < columns.length && j < controllers[i].length; j++) {
          rows[i][columns[j]] = controllers[i][j].text;
        }
      }

      final file = File(importedDatasetPath);
      final lines = await file.readAsLines();

      for (int i = 0; i < rows.length && i + 1 < lines.length; i++) {
        List<dynamic> updatedRow = [];
        for (var column in columns) {
          updatedRow.add(rows[i][column]);
        }

        lines[i + 1] = const ListToCsvConverter().convert([updatedRow]).trim();
      }

      await file.writeAsString(lines.join('\n'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $ex'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error saving changes: $ex');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
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

  /// Disposes of the resources used by this widget.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It performs the following actions:
  /// 1. Cancels the `debounceTimer` if it is active.
  /// 2. Disposes of all `TextEditingController` instances in the `controllers` list.
  /// 3. Removes the `_handleDatasetChange` listener from the `selectedDatasetNotifier`.
  /// 4. Calls the superclass's `dispose` method.
  ///

  @override
  void dispose() {
    debounceTimer?.cancel();
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
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

  /// Builds the main view for displaying the dataset's details and data.
  ///
  /// This method constructs the UI components for viewing the imported dataset.
  /// It includes the dataset's filename, an option to toggle between view and
  /// edit modes (for CSV files), metadata information, and the dataset's
  /// preview or editable data table.
  ///
  /// - [fileName]: The base name of the imported dataset file.
  /// - [isDarkMode]: A boolean indicating if the current theme is dark.
  /// - [isCSV]: A boolean indicating if the imported dataset is a CSV file.
  ///
  /// The view is dynamically updated based on these parameters, and displays
  /// a loading indicator, 'No data available' message, or the data table
  /// accordingly. It also manages the display of a 'Saving changes...' indicator
  /// when data modifications are being saved.
  ///
  Widget _buildDatasetView() {
    final fileName = path.basename(importedDatasetPath);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isCSV = importedDatasetType.toLowerCase() == 'csv';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dataset: $fileName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            if (isCSV)
              ElevatedButton.icon(
                icon: Icon(isEditing ? Icons.visibility : Icons.edit),
                label: Text(isEditing ? 'View Only' : 'Edit Data'),
                onPressed: _toggleEditing,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isEditing ? Colors.grey : Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16.0),
        _buildMetadataInfo(),
        const SizedBox(height: 8.0),
        if (isSaving)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Saving changes...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
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
                      child:
                          isEditing && isCSV
                              ? _buildEditableDataTable()
                              : _buildDataTable(),
                    ),
                  ),
        ),
      ],
    );
  }

  /// Builds the editable data table for CSV datasets.
  ///
  /// This method constructs a [Table] widget that allows editing of the
  /// dataset's preview data. It includes a header row with column names
  /// and rows of editable text fields, each corresponding to a cell in the
  /// dataset. The appearance of the table is adjusted based on the current
  /// theme (dark or light).
  ///
  /// - [isDarkMode]: Indicates if the application is in dark mode, influencing
  ///   the table's border and text colors.
  /// - [columns]: A list of column names for the table.
  /// - [controllers]: A list of lists of [TextEditingController] objects, each
  ///   linked to a cell in the table, enabling real-time data input.
  ///
  Widget _buildEditableDataTable() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Table(
      border: TableBorder.all(
        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        width: 1,
      ),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
          children:
              columns
                  .map(
                    (column) => Container(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        column,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),

        // Data rows
        ...controllers.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final rowControllers = entry.value;

          return TableRow(
            children:
                rowControllers.asMap().entries.map((controllerEntry) {
                  final colIndex = controllerEntry.key;
                  final controller = controllerEntry.value;

                  return Container(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                      ),
                      onChanged:
                          (value) => _saveChanges(rowIndex, colIndex, value),
                    ),
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  /// Loads a chunk of data from a CSV file.
  ///
  /// This method reads a CSV file from the specified [filePath] and extracts a
  /// chunk of data, starting from [startRow] and including [chunkSize] rows.
  /// It uses a stream-based approach to efficiently handle large files.
  ///
  /// - [filePath]: The path to the CSV file.
  /// - [startRow]: The row number to start reading from (0-based index).
  /// - [chunkSize]: The number of rows to read in this chunk.
  ///
  /// Returns a [Future] that completes with a list of rows, where each row is
  /// a list of dynamic values. Returns `null` if the file does not exist or
  /// if there is an error reading the file.
  ///
  /// The method skips header rows and starts reading from the specified `startRow`.
  /// It stops reading when it reaches `startRow + chunkSize` or the end of the file.
  Future<List<List<dynamic>>?> loadCsvChunk(
    String filePath,
    int startRow,
    int chunkSize,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final lineStream = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      List<List<dynamic>> chunk = [];
      int currentLine = 0;

      await for (var line in lineStream) {
        if (currentLine >= startRow && currentLine < startRow + chunkSize) {
          final rowData = const CsvToListConverter().convert(line).first;
          chunk.add(rowData);
        } else if (currentLine >= startRow + chunkSize) {
          break;
        }
        currentLine++;
      }

      return chunk;
    } catch (e) {
      debugPrint('Error loading CSV chunk: $e');
      return null;
    }
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
