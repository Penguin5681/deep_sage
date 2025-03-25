import 'package:flutter/material.dart';

class DataCleaningTab extends StatefulWidget {
  final String? currentDataset;
  final String? currentDatasetPath;
  final String? currentDatasetType;
  const DataCleaningTab({super.key, this.currentDataset, this.currentDatasetPath, this.currentDatasetType});

  @override
  State<DataCleaningTab> createState() => _DataCleaningTabState();
}

class _DataCleaningTabState extends State<DataCleaningTab> with SingleTickerProviderStateMixin {
  /// Method for handling null values. Defaults to 'nan' (Not a Number).
  String _nullMethod = 'nan';

  /// Controller for the text field used to fill null values for numeric columns.
  final TextEditingController _numericFillController = TextEditingController();

  /// Controller for the text field used to fill null values for categorical columns.
  final TextEditingController _categoricalFillController = TextEditingController();

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
  final TextEditingController _customMappingController = TextEditingController();

  /// Flag to enable or disable parallel processing globally. Defaults to false.
  bool _enableParallelGlobalProcessing = false;
  bool _enableInPlaceProcessing = true;
  bool _enableDatasetPreview = true;
  bool _enableProgressVisualization = true;
  bool _enableReportGeneration = false;

  final TextEditingController _regexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        Padding(padding: const EdgeInsets.only(left: 18.0), child: _buildBottomActions()),
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
          const Text('Data Cleaning', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Make your data ready for analysis by fixing common problems',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
            color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.2) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'No dataset selected. Please select a dataset from the sidebar.',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
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
          color: isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
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
                      color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade800,
                    ),
                  ),
                  if (widget.currentDatasetPath != null)
                    Text(
                      _getDisplayPath(widget.currentDatasetPath!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
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
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          subtitle: Text(
            description,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          initiallyExpanded: title == 'Null Value Handling',
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [content],
        ),
      ),
    );
  }

  /// Builds the UI for handling null values in the dataset.
  ///
  /// This widget returns a Column that contains a DropdownButtonFormField
  /// to choose a fill method for null values. The available methods include
  /// leaving the value as NaN, filling with 0, mean, median, mode, or providing
  /// custom fill values. When using the custom fill method, additional fields are
  /// displayed for numeric and categorical values, as well as a date picker for a
  /// date fill value.
  Widget _buildNullValueContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Fill method',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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
                border: Border.all(color: Theme.of(context).colorScheme.outline),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.auto_fix_high),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text('Apply Cleaning Operations'),
        ),
      ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _outlierThreshold.toString()),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _outlierAction,
            items: const [
              DropdownMenuItem(value: 'Report only', child: Text('Report only')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable duplicate removal'),
          value: _enableDuplicateRemoval,
          onChanged: (value) {
            setState(() {
              _enableDuplicateRemoval = value;
            });
          },
        ),
        if (_enableDuplicateRemoval) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Column subset for checking duplicates:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select columns from dataset (will be available after integration)',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Keep strategy',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _duplicateKeepStrategy,
            items: const [
              DropdownMenuItem(value: 'First occurrence', child: Text('Keep first occurrence')),
              DropdownMenuItem(value: 'Last occurrence', child: Text('Keep last occurrence')),
              DropdownMenuItem(value: 'Remove all', child: Text('Remove all occurrences')),
            ],
            onChanged: (newValue) {
              setState(() {
                _duplicateKeepStrategy = newValue!;
              });
            },
          ),
        ],
      ],
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _encodingMethod,
            items: const [
              DropdownMenuItem(value: 'One-hot', child: Text('One-hot encoding')),
              DropdownMenuItem(value: 'Label', child: Text('Label encoding')),
              DropdownMenuItem(value: 'Ordinal', child: Text('Ordinal encoding')),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                helperText: 'Categories beyond this limit will be grouped as "other"',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _maxCategories.toString()),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _scalingMethod,
            items: const [
              DropdownMenuItem(value: 'Standard', child: Text('Standard (z-score)')),
              DropdownMenuItem(value: 'Min-Max', child: Text('Min-Max scaling')),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _scalingMinRange.toString()),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _scalingMaxRange.toString()),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _valueCorrectionMethod,
            items: const [
              DropdownMenuItem(value: 'Automatic clustering', child: Text('Automatic clustering')),
              DropdownMenuItem(value: 'Frequency-based', child: Text('Frequency-based')),
              DropdownMenuItem(value: 'Custom mapping', child: Text('Custom mapping')),
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
                hintText: '{"original1": "corrected1", "original2": "corrected2"}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                helperText: 'Define mapping from original values to corrected values',
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
  /// - Progress visualization: Display processing status and estimated time remaining
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              SwitchListTile(
                dense: true,
                title: const Text('Enable parallel processing'),
                subtitle: const Text('Process operations concurrently (uses more memory)'),
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
                subtitle: const Text('Modify original dataset instead of creating a copy'),
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
                title: const Text('Enable progress visualization'),
                subtitle: const Text('Show processing status and time estimates'),
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
                subtitle: const Text('Create detailed report of all operations'),
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
  /// Proper data typing is crucial for meaningful analysis and visualization,
  /// as operations like calculations and time-series analysis require appropriate types.
  ///
  /// Returns a [ListView] containing cleaning cards with their respective content widgets.
  Widget _buildDataTypeImprovementsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCleaningCard(
          title: 'Convert Text to Numbers',
          description: 'Change text columns to numeric when they contain numbers',
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
          description: 'Standardize text by removing spaces, changing case, etc.',
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
          description: 'Detect and fix values that are much higher or lower than normal',
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
  /// for their specific needs regarding performance, memory usage, and visualization.
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
