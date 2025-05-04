import 'package:deep_sage/core/services/core_services/data_cleaning_services/data_cleaning_preview_service.dart';
import 'package:deep_sage/core/services/core_services/data_cleaning_services/data_cleaning_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import '../../../../core/services/core_services/data_preview_service.dart';
import '../../../../core/services/core_services/data_cleaning_services/missing_value_service.dart';

class DataCleaningTab extends StatefulWidget {
  final String? currentDataset;
  final String? currentDatasetPath;
  final String? currentDatasetType;

  const DataCleaningTab({
    super.key,
    this.currentDataset,
    this.currentDatasetPath,
    this.currentDatasetType,
  });

  @override
  State<DataCleaningTab> createState() => _DataCleaningTabState();
}

class _DataCleaningTabState extends State<DataCleaningTab>
    with SingleTickerProviderStateMixin {
  /// Method for handling null values. Defaults to 'nan' (Not a Number).
  String _nullMethod = 'nan';

  /// Controller for the text field used to fill null values for numeric columns.
  final TextEditingController _numericFillController = TextEditingController();

  /// Controller for the text field used to fill null values for categorical columns.
  final TextEditingController _categoricalFillController =
      TextEditingController();

  /// Default date value to fill in date-related null values. Defaults to the current date and time.
  DateTime _dateFillValue = DateTime.now();

  /// Tab controller for managing the different sections within the Data Cleaning tab.
  late TabController _tabController;

  /// Flag to enable or disable the fixing of numeric types. Defaults to false.
  bool _enableNumericFix = false;

  /// Confidence threshold for numeric type fixing. Defaults to 0.5.
  double _numericThreshold = 0.5;

  /// Flag to enable or disable parallel processing for certain operations. Defaults to false.
  bool _enableParallelProcessing = false;

  /// Flag to enable or disable date detection. Defaults to false.
  bool _enableDateDetection = false;

  /// Threshold for date detection confidence. Defaults to 0.5.
  double _dateThreshold = 0.5;

  /// Flag to enable or disable text cleaning operations. Defaults to false.
  bool _enableTextCleaning = false;

  /// Flag to enable or disable conversion of text to lowercase. Defaults to true.
  bool _convertToLowercase = true;

  /// Flag to enable or disable whitespace trimming in text. Defaults to true.
  bool _trimWhitespace = true;

  /// Flag to enable or disable removal of special characters from text. Defaults to false.
  bool _removeSpecialChars = false;

  /// Flag to enable or disable outlier handling. Defaults to false.
  bool _enableOutlierHandling = false;

  /// Method used for outlier detection (e.g., IQR, Z-score). Defaults to 'IQR'.
  String _outlierDetectionMethod = 'IQR';

  /// Threshold for outlier detection. Defaults to 1.5.
  double _outlierThreshold = 1.5;

  /// Action to be taken on detected outliers (e.g., 'Report only', 'Remove'). Defaults to 'Report only'.
  String _outlierAction = 'Report only';

  /// Flag to enable or disable duplicate removal. Defaults to false.
  bool _enableDuplicateRemoval = false;

  /// Strategy for handling duplicate rows (e.g., 'First occurrence', 'Last occurrence'). Defaults to 'First occurrence'.
  String _duplicateKeepStrategy = 'First occurrence';

  /// Flag to enable or disable categorical encoding. Defaults to false.
  bool _enableCategoricalEncoding = false;

  /// Method used for categorical encoding (e.g., 'One-hot', 'Label'). Defaults to 'One-hot'.
  String _encodingMethod = 'One-hot';

  /// Maximum number of categories for one-hot encoding. Defaults to 20.
  int _maxCategories = 20;

  /// Flag to enable or disable numeric scaling. Defaults to false.
  bool _enableNumericScaling = false;

  /// Method used for numeric scaling (e.g., 'Standard', 'Min-Max'). Defaults to 'Standard'.
  String _scalingMethod = 'Standard';

  /// Minimum range value for scaling. Defaults to 0.0.
  double _scalingMinRange = 0.0;

  /// Maximum range value for scaling. Defaults to 1.0.
  double _scalingMaxRange = 1.0;

  /// Flag to enable or disable column name standardization. Defaults to false.
  bool _enableColumnStandardization = false;

  /// Case style for column name standardization (e.g., 'Snake_case', 'camelCase'). Defaults to 'Snake_case'.
  String _columnCaseStyle = 'Snake_case';

  /// Flag to replace spaces in column names with underscores. Defaults to true.
  bool _replaceColumnSpaces = true;

  /// Flag to enable or disable value correction for inconsistent values. Defaults to false.
  bool _enableValueCorrection = false;

  /// Method used for value correction (e.g., 'Automatic clustering', 'Custom mapping'). Defaults to 'Automatic clustering'.
  String _valueCorrectionMethod = 'Automatic clustering';

  /// Similarity threshold for value correction. Defaults to 0.85.
  double _similarityThreshold = 0.85;

  /// Controller for the text field used to define custom value mappings.
  final TextEditingController _customMappingController =
      TextEditingController();

  /// Flag to enable or disable parallel processing globally. Defaults to false.
  bool _enableParallelGlobalProcessing = false;

  /// Flag indicating whether data processing should be done in-place (modifying the original dataset) or not.
  /// Defaults to true, meaning in-place processing is enabled.
  bool _enableInPlaceProcessing = true;

  /// Flag to determine whether the dataset preview feature is enabled.
  /// Defaults to true, meaning the preview is enabled.
  bool _enableDatasetPreview = true;

  /// Flag indicating if progress visualization_and_explorer (e.g., progress bars) should be displayed during operations.
  /// Defaults to true, meaning progress visualization_and_explorer is enabled.
  bool _enableProgressVisualization = true;

  /// Flag to enable or disable the generation of a detailed report after data cleaning.
  /// Defaults to false, meaning the report generation is disabled.
  bool _enableReportGeneration = false;

  /// Flag indicating whether metadata is currently being loaded.
  /// When true, UI should display a loading indicator for metadata-related components.
  bool _isLoadingMetadata = false;

  /// Contains statistics about missing values in the dataset.
  /// This map holds information like missing value counts, percentages, and column stats.
  Map<String, dynamic> _missingValueStats = {};

  /// Set of column names that the user has selected for cleaning operations.
  /// Operations will only be applied to these columns when this set is not empty.
  Set<String> _selectedColumns = {};

  /// Flag indicating whether a cleaning operation is currently being applied.
  /// Used to show loading state and disable UI controls during processing.
  bool isApplyingCleanOperation = false;

  /// Service for handling operations related to missing values in datasets.
  /// Provides functionality for detecting, filling, and reporting missing data.
  final MissingValuesService _missingValuesService = MissingValuesService();

  /// Service for generating and managing data previews.
  /// Handles retrieving samples of data for display in the UI.
  final DataPreviewService _dataPreviewService = DataPreviewService();

  /// Service for performing core data cleaning operations.
  /// Encapsulates logic for all data transformation and cleaning functions.
  final DataCleaningService _dataCleaningService = DataCleaningService();

  /// Preview of the dataset for display in the UI.
  /// Contains column names and a sample of rows from the dataset.
  Map<String, dynamic>? _dataPreview;

  /// Flag indicating whether data preview is currently being loaded.
  /// When true, UI should display a loading indicator in the preview area.
  bool isLoadingDataPreview = false;

  /// File path to the cleaned/processed dataset.
  /// Null when no cleaning operations have been applied yet.
  String? cleanedFilePath;

  /// Controller for text input fields used for regular expression operations.
  /// Used in pattern matching and text manipulation functions.
  final TextEditingController _regexController = TextEditingController();

  /// Flag that indicates whether a preview operation is currently in progress.
  /// When true, the UI should show a loading indicator.
  bool isLoadingPreview = false;

  /// Flag that indicates whether a cleaned data preview is ready to be displayed.
  /// Set to true after a successful preview operation completes.
  bool cleanedPreviewReady = false;

  /// Holds the preview data that shows before/after comparison of cleaning operations.
  /// Contains separate 'before' and 'after' datasets along with metadata about changes.
  Map<String, dynamic>? _previewData;

  /// Flag to determine if case-sensitive matching should be used for duplicates
  bool _caseSensitiveMatching = false;

  /// Set of columns selected for duplicate detection
  Set<String> _duplicateColumns = {};

  /// Flag indicating if duplicate preview is being loaded
  bool _isLoadingDuplicatePreview = false;

  /// Data containing preview of duplicates
  Map<String, dynamic>? _duplicatePreviewData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    if (widget.currentDatasetPath != null) {
      _fetchMissingValueStats();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numericFillController.dispose();
    _categoricalFillController.dispose();
    _regexController.dispose();
    _customMappingController.dispose();
    super.dispose();
  }

  /// Fetches and sets the missing value statistics for the current dataset.
  ///
  /// This asynchronous function retrieves metadata about missing values
  /// in the currently selected dataset using the `_dataCleaningService`.
  /// It first checks if a dataset path is available. If not, it returns
  /// immediately, doing nothing. If a dataset path is available, it sets
  /// the `_isLoadingMetadata` flag to true to indicate that data is being
  /// loaded.
  ///
  /// Upon successfully fetching the metadata, it updates the `_missingValueStats`
  /// state variable with the retrieved metadata and sets `_isLoadingMetadata` to
  /// false. If an error occurs during the fetch, it sets `_isLoadingMetadata`
  /// to false and displays a SnackBar with an error message.
  ///
  /// This function is typically called during the initialization phase to
  /// pre-load missing value information.
  Future<void> _fetchMissingValueStats() async {
    if (widget.currentDatasetPath == null) return;

    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      final metadata = await _dataCleaningService.getMetadata(
        widget.currentDatasetPath!,
      );
      setState(() {
        _missingValueStats = metadata;
        _isLoadingMetadata = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetadata = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching missing value stats: $e')),
      );
    }
  }

  /// Builds the indicator for the currently selected dataset.
  ///
  /// This widget dynamically displays information about the dataset being
  /// worked on, including its name, path, and file type. If no dataset is
  /// currently selected, it displays a message prompting the user to select one.
  ///
  /// The display varies based on the presence of a dataset:
  /// - If `widget.currentDataset` is null or empty, it shows an informational
  ///   message in a gray container with an info icon.
  /// - If `widget.currentDataset` is not null and not empty, it shows a
  ///   blue-themed container with the dataset name, an icon based on the file
  ///   type, and an optionally displayed file path.
  ///
  /// Returns a [Widget] that displays the current dataset information or a
  /// message to select a dataset. It adapts its appearance based on whether
  /// a dataset is active and the current theme's brightness.
  /// Builds the main widget for the Data Cleaning tab.
  ///
  /// This widget includes the header, tab bar, and the content for each tab.
  /// It also includes the bottom actions for applying cleaning operations.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Builds the header section of the Data Cleaning tab.
        _buildHeader(),
        const SizedBox(height: 8),
        _buildCurrentDatasetIndicator(),
        const SizedBox(height: 12),

        /// Builds the tab bar for navigating between different sections.
        _buildTabBar(),
        const SizedBox(height: 8),

        /// Builds the content for each tab in the Data Cleaning tab.
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBasicDataFixesTab(),
              _buildDataTypeImprovementsTab(),
              _buildDataTransformationsTab(),
              _buildDataQualityTab(),
              _buildOrganizationTab(),
              _buildSettingsTab(),
            ],
          ),
        ),

        /// Builds the bottom actions for applying cleaning operations.
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: _buildBottomActions(),
        ),
      ],
    );
  }

  /// Builds the header section of the Data Cleaning tab.
  ///
  /// This widget includes the title and a brief description of the tab's purpose.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Cleaning',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Make your data ready for analysis by fixing common problems',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the indicator for the currently selected dataset.
  ///
  /// This widget dynamically displays information about the dataset being
  /// worked on, including its name, path, and file type. If no dataset is
  /// currently selected, it displays a message prompting the user to select one.
  ///
  /// The display varies based on the presence of a dataset:
  /// - If `widget.currentDataset` is null or empty, it shows an informational
  ///   message in a gray container with an info icon.
  /// - If `widget.currentDataset` is not null and not empty, it shows a
  ///   blue-themed container with the dataset name, an icon based on the file
  ///   type, and an optionally displayed file path.
  ///
  /// Returns a [Widget] that displays the current dataset information or a
  /// message to select a dataset. It adapts its appearance based on whether
  /// a dataset is active and the current theme's brightness.
  ///
  /// The function uses helper methods:
  /// - [_getFileIcon]: Returns the appropriate icon based on the file type.
  /// - [_getFileColor]: Returns the color associated with the file type.
  /// - [_getDisplayPath]: Shortens the file path for display purposes.
  Widget _buildCurrentDatasetIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (widget.currentDataset == null || widget.currentDataset!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.grey.shade800.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              Text(
                'No dataset selected. Please select a dataset from the sidebar.',
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Colors.blue.shade900.withValues(alpha: 0.2)
                  : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade400, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIcon(widget.currentDatasetType ?? ''),
              color: _getFileColor(widget.currentDatasetType ?? ''),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Working with: ${widget.currentDataset}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade800,
                    ),
                  ),
                  if (widget.currentDatasetPath != null)
                    Text(
                      _getDisplayPath(widget.currentDatasetPath!),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the appropriate icon based on the file type.
  ///
  /// This method maps common file types (csv, json, xlsx) to their
  /// corresponding Material Design icons. If the file type does not match
  /// any known type, it defaults to a generic file icon.
  ///
  /// [fileType] The type of the file (e.g., 'csv', 'json', 'xlsx').
  ///
  /// Returns an [IconData] representing the file type.
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

  /// Returns the appropriate color associated with the file type.
  ///
  /// This method maps common file types (csv, json, xlsx) to specific
  /// colors to visually differentiate them. If the file type is not known,
  /// it defaults to gray.
  ///
  /// [fileType] The type of the file (e.g., 'csv', 'json', 'xlsx').
  ///
  /// Returns a [Color] associated with the file type.
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

  /// Shortens a file path for display if it's longer than 60 characters.
  ///
  /// This method checks the length of the input path. If it exceeds 60
  /// characters, it returns an abbreviated version that includes "..." at
  /// the start, the second-to-last part, and the last part of the path. If
  /// the path has 3 or fewer parts, or its length is less than 60, it returns
  /// the original path.
  ///
  /// [path] The full file path to potentially shorten.
  /// Returns a [String] representing the shortened or original path.
  String _getDisplayPath(String path) {
    if (path.length <= 60) return path;

    final pathParts = path.split('/');
    if (pathParts.length <= 3) return path;

    return '.../${pathParts[pathParts.length - 2]}/${pathParts.last}';
  }

  /// Builds a card widget for a specific data cleaning operation.
  ///
  /// The card includes a title, description, icon, and expandable content.
  ///
  /// [title] The title of the cleaning operation.
  /// [description] A brief description of the cleaning operation.
  /// [icon] The icon representing the cleaning operation.
  /// [content] The widget content to be displayed when the card is expanded.
  Widget _buildCleaningCard({
    required String title,
    required String description,
    required IconData icon,
    required Widget content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          initiallyExpanded: title == 'Null Value Handling',
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [content],
        ),
      ),
    );
  }

  /// Builds the UI content for handling null values in the dataset.
  ///
  /// This widget creates a column containing controls for configuring how to handle
  /// null values in the dataset:
  /// - A dropdown to select the fill method (e.g., leave as NaN, fill with 0, mean, median, mode, custom values)
  /// - If custom values are selected, additional text fields for numeric and categorical fills
  /// - A date picker for selecting a default date fill value
  /// - A section for displaying missing value statistics if available
  /// - A button to apply the missing value cleaning operation
  ///
  /// Returns a [Widget] containing the complete null value handling configuration UI.
  Widget _buildNullValueContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _isLoadingMetadata
            ? const Center(child: CircularProgressIndicator())
            : _buildMissingValueStats(),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Fill method',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          value: _nullMethod,
          items: const [
            DropdownMenuItem(value: 'nan', child: Text('Leave as NaN')),
            DropdownMenuItem(value: 'zero', child: Text('Fill with 0')),
            DropdownMenuItem(value: 'mean', child: Text('Fill with mean')),
            DropdownMenuItem(value: 'median', child: Text('Fill with median')),
            DropdownMenuItem(value: 'mode', child: Text('Fill with mode')),
            DropdownMenuItem(value: 'custom', child: Text('Custom values')),
          ],
          onChanged: (newValue) {
            setState(() {
              _nullMethod = newValue!;
            });
          },
        ),

        if (_nullMethod == 'custom') ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _numericFillController,
                  decoration: InputDecoration(
                    labelText: 'Numeric fill',
                    hintText: 'e.g., 0.0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _categoricalFillController,
                  decoration: InputDecoration(
                    labelText: 'Categorical fill',
                    hintText: 'e.g., unknown',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Date fill value',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _dateFillValue,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _dateFillValue = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_dateFillValue.toLocal()}'.split(' ')[0]),
                  const Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        if (_missingValueStats.isNotEmpty &&
            _missingValueStats.containsKey('columns'))
          _buildColumnSelectionSection(),

        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _applyMissingValueCleaning,
          icon: const Icon(Icons.healing),
          label: const Text('Apply Missing Value Cleaning'),
        ),
      ],
    );
  }

  /// Applies cleaning operations to handle missing values in the dataset.
  ///
  /// This method orchestrates the missing value cleaning process by:
  /// 1. Validating that a dataset is currently selected
  /// 2. Preparing custom values if the 'custom' method is selected
  /// 3. Updating UI to show a loading state
  /// 4. Calling the service to perform the cleaning operation
  /// 5. Storing the path to the cleaned file for future operations
  /// 6. Loading a preview of the cleaned data
  /// 7. Showing success or error notifications to the user
  ///
  /// The method handles different cleaning strategies based on the selected
  /// [_nullMethod] and provides appropriate feedback throughout the process.
  ///
  /// Throws an exception if the cleaning operation fails, which is caught
  /// and displayed to the user.
  Future<void> _applyMissingValueCleaning() async {
    if (widget.currentDatasetPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No dataset selected')));
      return;
    }

    Map<String, dynamic>? customValues;
    if (_nullMethod == 'custom') {
      customValues = {
        'numeric':
            _numericFillController.text.isEmpty
                ? 0
                : double.tryParse(_numericFillController.text) ?? 0,
        'categorical':
            _categoricalFillController.text.isEmpty
                ? 'unknown'
                : _categoricalFillController.text,
        'datetime': _dateFillValue.toIso8601String(),
      };
    }

    setState(() {
      isApplyingCleanOperation = true;
    });

    try {
      final cleanedPath = await _missingValuesService.cleanMissingValues(
        filePath: widget.currentDatasetPath!,
        method: _nullMethod,
        customValues: customValues,
        selectedColumns:
            _selectedColumns.isEmpty ? null : _selectedColumns.toList(),
      );

      // Store the cleaned file path for potential future operations
      cleanedFilePath = cleanedPath;

      // Load preview of cleaned data
      await _loadDataPreview(cleanedPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully cleaned missing values')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying cleaning: $e')));
    } finally {
      setState(() {
        isApplyingCleanOperation = false;
      });
    }
  }

  /// Loads a preview of the specified dataset file.
  ///
  /// This asynchronous method attempts to load a preview of the data from the
  /// provided [filePath]. It manages loading state via [isLoadingDataPreview]
  /// to indicate when a preview operation is in progress.
  ///
  /// The preview uses the [DataPreviewService] to fetch a small sample (up to 10 rows)
  /// of the dataset, maintaining the correct format based on the dataset type.
  ///
  /// Parameters:
  /// - [filePath]: The path to the dataset file to preview
  ///
  /// The method handles errors gracefully by logging them with [debugPrint]
  /// without interrupting the UI flow, and ensures the loading state is always
  /// reset even if an error occurs.
  ///
  /// Sets [_dataPreview] with the preview data when successful.
  Future<void> _loadDataPreview(String filePath) async {
    setState(() {
      isLoadingDataPreview = true;
    });

    try {
      final preview = await _dataPreviewService.loadDatasetPreview(
        filePath,
        widget.currentDatasetType ?? 'csv',
        10,
      );
      debugPrint('_dataPreview: $_dataPreview');
      setState(() {
        _dataPreview = preview;
      });
    } catch (e) {
      debugPrint('Error loading data preview: $e');
    } finally {
      setState(() {
        isLoadingDataPreview = false;
      });
    }
  }

  /// Builds and returns a widget displaying missing value statistics for the dataset.
  ///
  /// This method visualizes the analysis of missing values in the current dataset.
  /// It has three possible states:
  /// 1. If [_missingValueStats] is empty, displays a message indicating no statistics are available
  /// 2. If there are no columns with missing values, shows a success message with a green indicator
  /// 3. Otherwise, displays a detailed table showing which columns have missing values,
  ///    their data types, count and percentage of missing values
  ///
  /// The detailed table includes:
  /// - Column names
  /// - Data types
  /// - Absolute count of missing values per column
  /// - Percentage of missing values relative to the total row count
  ///
  /// The table is horizontally scrollable to accommodate datasets with many columns.
  ///
  /// Returns a Widget containing either a message about the state of missing values
  /// or a detailed table of missing value statistics.
  Widget _buildMissingValueStats() {
    if (_missingValueStats.isEmpty) {
      return const Center(child: Text('No missing value statistics available'));
    }

    final columns = List<Map<String, dynamic>>.from(
      _missingValueStats['columns'] ?? [],
    );
    final columnsWithMissingValues =
        columns.where((col) => (col['missing_values'] ?? 0) > 0).toList();

    if (columnsWithMissingValues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          color: Colors.green.withValues(alpha: 0.1),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('No missing values detected in this dataset!'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Missing Values Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('Column')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Missing Values')),
                DataColumn(label: Text('% Missing')),
              ],
              rows:
                  columnsWithMissingValues.map((col) {
                    final totalRows = _missingValueStats['num_rows'] ?? 1;
                    final missingCount = col['missing_values'] ?? 0;
                    final percentMissing = (missingCount / totalRows * 100)
                        .toStringAsFixed(1);

                    return DataRow(
                      cells: [
                        DataCell(Text(col['name'] ?? '')),
                        DataCell(Text(col['type'] ?? '')),
                        DataCell(Text('$missingCount')),
                        DataCell(Text('$percentMissing%')),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a section for selecting columns with missing values that need cleaning.
  ///
  /// This method creates a UI component containing:
  /// - A title label identifying the section
  /// - A wrap layout with [FilterChip] widgets for each column that has missing values
  /// - "Select All" and "Clear Selection" buttons for batch selection operations
  ///
  /// The method filters the columns list to only show those with missing values,
  /// making it easier for users to identify and select columns that need attention.
  /// Each column can be individually toggled by tapping its chip.
  ///
  /// Returns a [Widget] (Column) containing the column selection interface.
  Widget _buildColumnSelectionSection() {
    final columns = List<Map<String, dynamic>>.from(
      _missingValueStats['columns'] ?? [],
    );
    final columnsWithMissingValues =
        columns.where((col) => (col['missing_values'] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select columns to clean:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              columnsWithMissingValues.map((col) {
                final columnName = col['name'] as String;
                final isSelected = _selectedColumns.contains(columnName);

                return FilterChip(
                  label: Text(columnName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedColumns.add(columnName);
                      } else {
                        _selectedColumns.remove(columnName);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedColumns = Set<String>.from(
                    columnsWithMissingValues.map(
                      (col) => col['name'] as String,
                    ),
                  );
                });
              },
              child: const Text('Select All'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedColumns = {};
                });
              },
              child: const Text('Clear Selection'),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the UI for numeric type correction options.
  ///
  /// This widget returns a Column widget that includes a SwitchListTile
  /// to enable or disable numeric type fixing. When enabled, it displays a
  /// Slider to adjust the confidence threshold for numeric type conversion
  /// and an option to enable parallel processing for the operation.
  Widget _buildNumericTypeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable numeric type fixing'),
          value: _enableNumericFix,
          onChanged: (value) {
            setState(() {
              _enableNumericFix = value;
            });
          },
        ),
        if (_enableNumericFix) ...[
          Row(
            children: [
              const Expanded(flex: 2, child: Text('Confidence threshold:')),
              Expanded(
                flex: 3,
                child: Slider(
                  value: _numericThreshold,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: _numericThreshold.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _numericThreshold = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _numericThreshold.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable parallel processing'),
            subtitle: const Text('Faster but uses more resources'),
            value: _enableParallelProcessing,
            onChanged: (value) {
              setState(() {
                _enableParallelProcessing = value;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Builds the UI content for date detection settings.
  ///
  /// This widget creates a column containing controls for configuring date detection:
  /// - A switch to enable/disable date detection functionality
  /// - A slider to adjust the confidence threshold for date detection (when enabled)
  ///
  /// The date detection threshold ranges from 0.0 to 1.0 with 20 divisions.
  /// Higher threshold values require more confidence in date pattern matching.
  Widget _buildDateDetectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable date detection'),
          value: _enableDateDetection,
          onChanged: (value) {
            setState(() {
              _enableDateDetection = value;
            });
          },
        ),
        if (_enableDateDetection) ...[
          Row(
            children: [
              const Expanded(flex: 2, child: Text('Detection threshold:')),
              Expanded(
                flex: 3,
                child: Slider(
                  value: _dateThreshold,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: _dateThreshold.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _dateThreshold = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _dateThreshold.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds the UI content for text cleaning settings.
  ///
  /// This widget creates a column containing controls for text cleaning configuration:
  /// - A switch to enable/disable text cleaning functionality
  /// - When enabled, displays a card with the following options:
  ///   * Convert text to lowercase
  ///   * Trim leading/trailing whitespace
  ///   * Remove special characters
  /// - A text field for custom regex pattern input for advanced cleaning
  ///
  /// The card uses the surface container color with reduced opacity for visual hierarchy.
  /// Each cleaning option is presented as a checkbox list tile with dividers between them.
  /// The regex text field includes helper text explaining its purpose.
  Widget _buildTextCleaningContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable text cleaning'),
          value: _enableTextCleaning,
          onChanged: (value) {
            setState(() {
              _enableTextCleaning = value;
            });
          },
        ),
        if (_enableTextCleaning) ...[
          Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  dense: true,
                  title: const Text('Convert to lowercase'),
                  value: _convertToLowercase,
                  onChanged: (value) {
                    setState(() {
                      _convertToLowercase = value!;
                    });
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Trim whitespace'),
                  value: _trimWhitespace,
                  onChanged: (value) {
                    setState(() {
                      _trimWhitespace = value!;
                    });
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Remove special characters'),
                  value: _removeSpecialChars,
                  onChanged: (value) {
                    setState(() {
                      _removeSpecialChars = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _regexController,
            decoration: InputDecoration(
              labelText: 'Custom regex pattern',
              hintText: 'e.g., [^a-zA-Z0-9]',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              helperText: 'Advanced: Define a custom pattern for text cleaning',
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the bottom actions section of the Data Cleaning tab.
  ///
  /// Creates a container with a filled button that allows users to apply
  /// all the selected cleaning operations to their dataset. The button
  /// includes both an icon (auto_fix_high) and text to clearly indicate
  /// its purpose.
  ///
  /// Returns a [Widget] containing the action button with appropriate padding.
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => _previewMissingValueCleaning(),
            icon: const Icon(Icons.visibility_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Preview Changes'),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_fix_high),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Apply Cleaning Operations'),
            ),
          ),
        ],
      ),
    );
  }

  /// Retrieves a list of currently active cleaning operations based on the selected
  /// options in the UI.
  ///
  /// This method checks the state of each cleaning operation's configuration and
  /// assembles a list of strings describing the active operations and their
  /// respective parameters. This list is then used to provide a preview of the
  /// operations that will be applied to the dataset.
  ///
  /// The method checks for the following operations:
  /// - Handling of null values (missing data).
  /// - Removal of duplicate rows.
  /// - Correction of inconsistent values.
  /// - Conversion of text to numbers.
  /// - Detection and formatting of dates.
  /// - Cleaning of text (e.g., lowercasing, trimming, special character removal).
  /// - Encoding of categorical data.
  List<String> _getActiveOperations() {
    List<String> operations = [];

    // Check each enabled operation
    if (_nullMethod != 'nan') {
      operations.add(
        'Fix Missing Values: ${_nullMethod == 'custom' ? 'Custom values' : _nullMethod}',
      );
    }

    if (_enableDuplicateRemoval) {
      operations.add('Remove Duplicates: Keep $_duplicateKeepStrategy');
    }

    if (_enableValueCorrection) {
      operations.add('Fix Spelling Mistakes: $_valueCorrectionMethod');
    }

    if (_enableNumericFix) {
      operations.add('Convert Text to Numbers: Threshold $_numericThreshold');
    }

    if (_enableDateDetection) {
      operations.add('Find and Format Dates: Threshold $_dateThreshold');
    }

    if (_enableTextCleaning) {
      operations.add('Clean Text: ${_getTextCleaningDetails()}');
    }

    if (_enableCategoricalEncoding) {
      operations.add('Convert Categories: $_encodingMethod encoding');
    }

    if (_enableNumericScaling) {
      operations.add('Scale Numbers: $_scalingMethod scaling');
    }

    if (_enableOutlierHandling) {
      operations.add(
        'Handle Outliers: $_outlierDetectionMethod method, $_outlierAction',
      );
    }

    if (_enableColumnStandardization) {
      operations.add('Clean Column Names: $_columnCaseStyle style');
    }

    return operations;
  }

  /// Creates a detailed string description of the current text cleaning options.
  ///
  /// This method checks the state of each text cleaning option (convert to lowercase,
  /// trim whitespace, remove special characters) and generates a comma-separated
  /// string of the enabled options. This string is used to provide a preview of
  /// the text cleaning operations that will be applied.
  ///
  /// Returns a [String] containing a comma-separated list of enabled text cleaning
  /// operations. If no options are enabled, returns an empty string.
  String _getTextCleaningDetails() {
    List<String> details = [];
    if (_convertToLowercase) details.add('lowercase');
    if (_trimWhitespace) details.add('trim spaces');
    if (_removeSpecialChars) details.add('remove special chars');
    return details.join(', ');
  }

  /// Builds a data preview table for both "before" and "after" states of data cleaning.
  ///
  /// This method constructs a DataTable widget wrapped within scrollable views to
  /// display a sample of data. The table is dynamically generated based on whether
  /// the preview is for the "before" state (original data) or the "after" state
  /// (data after applying cleaning operations).
  ///
  /// The table includes columns for 'id', 'product name', 'price', 'discount %', and
  /// 'date added', with sample rows to illustrate potential changes in the data.
  ///
  /// The table is designed to handle:
  /// - Horizontal and vertical scrolling for large datasets.
  /// - Visual differentiation between "before" and "after" states of the data.
  /// - Displaying indicators for missing values, duplicates, and type corrections.
  ///
  /// [isBefore] A boolean flag indicating whether to display the "before" or "after" data preview.
  Widget buildDataPreview({required bool isBefore}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            columns: [
              DataColumn(label: Text(isBefore ? 'id' : 'id')),
              DataColumn(
                label: Text(isBefore ? 'product name' : 'product_name'),
              ),
              DataColumn(label: Text(isBefore ? 'price' : 'price')),
              DataColumn(label: Text(isBefore ? 'discount %' : 'discount_pct')),
              DataColumn(label: Text(isBefore ? 'date added' : 'date_added')),
            ],
            rows: [
              _buildPreviewRow(
                isBefore: isBefore,
                id: '1',
                productName: isBefore ? 'Laptop' : 'laptop',
                price: isBefore ? '1299.99' : '1299.99',
                discount: isBefore ? '10' : '10.0',
                date: isBefore ? '01/05/2023' : '2023-01-05',
                hasNull: false,
              ),
              _buildPreviewRow(
                isBefore: isBefore,
                id: '2',
                productName: isBefore ? 'Smart Phone' : 'smart_phone',
                price: isBefore ? '799.0' : '799.0',
                discount: isBefore ? null : '0.0',
                date: isBefore ? '02/17/2023' : '2023-02-17',
                hasNull: true,
              ),
              _buildPreviewRow(
                isBefore: isBefore,
                id: '3',
                productName: isBefore ? 'HeadPhones' : 'headphones',
                price: isBefore ? '99.99' : '99.99',
                discount: isBefore ? '15' : '15.0',
                date: isBefore ? '03/10/2023' : '2023-03-10',
                hasNull: false,
              ),
              _buildPreviewRow(
                isBefore: isBefore,
                id: '2',
                productName:
                    isBefore
                        ? 'Smart phone'
                        : isBefore
                        ? 'Smart phone'
                        : '<removed duplicate>',
                price:
                    isBefore
                        ? '799.0'
                        : isBefore
                        ? '799.0'
                        : '',
                discount:
                    isBefore
                        ? '5'
                        : isBefore
                        ? '5'
                        : '',
                date:
                    isBefore
                        ? '02/18/2023'
                        : isBefore
                        ? '02/18/2023'
                        : '',
                hasNull: false,
                isDuplicate: !isBefore,
              ),
              _buildPreviewRow(
                isBefore: isBefore,
                id: '4',
                productName: isBefore ? 'Tablet' : 'tablet',
                price: isBefore ? 'one thousand' : '1000.0',
                discount: isBefore ? '20' : '20.0',
                date: isBefore ? '04/22/2023' : '2023-04-22',
                hasNull: false,
                hasTextAsNumber: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates a preview of how missing value cleaning will affect the dataset.
  ///
  /// This asynchronous method provides a before/after comparison of the data
  /// without actually modifying the original dataset. It follows these steps:
  ///
  /// 1. Validates that a dataset is currently selected, returning early with
  ///    an error message if not.
  /// 2. Verifies that at least one column has been selected for cleaning,
  ///    returning early with an error message if not.
  /// 3. Prepares custom values if the 'custom' method is selected.
  /// 4. Updates UI to show a loading state.
  /// 5. Calls the preview service to generate a sample of the data
  ///    both before and after the cleaning operation.
  /// 6. Updates the state with the preview data.
  /// 7. Shows a dialog with the comparison preview.
  /// 8. Handles errors by displaying appropriate messages.
  /// 9. Always resets the loading state when complete.
  ///
  /// The preview is limited to 10 rows by default to optimize performance.
  ///
  /// Throws exceptions if the preview operation fails, which are caught
  /// and presented to the user via a SnackBar.
  Future<void> _previewMissingValueCleaning() async {
    if (widget.currentDatasetPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No dataset selected')));
      return;
    }

    if (_selectedColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one column to clean'),
        ),
      );
      return;
    }

    Map<String, dynamic>? customValues;
    if (_nullMethod == 'custom') {
      customValues = {
        'numeric':
            _numericFillController.text.isEmpty
                ? 0
                : double.tryParse(_numericFillController.text) ?? 0,
        'categorical':
            _categoricalFillController.text.isEmpty
                ? 'unknown'
                : _categoricalFillController.text,
        'datetime': _dateFillValue.toIso8601String(),
      };
    }

    setState(() {
      isLoadingPreview = true;
    });

    try {
      final previewService = DataCleaningPreviewService(
        baseUrl: 'http://localhost:5000',
      );

      final previewData = await previewService.previewMissingValueCleaning(
        filePath: widget.currentDatasetPath!,
        method: _nullMethod,
        customValues: customValues,
        selectedColumns: _selectedColumns.toList(),
        // Convert set to list
        limit: 10,
      );

      debugPrint('previewData: $previewData');

      setState(() {
        _previewData = previewData;
        cleanedPreviewReady = true;
      });

      _showDataPreviewDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating preview: $e')));
    } finally {
      setState(() {
        isLoadingPreview = false;
      });
    }
  }

  /// Displays a dialog that previews the data before and after cleaning operations.
  ///
  /// This method creates a rich, interactive dialog that allows users to visualize the
  /// effects of data cleaning operations before committing to them. The dialog features:
  ///
  /// * A summary of the affected rows and cleaning operations
  /// * Toggle between split view (before/after side by side) and unified view
  /// * Visual highlighting of changes between original and cleaned data
  /// * Lists of affected columns and active operations
  /// * Options to apply or cancel the changes
  ///
  /// The method requires [_previewData] to be populated with the "before" and "after"
  /// data samples, typically from a call to [_previewMissingValueCleaning].
  ///
  /// If [_previewData] is null, the method returns early without showing anything.
  /// If the before or after data arrays are empty, a snackbar message is displayed.
  ///
  /// The dialog performs comparisons between before and after rows to identify which
  /// columns were affected by the cleaning operations, and provides appropriate visual
  /// feedback.
  void _showDataPreviewDialog() {
    if (_previewData == null) return;

    final beforeRows = List<Map<String, dynamic>>.from(
      _previewData!['before'] ?? [],
    );
    final afterRows = List<Map<String, dynamic>>.from(
      _previewData!['after'] ?? [],
    );
    final affectedRows = _previewData!['affected_rows'] ?? 0;
    final sampledRows = _previewData!['sampled_rows'] ?? 0;
    final message = _previewData!['message'] ?? '';

    if (beforeRows.isEmpty || afterRows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    // Identify affected columns (columns that have changes)
    final allColumns = beforeRows.first.keys.toList();
    Set<String> affectedColumns = {};

    // Compare before and after to find columns with changes
    for (int i = 0; i < beforeRows.length; i++) {
      for (String column in allColumns) {
        if (beforeRows[i][column] != afterRows[i][column]) {
          affectedColumns.add(column);
        }
      }
    }

    // If no columns are affected, use the selected columns or all columns
    if (affectedColumns.isEmpty) {
      if (_selectedColumns.isNotEmpty) {
        affectedColumns = Set.from(_selectedColumns);
      } else {
        affectedColumns = Set.from(allColumns);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes were detected in the data preview'),
          ),
        );
      }
    }

    // Get active operations
    final activeOperations = _getActiveOperations();

    // Track current view mode (split or unified)
    bool splitView = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog header with title and close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Data Cleaning Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // View mode selector
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Split View'),
                          icon: Icon(Icons.vertical_split),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Unified View'),
                          icon: Icon(Icons.view_agenda),
                        ),
                      ],
                      selected: {splitView},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          splitView = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Summary statistics with highlighting
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                '$affectedRows rows affected',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      affectedRows > 0
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress indicator showing percentage of affected rows
                          if (sampledRows > 0) ...[
                            LinearProgressIndicator(
                              value: affectedRows / sampledRows,
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Showing $sampledRows sample rows (${(affectedRows / sampledRows * 100).toStringAsFixed(1)}% affected)',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active operations section
                    if (activeOperations.isNotEmpty) ...[
                      Text(
                        'Active Operations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            activeOperations
                                .map(
                                  (op) => Chip(
                                    label: Text(op),
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Column names that were affected
                    if (affectedColumns.isNotEmpty) ...[
                      Text(
                        'Affected Columns',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            affectedColumns
                                .map(
                                  (col) => Chip(
                                    label: Text(col),
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.tertiaryContainer,
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Data preview tables
                    Expanded(
                      child:
                          splitView
                              ? _buildSplitView(
                                beforeRows,
                                afterRows,
                                affectedColumns.toList(),
                              )
                              : _buildUnifiedView(
                                beforeRows,
                                afterRows,
                                affectedColumns.toList(),
                              ),
                    ),

                    // Bottom actions
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyMissingValueCleaning();
                          },
                          child: const Text('Apply Changes'),
                        ),
                      ],
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

  /// Builds a split view showing both before and after data cleaning states side by side.
  ///
  /// This widget creates a horizontal split layout with two tables:
  /// - Left side shows the original data ("Before" state)
  /// - Right side shows the cleaned data ("After" state)
  ///
  /// Each side has its own header with an appropriate icon and styling to visually
  /// differentiate between the before and after states.
  ///
  /// Parameters:
  /// - [beforeRows]: List of maps representing the original data before cleaning
  /// - [afterRows]: List of maps representing the data after cleaning operations
  /// - [columns]: List of column names to display in the tables, typically focuses
  ///   on columns that were affected by cleaning operations
  ///
  /// Returns a [Widget] containing the side-by-side comparison view with appropriate
  /// styling and headers.
  Widget _buildSplitView(
    List<Map<String, dynamic>> beforeRows,
    List<Map<String, dynamic>> afterRows,
    List<String> columns,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Before',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPreviewTable(
                  columns: columns,
                  rows: beforeRows,
                  compareRows: afterRows,
                  isBefore: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'After',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPreviewTable(
                  columns: columns,
                  rows: afterRows,
                  compareRows: beforeRows,
                  isBefore: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a unified view that shows before and after data changes in a single table.
  ///
  /// This widget creates a column containing a header and an expanded table view that
  /// visualizes the differences between the original and cleaned datasets side by side.
  /// The unified view is designed to help users easily identify which values have been
  /// modified by the cleaning operations.
  ///
  /// Parameters:
  /// * [beforeRows] - A list of maps representing the original dataset rows before cleaning
  /// * [afterRows] - A list of maps representing the dataset rows after cleaning operations
  /// * [columns] - A list of column names to display in the table, typically focusing on
  ///   columns that have been affected by cleaning operations
  ///
  /// Returns a [Column] widget containing a styled header and the unified preview table.
  /// The header has a tertiary color scheme to distinguish it from split view headers.
  Widget _buildUnifiedView(
    List<Map<String, dynamic>> beforeRows,
    List<Map<String, dynamic>> afterRows,
    List<String> columns,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.compare_arrows,
                size: 16,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Changes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildUnifiedPreviewTable(
            columns: columns,
            beforeRows: beforeRows,
            afterRows: afterRows,
          ),
        ),
      ],
    );
  }

  /// Builds a data preview table for comparing dataset values.
  ///
  /// This method creates a scrollable data table that displays dataset values and
  /// highlights changes between the original and processed data. It is used in both
  /// the "before" and "after" views of the data cleaning preview dialog.
  ///
  /// Features:
  /// - Highlights cells with changed values (red for before, green for after)
  /// - Shows tooltips for column names that might be truncated
  /// - Adds visual indicators (arrow icon) for new values
  /// - Applies appropriate text styling (strikethrough for old values, bold for changes)
  /// - Handles null and empty values with descriptive placeholders
  /// - Provides horizontal and vertical scrolling for large datasets
  ///
  /// Parameters:
  /// - [columns]: List of column names to display
  /// - [rows]: List of data rows to display in the table
  /// - [compareRows]: Reference data to compare against for highlighting changes
  /// - [isBefore]: Whether this table shows the "before" state (true) or "after" state (false)
  ///
  /// Returns a Container widget containing the formatted data table with appropriate styling.
  Widget _buildPreviewTable({
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
    required List<Map<String, dynamic>> compareRows,
    required bool isBefore,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            columnSpacing: 16,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 56,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            columns:
                columns.map((column) {
                  return DataColumn(
                    label: Tooltip(
                      message: column,
                      child: Text(
                        column,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
            rows: List<DataRow>.generate(
              rows.length,
              (rowIndex) => DataRow(
                cells:
                    columns.map((column) {
                      // Extract values from both datasets for comparison
                      final value = rows[rowIndex][column];
                      final compareValue = compareRows[rowIndex][column];
                      final isChanged = value != compareValue;

                      // Format the displayed value appropriately
                      String displayValue =
                          (value == null)
                              ? 'null'
                              : (value == '')
                              ? '(empty)'
                              : value.toString();

                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          // Apply highlighting background for changed cells
                          decoration:
                              isChanged
                                  ? BoxDecoration(
                                    color:
                                        (isBefore
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.green.withValues(
                                              alpha: 0.1,
                                            )),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                  : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show an arrow indicator for new values
                              if (isChanged && !isBefore)
                                Icon(
                                  Icons.arrow_right_alt,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                              Flexible(
                                child: Text(
                                  displayValue,
                                  style: TextStyle(
                                    // Make changed values bold
                                    fontWeight:
                                        isChanged
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    // Use red for removed values, green for new values
                                    color:
                                        isChanged
                                            ? (isBefore
                                                ? Colors.red.shade700
                                                : Colors.green.shade700)
                                            : null,
                                    // Apply strikethrough to old values being replaced
                                    decoration:
                                        isChanged && isBefore
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a unified view data table showing both before and after values in a single table.
  ///
  /// This widget creates a table that shows changes between the before and after datasets
  /// in a unified view, with changes highlighted inline. Each changed value shows both
  /// the original value (struck through in red) and the new value (in bold green).
  ///
  /// Parameters:
  /// - [columns]: List of column names to display in the table
  /// - [beforeRows]: List of maps containing the original data rows
  /// - [afterRows]: List of maps containing the modified data after cleaning
  ///
  /// Returns a scrollable [Container] with a [DataTable] showing the unified comparison view.
  Widget _buildUnifiedPreviewTable({
    required List<String> columns,
    required List<Map<String, dynamic>> beforeRows,
    required List<Map<String, dynamic>> afterRows,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            columnSpacing: 16,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 56,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            columns: [
              const DataColumn(label: Text('Row')),
              const DataColumn(label: Text('Status')),
              ...columns.map((column) {
                return DataColumn(
                  label: Tooltip(
                    message: column,
                    child: Text(
                      column,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ],
            rows: List<DataRow>.generate(beforeRows.length, (rowIndex) {
              // Determine if this row has any changes
              bool hasChanges = false;
              for (final column in columns) {
                if (beforeRows[rowIndex][column] !=
                    afterRows[rowIndex][column]) {
                  hasChanges = true;
                  break;
                }
              }

              return DataRow(
                color:
                    hasChanges
                        ? WidgetStateProperty.all(
                          Theme.of(context).colorScheme.tertiaryContainer
                              .withValues(alpha: 0.1),
                        )
                        : null,
                cells: [
                  // Row number
                  DataCell(Text('${rowIndex + 1}')),
                  // Status cell
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            hasChanges
                                ? Colors.amber.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasChanges ? 'Changed' : 'Unchanged',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              hasChanges
                                  ? Colors.amber.shade900
                                  : Colors.grey.shade700,
                          fontWeight:
                              hasChanges ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  // Data columns
                  ...columns.map((column) {
                    final beforeValue = beforeRows[rowIndex][column];
                    final afterValue = afterRows[rowIndex][column];
                    final isChanged = beforeValue != afterValue;

                    // Format the displayed values
                    String beforeDisplay =
                        (beforeValue == null)
                            ? 'null'
                            : (beforeValue == '')
                            ? '(empty)'
                            : beforeValue.toString();

                    String afterDisplay =
                        (afterValue == null)
                            ? 'null'
                            : (afterValue == '')
                            ? '(empty)'
                            : afterValue.toString();

                    return DataCell(
                      isChanged
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.remove,
                                    size: 12,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    beforeDisplay,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 12,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    afterDisplay,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          : Text(beforeDisplay),
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Builds a single data row for the data preview table.
  ///
  /// This method creates a [DataRow] widget that represents a single row in
  /// the data preview table. It is used to display sample data and highlight
  /// any changes or special conditions, such as missing values, duplicates, or
  /// corrected values.
  ///
  /// Each row contains cells for 'id', 'productName', 'price', 'discount', and
  /// 'date'. The display of these cells is styled based on the following:
  /// - [isDuplicate]: If true and `isBefore` is false, the row is styled to
  ///   indicate it as a removed duplicate.
  /// - [hasNull]: If true and `isBefore` is true, the discount cell is styled
  ///   to indicate a missing value.
  /// - [hasTextAsNumber]: If true and `isBefore` is false, the price cell is
  ///   styled to indicate a corrected numeric value.
  ///
  /// [isBefore] - Indicates whether this is a "before" or "after" preview row.
  /// [id] - The unique identifier of the row.
  /// [productName] - The name of the product in this row.
  /// [price] - The price value, may be null or a string representation.
  /// [discount] - The discount value, may be null or a string representation.
  /// [date] - The date value for this row.
  /// [hasNull] - Indicates whether a missing value should be highlighted.
  /// [isDuplicate] - Indicates whether this row is a duplicate and should be styled as such.
  /// [hasTextAsNumber] - Indicates if a text value was converted to a number and should be highlighted.
  DataRow _buildPreviewRow({
    required bool isBefore,
    required String id,
    required String productName,
    required String? price,
    required String? discount,
    required String date,
    required bool hasNull,
    bool isDuplicate = false,
    bool hasTextAsNumber = false,
  }) {
    final TextStyle? baseStyle =
        isDuplicate && !isBefore
            ? const TextStyle(
              color: Colors.red,
              decoration: TextDecoration.lineThrough,
            )
            : null;

    return DataRow(
      color:
          isDuplicate && !isBefore
              ? WidgetStateProperty.all(Colors.red.withValues(alpha: 0.1))
              : null,
      cells: [
        DataCell(Text(id, style: baseStyle)),
        DataCell(Text(productName, style: baseStyle)),
        DataCell(
          hasTextAsNumber && !isBefore
              ? Text(
                price!,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
              : Text(price ?? '', style: baseStyle),
        ),
        DataCell(
          hasNull && isBefore
              ? Text(
                '',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              )
              : Text(discount ?? '', style: baseStyle),
        ),
        DataCell(Text(date, style: baseStyle)),
      ],
    );
  }

  /// Builds the UI for outlier detection and handling configuration.
  ///
  /// This widget provides controls for configuring outlier detection:
  /// - A switch to enable/disable outlier handling
  /// - When enabled, additional controls appear:
  ///   * Dropdown for selecting detection method (IQR, Z-score, Percentile)
  ///   * Text field for setting the detection threshold
  ///   * Dropdown for selecting the action to take on detected outliers
  ///
  /// The threshold value changes meaning based on the selected detection method:
  /// - For IQR: typically 1.5 or 3.0 (multiples of IQR)
  /// - For Z-score: typically 3.0 (standard deviations from mean)
  /// - For Percentile: value between 0.0 and 1.0 (percentile cutoff)
  ///
  /// Returns a [Widget] containing the complete outlier handling configuration UI.
  Widget _buildOutlierHandlingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable outlier handling'),
          value: _enableOutlierHandling,
          onChanged: (value) {
            setState(() {
              _enableOutlierHandling = value;
            });
          },
        ),
        if (_enableOutlierHandling) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Detection method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _outlierDetectionMethod,
            items: const [
              DropdownMenuItem(value: 'IQR', child: Text('IQR')),
              DropdownMenuItem(value: 'Z-score', child: Text('Z-score')),
              DropdownMenuItem(value: 'Percentile', child: Text('Percentile')),
            ],
            onChanged: (newValue) {
              setState(() {
                _outlierDetectionMethod = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Threshold',
              hintText: 'e.g., 1.5 for IQR, 3.0 for Z-score',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _outlierThreshold.toString(),
            ),
            onChanged: (value) {
              setState(() {
                _outlierThreshold = double.tryParse(value) ?? 1.5;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _outlierAction,
            items: const [
              DropdownMenuItem(
                value: 'Report only',
                child: Text('Report only'),
              ),
              DropdownMenuItem(value: 'Remove', child: Text('Remove')),
              DropdownMenuItem(value: 'Clip', child: Text('Clip values')),
              DropdownMenuItem(value: 'Winsorize', child: Text('Winsorize')),
            ],
            onChanged: (newValue) {
              setState(() {
                _outlierAction = newValue!;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Builds the UI for duplicate row detection and removal configuration.
  ///
  /// This widget provides controls for configuring duplicate handling:
  /// - A switch to enable/disable duplicate removal
  /// - When enabled, additional controls appear:
  ///   * A container displaying where column selection will be available
  ///     (currently placeholder for future dataset integration)
  ///   * Dropdown for selecting which occurrences to keep when duplicates are found
  ///
  /// The duplicate handling supports different strategies:
  /// - Keep first occurrence: Keeps the first instance of duplicate rows
  /// - Keep last occurrence: Keeps the last instance of duplicate rows
  /// - Remove all: Removes all instances of duplicate rows
  ///
  /// Returns a [Widget] containing the complete duplicate removal configuration UI.
  Widget _buildDuplicateRemovalContent() {
    // Get columns from data preview if available
    List<String> availableColumns = [];
    if (_dataPreview != null && _dataPreview!['columns'] != null) {
      availableColumns = List<String>.from(_dataPreview!['columns']);
    }

    // Selected columns for duplicate detection
    Set<String> duplicateColumns = {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Remove Duplicate Rows'),
          subtitle: const Text(
            'Find and remove duplicate records in your dataset',
          ),
          value: _enableDuplicateRemoval,
          onChanged: (value) {
            setState(() {
              _enableDuplicateRemoval = value;
            });
          },
        ),
        if (_enableDuplicateRemoval) ...[
          const SizedBox(height: 8),

          // Column selection for duplicate detection
          if (availableColumns.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Select columns to check for duplicates:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    availableColumns.map((column) {
                      return FilterChip(
                        label: Text(column),
                        selected: duplicateColumns.contains(column),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              duplicateColumns.add(column);
                            } else {
                              duplicateColumns.remove(column);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('Select All'),
                    onPressed: () {
                      setState(() {
                        duplicateColumns = Set.from(availableColumns);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    onPressed: () {
                      setState(() {
                        duplicateColumns.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ] else if (widget.currentDatasetPath != null) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Load the dataset preview to select columns for duplicate detection',
                ),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Duplicate handling options:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Keep strategy'),
              value: _duplicateKeepStrategy,
              items: const [
                DropdownMenuItem(
                  value: 'First occurrence',
                  child: Text('Keep first occurrence'),
                ),
                DropdownMenuItem(
                  value: 'Last occurrence',
                  child: Text('Keep last occurrence'),
                ),
                DropdownMenuItem(
                  value: 'None',
                  child: Text('Remove all duplicates'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _duplicateKeepStrategy = value!;
                });
              },
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced options',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Case-sensitive matching'),
                      subtitle: const Text('Match exact letter case'),
                      dense: true,
                      value: _caseSensitiveMatching,
                      onChanged: (value) {
                        setState(() {
                          _caseSensitiveMatching = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Trim whitespace'),
                      subtitle: const Text('Ignore leading/trailing spaces'),
                      dense: true,
                      value: _trimWhitespace,
                      onChanged: (value) {
                        setState(() {
                          _trimWhitespace = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Preview duplicates button
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.preview_outlined),
              label: const Text('Preview Duplicates'),
              onPressed:
                  widget.currentDatasetPath != null &&
                          duplicateColumns.isNotEmpty
                      ? _previewDuplicates
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Previews duplicates in the dataset using the configured options.
  Future<void> _previewDuplicates() async {
    if (widget.currentDatasetPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No dataset selected')));
      return;
    }

    if (_duplicateColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one column to check for duplicates',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingDuplicatePreview = true;
    });

    try {
      // Call the backend API to preview duplicates
      final response = await http.post(
        Uri.parse('${dotenv.env['DEV_BASE_URL']}/api/duplicates/preview'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_path': widget.currentDatasetPath,
          'columns': _duplicateColumns.toList(),
          'case_sensitive': _caseSensitiveMatching,
          'trim_whitespace': _trimWhitespace,
          'limit': 20, // Limit preview to 20 duplicate groups
          'max_sample_size': 50000, // Sample size for large files
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _duplicatePreviewData = data;
        });

        _showDuplicatePreviewDialog();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error previewing duplicates: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error previewing duplicates: $e')),
      );
    } finally {
      setState(() {
        _isLoadingDuplicatePreview = false;
      });
    }
  }

  /// Shows a dialog displaying the duplicate preview results.
  void _showDuplicatePreviewDialog() {
    if (_duplicatePreviewData == null) return;

    final duplicateCount = _duplicatePreviewData!['duplicate_count'] ?? 0;
    final duplicateGroups = _duplicatePreviewData!['duplicate_groups'] ?? 0;
    final samples = List<Map<String, dynamic>>.from(
      _duplicatePreviewData!['samples'] ?? [],
    );
    final columnsAnalyzed = List<String>.from(
      _duplicatePreviewData!['columns_analyzed'] ?? [],
    );
    final fileInfo = Map<String, dynamic>.from(
      _duplicatePreviewData!['file_info'] ?? {},
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.find_replace,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Duplicate Detection Results'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child:
                samples.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No duplicates found!',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView(
                      shrinkWrap: true,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Summary',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Found $duplicateCount duplicate records in $duplicateGroups groups',
                                ),
                                Text(
                                  'Columns analyzed: ${columnsAnalyzed.join(", ")}',
                                ),
                                Text(
                                  'Total rows in file: ${fileInfo['total_rows'] ?? "unknown"}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sample Duplicate Groups:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...samples.map((group) {
                          final groupId = group['group_id'];
                          final count = group['count'];
                          final rows = List<Map<String, dynamic>>.from(
                            group['rows'],
                          );
                          final keyValues = Map<String, dynamic>.from(
                            group['key_values'] ?? {},
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Group ${groupId + 1}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                      ),
                                      const Spacer(),
                                      Badge(
                                        label: Text('$count duplicates'),
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Matching on: ${keyValues.entries.map((e) => "${e.key}=${e.value}").join(", ")}',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columnSpacing: 16,
                                          headingRowHeight: 40,
                                          dataRowMaxHeight: double.infinity,
                                          dataRowMinHeight: 48,
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.5),
                                              ),
                                          columns:
                                              rows.first.keys.map((key) {
                                                return DataColumn(
                                                  label: Tooltip(
                                                    message: key,
                                                    child: Text(
                                                      key,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          rows:
                                              rows.map((row) {
                                                return DataRow(
                                                  cells:
                                                      row.keys.map((key) {
                                                        final isKeyColumn =
                                                            keyValues
                                                                .containsKey(
                                                                  key,
                                                                );
                                                        final cellValue =
                                                            row[key]
                                                                ?.toString() ??
                                                            'null';

                                                        return DataCell(
                                                          Container(
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 200,
                                                                ),
                                                            child: Text(
                                                              cellValue,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  isKeyColumn
                                                                      ? TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            Theme.of(
                                                                              context,
                                                                            ).colorScheme.primary,
                                                                      )
                                                                      : null,
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            if (cellValue
                                                                    .length >
                                                                20) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (
                                                                      ctx,
                                                                    ) => AlertDialog(
                                                                      title:
                                                                          Text(
                                                                            key,
                                                                          ),
                                                                      content: Text(
                                                                        cellValue,
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          child: const Text(
                                                                            'Close',
                                                                          ),
                                                                          onPressed:
                                                                              () =>
                                                                                  Navigator.of(ctx).pop(),
                                                                        ),
                                                                      ],
                                                                    ),
                                                              );
                                                            }
                                                          },
                                                        );
                                                      }).toList(),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
          contentPadding: const EdgeInsets.all(16),
          scrollable: true,
        );
      },
    );
  }

  /// Builds the UI for categorical encoding configuration.
  ///
  /// This widget creates a column with controls for configuring categorical encoding:
  /// - A switch to enable/disable categorical encoding functionality
  /// - When enabled, displays:
  ///   * A dropdown menu to select the encoding method (One-hot, Label, Ordinal)
  ///   * For One-hot encoding, shows a text field to set maximum categories
  ///
  /// Categorical encoding is important for machine learning as many algorithms
  /// require numeric input. This component provides different encoding strategies:
  /// - One-hot: Creates binary columns for each category (up to max categories)
  /// - Label: Assigns a unique integer to each category (0, 1, 2, ...)
  /// - Ordinal: Similar to label, but preserves some order relationship
  ///
  /// Returns a [Widget] containing the complete categorical encoding configuration UI.
  Widget _buildCategoricalEncodingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable categorical encoding'),
          value: _enableCategoricalEncoding,
          onChanged: (value) {
            setState(() {
              _enableCategoricalEncoding = value;
            });
          },
        ),
        if (_enableCategoricalEncoding) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Encoding method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _encodingMethod,
            items: const [
              DropdownMenuItem(
                value: 'One-hot',
                child: Text('One-hot encoding'),
              ),
              DropdownMenuItem(value: 'Label', child: Text('Label encoding')),
              DropdownMenuItem(
                value: 'Ordinal',
                child: Text('Ordinal encoding'),
              ),
            ],
            onChanged: (newValue) {
              setState(() {
                _encodingMethod = newValue!;
              });
            },
          ),
          if (_encodingMethod == 'One-hot') ...[
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Max categories (for one-hot)',
                hintText: 'Limit for unique values to encode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                helperText:
                    'Categories beyond this limit will be grouped as "other"',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(
                text: _maxCategories.toString(),
              ),
              onChanged: (value) {
                setState(() {
                  _maxCategories = int.tryParse(value) ?? 20;
                });
              },
            ),
          ],
        ],
      ],
    );
  }

  /// Builds the UI for numeric scaling configuration.
  ///
  /// This widget creates a column with controls for configuring numeric scaling:
  /// - A switch to enable/disable numeric scaling functionality
  /// - When enabled, displays:
  ///   * A dropdown menu to select the scaling method
  ///   * For Min-Max scaling, shows text fields for min/max range values
  ///
  /// Numeric scaling is crucial for many machine learning algorithms as it:
  /// - Prevents features with large values from dominating the model
  /// - Improves convergence speed for gradient-based algorithms
  /// - Makes features comparable on the same scale
  ///
  /// The available scaling methods are:
  /// - Standard (z-score): Scales values to have mean=0, std=1
  /// - Min-Max: Scales values to fit within a specified range (default: 0 to 1)
  /// - Robust: Uses median and quartiles (less sensitive to outliers)
  /// - Log: Applies logarithmic transformation (useful for skewed data)
  ///
  /// Returns a [Widget] containing the complete numeric scaling configuration UI.
  Widget _buildNumericScalingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable numeric scaling'),
          value: _enableNumericScaling,
          onChanged: (value) {
            setState(() {
              _enableNumericScaling = value;
            });
          },
        ),
        if (_enableNumericScaling) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Scaling method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _scalingMethod,
            items: const [
              DropdownMenuItem(
                value: 'Standard',
                child: Text('Standard (z-score)'),
              ),
              DropdownMenuItem(
                value: 'Min-Max',
                child: Text('Min-Max scaling'),
              ),
              DropdownMenuItem(value: 'Robust', child: Text('Robust scaling')),
              DropdownMenuItem(value: 'Log', child: Text('Log transformation')),
            ],
            onChanged: (newValue) {
              setState(() {
                _scalingMethod = newValue!;
              });
            },
          ),
          if (_scalingMethod == 'Min-Max') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Min range',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: _scalingMinRange.toString(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _scalingMinRange = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Max range',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: _scalingMaxRange.toString(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _scalingMaxRange = double.tryParse(value) ?? 1.0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  /// Builds the UI content for column name standardization settings.
  ///
  /// This widget creates a column containing controls for configuring column name standardization:
  /// - A switch to enable/disable column name standardization
  /// - When enabled, displays additional controls:
  ///   * A dropdown for selecting naming case style (Snake_case, camelCase, etc.)
  ///   * Text fields for optional prefix and suffix additions
  ///   * An option to replace spaces with underscores in column names
  ///
  /// Column name standardization helps maintain consistency across the dataset
  /// and improves code readability when referring to columns programmatically.
  ///
  /// Returns a [Widget] containing the complete column name standardization configuration UI.
  Widget _buildColumnNameStandardizationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable column name standardization'),
          value: _enableColumnStandardization,
          onChanged: (value) {
            setState(() {
              _enableColumnStandardization = value;
            });
          },
        ),
        if (_enableColumnStandardization) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Case style',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _columnCaseStyle,
            items: const [
              DropdownMenuItem(value: 'Snake_case', child: Text('Snake_case')),
              DropdownMenuItem(value: 'camelCase', child: Text('camelCase')),
              DropdownMenuItem(value: 'PascalCase', child: Text('PascalCase')),
              DropdownMenuItem(value: 'kebab-case', child: Text('kebab-case')),
            ],
            onChanged: (newValue) {
              setState(() {
                _columnCaseStyle = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Prefix',
                    hintText: 'e.g., data_',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Suffix',
                    hintText: 'e.g., _col',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Replace spaces with underscores'),
            value: _replaceColumnSpaces,
            onChanged: (value) {
              setState(() {
                _replaceColumnSpaces = value;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Builds the UI content for inconsistent value correction settings.
  ///
  /// This widget creates a column containing controls for configuring value correction:
  /// - A switch to enable/disable inconsistent value correction
  /// - When enabled, displays additional controls:
  ///   * A dropdown for selecting the correction method (Automatic clustering, Frequency-based, Custom mapping)
  ///   * A slider for adjusting similarity threshold for fuzzy matching
  ///   * For custom mapping: A multi-line text field for JSON format mappings
  ///
  /// Inconsistent value correction helps standardize categorical values with spelling variations,
  /// different capitalization, or other minor differences (e.g., "NY", "New York", "new york").
  ///
  /// The similarity threshold (0.0-1.0) determines how close strings need to be to be considered the same:
  /// - Higher values (closer to 1.0) require more similarity
  /// - Lower values (closer to 0.0) are more lenient in matching
  ///
  /// Returns a [Widget] containing the complete inconsistent value correction configuration UI.
  Widget _buildInconsistentValueCorrectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable inconsistent value correction'),
          value: _enableValueCorrection,
          onChanged: (value) {
            setState(() {
              _enableValueCorrection = value;
            });
          },
        ),
        if (_enableValueCorrection) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Correction method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _valueCorrectionMethod,
            items: const [
              DropdownMenuItem(
                value: 'Automatic clustering',
                child: Text('Automatic clustering'),
              ),
              DropdownMenuItem(
                value: 'Frequency-based',
                child: Text('Frequency-based'),
              ),
              DropdownMenuItem(
                value: 'Custom mapping',
                child: Text('Custom mapping'),
              ),
            ],
            onChanged: (newValue) {
              setState(() {
                _valueCorrectionMethod = newValue!;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(flex: 2, child: Text('Similarity threshold:')),
              Expanded(
                flex: 3,
                child: Slider(
                  value: _similarityThreshold,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: _similarityThreshold.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _similarityThreshold = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _similarityThreshold.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (_valueCorrectionMethod == 'Custom mapping') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customMappingController,
              decoration: InputDecoration(
                labelText: 'Custom mapping (JSON format)',
                hintText:
                    '{"original1": "corrected1", "original2": "corrected2"}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                helperText:
                    'Define mapping from original values to corrected values',
              ),
              maxLines: 5,
            ),
          ],
        ],
      ],
    );
  }

  /// Builds the UI content for global data cleaning settings.
  ///
  /// This widget creates a column with a card containing switches for various global options:
  /// - Parallel processing: Enable concurrent processing of operations (uses more memory)
  /// - In-place processing: Modify original dataset without creating a copy
  /// - Dataset preview: Show before/after comparison when applying operations
  /// - Progress visualization_and_explorer: Display processing status and estimated time remaining
  /// - Report generation: Create a detailed report of all cleaning operations
  ///
  /// These global settings affect how all data cleaning operations are performed.
  ///
  /// Returns a [Widget] containing the global options configuration UI.
  Widget _buildGlobalOptionsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              SwitchListTile(
                dense: true,
                title: const Text('Enable parallel processing'),
                subtitle: const Text(
                  'Process operations concurrently (uses more memory)',
                ),
                value: _enableParallelGlobalProcessing,
                onChanged: (value) {
                  setState(() {
                    _enableParallelGlobalProcessing = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                dense: true,
                title: const Text('Process data in-place'),
                subtitle: const Text(
                  'Modify original dataset instead of creating a copy',
                ),
                value: _enableInPlaceProcessing,
                onChanged: (value) {
                  setState(() {
                    _enableInPlaceProcessing = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                dense: true,
                title: const Text('Show dataset preview'),
                subtitle: const Text('Display before/after comparison'),
                value: _enableDatasetPreview,
                onChanged: (value) {
                  setState(() {
                    _enableDatasetPreview = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                dense: true,
                title: const Text('Enable progress visualization_and_explorer'),
                subtitle: const Text(
                  'Show processing status and time estimates',
                ),
                value: _enableProgressVisualization,
                onChanged: (value) {
                  setState(() {
                    _enableProgressVisualization = value;
                  });
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                dense: true,
                title: const Text('Generate cleaning report'),
                subtitle: const Text(
                  'Create detailed report of all operations',
                ),
                value: _enableReportGeneration,
                onChanged: (value) {
                  setState(() {
                    _enableReportGeneration = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the tab bar navigation component for the Data Cleaning tab.
  ///
  /// Creates a horizontally scrollable tab bar with 6 tabs representing different
  /// sections of the data cleaning workflow in a logical sequence:
  /// 1. Fix Basics - Handle missing values, duplicates, and spelling inconsistencies
  /// 2. Fix Data Types - Correct numeric types and date formats
  /// 3. Transform Data - Clean text, encode categories, and scale numeric values
  /// 4. Fix Data Quality - Handle outliers and other quality issues
  /// 5. Organize Data - Standardize column names and structure
  /// 6. Settings - Configure global processing options
  ///
  /// Returns a [Widget] containing the configured tab bar inside a container.
  Widget _buildTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '1. Fix Basics'),
          Tab(text: '2. Fix Data Types'),
          Tab(text: '3. Transform Data'),
          Tab(text: '4. Fix Data Quality'),
          Tab(text: '5. Organize Data'),
          Tab(text: '6. Settings'),
        ],
      ),
    );
  }

  /// Builds the content for the "Fix Basics" tab.
  ///
  /// This tab focuses on fundamental data cleaning operations:
  /// - Missing value handling: Options to fill or handle null/empty values
  /// - Duplicate removal: Detecting and removing duplicate rows
  /// - Inconsistent value correction: Fixing spelling variations and similar values
  ///
  /// The content is presented as a scrollable list of cards, each containing
  /// a specific cleaning operation with its own configuration options.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildBasicDataFixesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Fix Missing Values',
          description: 'Fill in or handle empty cells in your data',
          icon: Icons.block_outlined,
          content: _buildNullValueContent(),
        ),
        const SizedBox(height: 12),
        _buildCleaningCard(
          title: 'Remove Duplicates',
          description: 'Find and remove rows that appear more than once',
          icon: Icons.filter_none_outlined,
          content: _buildDuplicateRemovalContent(),
        ),
        const SizedBox(height: 12),
        _buildCleaningCard(
          title: 'Fix Spelling Mistakes',
          description: 'Correct similar values like "NY" and "New York"',
          icon: Icons.spellcheck_outlined,
          content: _buildInconsistentValueCorrectionContent(),
        ),
      ],
    );
  }

  /// Builds the content for the "Fix Data Types" tab.
  ///
  /// This tab focuses on improving and correcting data types in the dataset:
  /// - Numeric type conversion: Detecting and converting text that should be numeric
  /// - Date format detection: Identifying various date formats and standardizing them
  ///
  /// Proper data typing is crucial for meaningful analysis and visualization_and_explorer,
  /// as operations like calculations and time-series analysis require appropriate types.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildDataTypeImprovementsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Convert Text to Numbers',
          description:
              'Change text columns to numeric when they contain numbers',
          icon: Icons.onetwothree_outlined,
          content: _buildNumericTypeContent(),
        ),
        const SizedBox(height: 12),
        _buildCleaningCard(
          title: 'Find and Format Dates',
          description: 'Detect and standardize different date formats',
          icon: Icons.calendar_today_outlined,
          content: _buildDateDetectionContent(),
        ),
      ],
    );
  }

  /// Builds the content for the "Data Transformations" tab.
  ///
  /// This tab focuses on transforming data for better analysis:
  /// - Text cleaning: Standardizing text by changing case, trimming whitespace, etc.
  /// - Categorical encoding: Converting text categories to numerical values
  /// - Numeric scaling: Standardizing numeric data ranges
  ///
  /// These transformations prepare data for more advanced analysis and machine learning
  /// by ensuring consistent formats and appropriate representations.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildDataTransformationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Clean Text',
          description:
              'Standardize text by removing spaces, changing case, etc.',
          icon: Icons.text_format_outlined,
          content: _buildTextCleaningContent(),
        ),
        const SizedBox(height: 12),
        _buildCleaningCard(
          title: 'Convert Categories to Numbers',
          description: 'Turn text categories into numbers for analysis',
          icon: Icons.category_outlined,
          content: _buildCategoricalEncodingContent(),
        ),
        const SizedBox(height: 12),
        _buildCleaningCard(
          title: 'Scale Numbers',
          description: 'Standardize number ranges for better comparisons',
          icon: Icons.scale_outlined,
          content: _buildNumericScalingContent(),
        ),
      ],
    );
  }

  /// Builds the content for the "Data Quality" tab.
  ///
  /// This tab focuses on identifying and addressing data quality issues:
  /// - Outlier detection: Finding and handling unusual values that may skew analysis
  ///
  /// Addressing data quality issues improves the reliability of analyses and prevents
  /// misleading conclusions from anomalies in the dataset.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildDataQualityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Handle Unusual Values',
          description:
              'Detect and fix values that are much higher or lower than normal',
          icon: Icons.show_chart_outlined,
          content: _buildOutlierHandlingContent(),
        ),
      ],
    );
  }

  /// Builds the content for the "Organization" tab.
  ///
  /// This tab focuses on improving the organization and structure of the dataset:
  /// - Column name standardization: Making column names consistent and easier to use
  ///
  /// Better organization improves code readability and makes it easier to reference
  /// specific columns consistently throughout analysis workflows.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildOrganizationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Clean Column Names',
          description: 'Make column names consistent and easy to use',
          icon: Icons.title_outlined,
          content: _buildColumnNameStandardizationContent(),
        ),
      ],
    );
  }

  /// Builds the content for the "Settings" tab.
  ///
  /// This tab provides global configuration options for all data cleaning operations:
  /// - Processing options: Settings that affect how cleaning operations are performed
  ///   including parallel processing, in-place modifications, and reporting
  ///
  /// These settings apply across all cleaning operations and help users optimize
  /// for their specific needs regarding performance, memory usage, and visualization_and_explorer.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Processing Options',
          description: 'Configure how data cleaning operations work',
          icon: Icons.settings_outlined,
          content: _buildGlobalOptionsContent(),
        ),
      ],
    );
  }
}

// NOTE: I would kill my self before I actually explain this code to someone
