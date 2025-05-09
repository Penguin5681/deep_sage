import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/services/caching_services/dataset_insights_caching_service.dart';
import 'package:deep_sage/core/services/core_services/data_preview_service.dart';
import 'package:deep_sage/core/services/core_services/quick_insights_service.dart';
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

class _RawDataTabState extends State<RawDataTab>
    with AutomaticKeepAliveClientMixin {
  final DatasetInsightsCachingService _insightsCachingService =
      DatasetInsightsCachingService();

  /// Indicates whether a dataset has been imported.
  late bool isDatasetImported = false;

  /// Stores the file path of the imported dataset.
  late String importedDatasetPath = '';

  /// Stores the type of the imported dataset (e.g., 'csv', 'json').
  late String importedDatasetType = '';

  /// Cache key for current dataset identification
  String? _currentDatasetCacheKey;

  @override
  bool get wantKeepAlive => true;

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

  /// Indicates if the additional 50 rows being loaded
  bool isEditModeLoading = false;

  /// A timer used for debouncing text changes in the table.
  /// It is used to delay actions until the user has stopped typing for a
  /// certain duration.
  Timer? debounceTimer;

  /// An instance of the QuickInsightsService used for generating insights about
  /// the imported dataset.
  final QuickInsightsService _insightsService = QuickInsightsService();

  /// Data from the insights service.
  Map<String, dynamic>? insightsData;

  /// A flag to show/hide the insight content.
  bool showInsights = false;

  /// Number of rows currently loaded in the preview.
  int loadedRowsCount = 10;

  /// Indicates if there are more rows to be loaded from the dataset.
  bool hasMoreRows = true;

  /// Indicates if additional rows are currently being loaded.
  bool isLoadingMoreRows = false;

  /// Total number of rows in the dataset.
  int totalRowCount = 0;

  /// Indicates if insights are currently being loaded.
  bool isLoadingInsights = false;

  /// Loads quick insights for the current dataset.
  ///
  /// This method asynchronously retrieves or generates insights about the loaded dataset.
  /// It follows these steps:
  ///
  /// 1. Validates that a dataset is imported and has a valid path
  /// 2. Verifies the dataset hasn't changed during execution
  /// 3. Attempts to retrieve cached insights first using [_insightsCachingService]
  /// 4. If no cached insights are available, generates new insights using [_insightsService]
  /// 5. Caches the newly generated insights for future use
  /// 6. Updates the UI state based on the insights retrieved
  ///
  /// The method includes multiple dataset path checks to ensure that insights
  /// aren't loaded for a dataset that has been changed during async operations.
  ///
  /// Sets [isLoadingInsights] to true while loading and updates [insightsData]
  /// with the retrieved insights when complete.
  ///
  /// Returns a [Future] that completes when the insights loading process is finished.
  Future<void> _loadQuickInsights() async {
    if (!isDatasetImported || importedDatasetPath.isEmpty) {
      setState(() {
        insightsData = null;
      });
      return;
    }

    final currentPath = importedDatasets.get('currentDatasetPath');
    if (currentPath != importedDatasetPath) {
      debugPrint('Dataset changed while loading insights, aborting');
      return;
    }

    setState(() {
      isLoadingInsights = true;
      showInsights = true;
    });

    try {
      final cachedInsights = await _insightsCachingService.getCachedInsights(
        importedDatasetPath,
      );

      if (importedDatasetPath != importedDatasets.get('currentDatasetPath')) {
        debugPrint(
          'Dataset changed after loading insights, discarding results',
        );
        return;
      }

      if (cachedInsights != null) {
        if (mounted) {
          setState(() {
            insightsData = cachedInsights;
            isLoadingInsights = false;
          });
        }
        debugPrint('Using cached insights for $importedDatasetPath');
        return;
      }

      final file = File(importedDatasetPath);
      final insights = await _insightsService.analyzeCsvFile(file);

      if (importedDatasetPath != importedDatasets.get('currentDatasetPath')) {
        debugPrint('Dataset changed after analyzing, discarding results');
        return;
      }

      if (insights != null) {
        await _insightsCachingService.cacheInsights(
          importedDatasetPath,
          insights,
        );

        if (mounted) {
          setState(() {
            insightsData = insights;
            isLoadingInsights = false;
          });
        }
      }
    } catch (ex) {
      if (mounted) {
        setState(() {
          insightsData = null;
          isLoadingInsights = false;
        });
      }
      debugPrint('Insights error: $ex');
    }
  }

  /// Toggles the visibility of the insights section
  void _toggleInsights() {
    setState(() {
      showInsights = !showInsights;

      // Load insights if they haven't been loaded yet and we're showing them
      if (showInsights && insightsData == null && !isLoadingInsights) {
        _loadQuickInsights();
      }
    });
  }

  /// Loads more rows from the dataset preview.
  ///
  /// This method loads additional rows from the dataset, based on the current
  /// `loadedRowsCount` and the provided `additionalRows` parameter. It updates
  /// the `previewData` state with the new rows, and checks if there are more rows
  /// to be loaded by comparing `loadedRowsCount` with `totalRowCount`.
  ///
  /// - [additionalRows]: The number of additional rows to load. Defaults to 20.
  ///
  /// This method will not execute if `isLoadingMoreRows` is true or if `hasMoreRows` is false.
  Future<void> _loadMoreRows([int additionalRows = 20]) async {
    if (isLoadingMoreRows || !hasMoreRows) return;

    setState(() {
      isLoadingMoreRows = true;
    });

    try {
      final rowsToLoad = loadedRowsCount + additionalRows;

      final result = await _previewService.loadDatasetPreview(
        importedDatasetPath,
        importedDatasetType,
        rowsToLoad,
      );

      if (mounted) {
        setState(() {
          previewData = result;
          isLoadingMoreRows = false;

          loadedRowsCount = rowsToLoad;
          if (result != null && result['metadata'] != null) {
            totalRowCount = result['metadata']['total_rows'] ?? 0;
            hasMoreRows = loadedRowsCount < totalRowCount;
          }
        });
      }
    } catch (ex) {
      if (mounted) {
        setState(() {
          isLoadingMoreRows = false;
        });
        _showNoMoreRowsDialog();
        debugPrint('Preview error when loading more rows: $ex');
      }
    }
  }

  /// Displays a dialog indicating that the end of the dataset has been reached.
  ///
  /// This function presents a modal dialog to the user, informing them that
  /// there are no more rows to load in the dataset. It includes an "OK" button
  /// to dismiss the dialog. This is typically called when the user attempts to
  /// load more rows, but there are no more rows available.
  void _showNoMoreRowsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End of Dataset'),
            content: const Text(
              'You have reached the end of the dataset. There are no more rows to load.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

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
        _currentDatasetCacheKey = null;
        // Reset insights data
        insightsData = null;
        isLoadingInsights = false;
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
        _currentDatasetCacheKey = null;
        // Reset insights data when dataset changes
        insightsData = null;
        isLoadingInsights = false;
      }
    });

    if (isNewDataset || previewData == null) {
      _loadPreviewData();
    }
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
  Future<void> _loadPreviewData({bool shouldToggleEditing = false}) async {
    if (!isDatasetImported || importedDatasetPath.isEmpty) {
      setState(() {
        previewData = null;
        fullData = [];
        columns = [];
        rows = [];
      });
      return;
    }

    final newCacheKey = '$importedDatasetPath-$loadedRowsCount';

    if (_currentDatasetCacheKey == newCacheKey &&
        previewData != null &&
        !shouldToggleEditing) {
      debugPrint('Using cached preview data');
      if (shouldToggleEditing) {
        setState(() {
          isEditing = !isEditing;
          if (isEditing && importedDatasetType.toLowerCase() == 'csv') {
            _initializeEditData();
          }
        });
      }
      return;
    }

    final pathToLoad = importedDatasetPath;
    final typeToLoad = importedDatasetType;

    final rowsToLoad = isEditing || shouldToggleEditing ? 50 : 10;

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
          _currentDatasetCacheKey = newCacheKey;

          loadedRowsCount = rowsToLoad;
          if (result != null && result['metadata'] != null) {
            totalRowCount = result['metadata']['total_rows'] ?? 0;
            hasMoreRows = loadedRowsCount < totalRowCount;
          }

          if (shouldToggleEditing) {
            isEditing = !isEditing;
          }

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
          if (shouldToggleEditing) {
            isEditing = false;
          }
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
      isEditModeLoading = true; // Show loading indicator first
    });

    Future.delayed(Duration.zero, () async {
      // Load data asynchronously
      await _loadPreviewData(shouldToggleEditing: true);

      if (mounted) {
        setState(() {
          isEditModeLoading = false;
        });
      }
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
    super.build(context);
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
                onPressed: () {},
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

    return SingleChildScrollView(
      child: Column(
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
                  icon: Icon(
                    isEditModeLoading
                        ? Icons.hourglass_empty
                        : (isEditing ? Icons.visibility : Icons.edit),
                  ),
                  label: Text(
                    isEditModeLoading
                        ? 'Loading...'
                        : (isEditing ? 'View Only' : 'Edit Data'),
                  ),
                  onPressed: isEditModeLoading ? null : _toggleEditing,
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
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

          (previewData != null && hasMoreRows)
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed:
                        isLoadingMoreRows ? null : () => _loadMoreRows(20),
                    icon:
                        isLoadingMoreRows
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                            : const Icon(
                              Icons.expand_more,
                              size: 20,
                              color: Colors.blue,
                            ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        isLoadingMoreRows ? 'Loading...' : 'Load More Rows',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              )
              : const SizedBox(),
          _buildQuickInsightsSection(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickInsightsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final headerColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Insights Header with toggle
        InkWell(
          onTap: _toggleInsights,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Quick Insights',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (!showInsights || insightsData == null)
                  ElevatedButton(
                    onPressed: isLoadingInsights ? null : _loadQuickInsights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child:
                        isLoadingInsights
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Generate'),
                  ),
                const SizedBox(width: 8),
                Icon(
                  showInsights ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),

        // Insights Content (expandable)
        if (showInsights) ...[
          const SizedBox(height: 16),
          isLoadingInsights
              ? const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating insights...'),
                  ],
                ),
              )
              : insightsData == null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No insights available. Click "Generate" to analyze this dataset.',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _buildInsightsContent(cardColor),
        ],
      ],
    );
  }

  /// Builds the content section for quick insights.
  ///
  /// This method creates the layout for displaying various insights about the dataset.
  /// It includes sections for data quality, column distribution, categorical stats,
  /// and numeric stats. Each section is conditionally rendered based on the data available
  /// in the `insightsData` map. If there's no insights data or the format is invalid,
  /// it will display an appropriate message.
  ///
  /// [cardColor] The background color for the insight cards.
  Widget _buildInsightsContent(Color? cardColor) {
    if (insightsData == null || !insightsData!.containsKey('basic_insights')) {
      return const Center(child: Text('Invalid insights data format'));
    }

    final insights = insightsData!['basic_insights'];
    final dataQuality = insights['data_quality'];
    final numericStats = insights['numeric_stats'];
    final categoricalStats = insights['categorical_stats'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data Quality Card
        _buildInsightCard(
          'Data Quality',
          Icons.check_circle_outline,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQualityScoreRow(
                'Overall Quality',
                dataQuality['overall_score'],
              ),
              const SizedBox(height: 8),
              _buildQualityScoreRow(
                'Completeness',
                dataQuality['completeness_score'],
              ),
              _buildQualityScoreRow(
                'Outlier Score',
                dataQuality['outlier_score'],
              ),
              _buildQualityScoreRow(
                'Duplication Score',
                dataQuality['duplication_score'],
              ),
              const SizedBox(height: 12),
              Text(
                'Missing Data: ${dataQuality['total_missing_percentage'].toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          cardColor,
        ),

        const SizedBox(height: 16),

        _buildInsightCard(
          'Column Distribution',
          Icons.category_outlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumnTypeDistribution(dataQuality['column_types']),
            ],
          ),
          cardColor,
        ),

        const SizedBox(height: 16),

        if (categoricalStats != null && categoricalStats.isNotEmpty)
          _buildInsightCard(
            'Top Categories',
            Icons.pie_chart_outline,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildCategoricalHighlights(categoricalStats)],
            ),
            cardColor,
          ),

        const SizedBox(height: 16),

        if (numericStats != null && numericStats.isNotEmpty)
          _buildInsightCard(
            'Numeric Columns',
            Icons.trending_up,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildNumericHighlights(numericStats)],
            ),
            cardColor,
          ),
      ],
    );
  }

  /// Builds a card to display an insight section.
  ///
  /// Creates a consistent card layout for different insight types.
  ///
  /// [title] The title of the insight card.
  /// [icon] The icon to display next to the title.
  /// [content] The widget containing the insight content.
  /// [cardColor] The background color of the card.
  Widget _buildInsightCard(
    String title,
    IconData icon,
    Widget content,
    Color? cardColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  /// Builds a quality score visualization_and_explorer with a linear progress indicator.
  ///
  /// [label] The name of the quality metric.
  /// [score] The numerical score value (0-100).
  Widget _buildQualityScoreRow(String label, double score) {
    final Color scoreColor =
        score > 90 ? Colors.green : (score > 70 ? Colors.orange : Colors.red);

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${score.toStringAsFixed(1)}%',
          style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor),
        ),
      ],
    );
  }

  /// Builds a visualization_and_explorer of column type distribution.
  ///
  /// [columnTypes] Map containing counts of different column types.
  Widget _buildColumnTypeDistribution(Map<String, dynamic> columnTypes) {
    final totalColumns = columnTypes.values.fold<int>(
      0,
      (sum, value) => sum + value as int,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total columns: $totalColumns',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children:
              columnTypes.entries.map((entry) {
                final type = entry.key.toString();
                final count = entry.value as int;
                final percentage = (count * 100 / totalColumns).toStringAsFixed(
                  1,
                );

                return Chip(
                  backgroundColor: _getColumnTypeColor(
                    type,
                  ).withValues(alpha: 0.15),
                  side: BorderSide(color: _getColumnTypeColor(type), width: 1),
                  label: Text(
                    '$type: $count ($percentage%)',
                    style: TextStyle(
                      color: _getColumnTypeColor(type),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: _getColumnTypeColor(type),
                    radius: 12,
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  /// Gets a color for a specific column type.
  ///
  /// [columnType] The type of the column.
  /// Returns a color associated with the column type.
  Color _getColumnTypeColor(String columnType) {
    switch (columnType) {
      case 'categorical':
        return Colors.purple;
      case 'numeric':
        return Colors.blue;
      case 'datetime':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Builds highlights for categorical columns.
  ///
  /// [categoricalStats] Map containing statistics for categorical columns.
  /// Returns a widget showing key categorical variables and their top values.
  Widget _buildCategoricalHighlights(Map<String, dynamic> categoricalStats) {
    // Select up to 3 categorical columns to show
    final columnsToShow = categoricalStats.keys.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          columnsToShow.map((columnName) {
            final columnStats = categoricalStats[columnName];
            final topValues =
                columnStats['top_5_values'] as Map<String, dynamic>;
            final uniqueValues = columnStats['unique_values'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        columnName.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($uniqueValues unique values)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...topValues.entries.take(3).map((entry) {
                    final value = entry.key;
                    final count = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Text('• $value: $count occurrences'),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// Builds highlights for numeric columns.
  ///
  /// [numericStats] Map containing statistics for numeric columns.
  /// Returns a widget showing key statistics for numeric variables.
  Widget _buildNumericHighlights(Map<String, dynamic> numericStats) {
    // Select up to 2 numeric columns to show
    final columnsToShow = numericStats.keys.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          columnsToShow.map((columnName) {
            final columnStats = numericStats[columnName];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    columnName.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildStatItem('Min', columnStats['min']),
                        _buildStatItem('Max', columnStats['max']),
                        _buildStatItem('Mean', columnStats['mean']),
                        _buildStatItem('Median', columnStats['median']),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// Builds a single statistic display item.
  ///
  /// [label] The name of the statistic.
  /// [value] The value of the statistic.
  /// Returns a widget displaying a numeric statistic with its label.
  Widget _buildStatItem(String label, dynamic value) {
    final formattedValue =
        value is double
            ? (value > 100
                ? value.toStringAsFixed(1)
                : value.toStringAsFixed(2))
            : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          formattedValue,
          style: const TextStyle(fontWeight: FontWeight.bold),
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

    // Limit number of columns for very wide tables
    final maxColumnsToShow = 20;
    final displayColumns =
        columns.length > maxColumnsToShow
            ? columns.sublist(0, maxColumnsToShow)
            : columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (columns.length > maxColumnsToShow)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Showing ${displayColumns.length} of ${columns.length} columns',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            columns: List<DataColumn>.generate(
              displayColumns.length,
              (index) => DataColumn(
                label: Text(
                  displayColumns[index].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            rows: List<DataRow>.generate(preview.length, (rowIndex) {
              final row = preview[rowIndex] as Map<String, dynamic>;
              return DataRow(
                cells: List<DataCell>.generate(displayColumns.length, (
                  cellIndex,
                ) {
                  final colName = displayColumns[cellIndex].toString();
                  return DataCell(
                    Text(
                      row[colName]?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }
}
