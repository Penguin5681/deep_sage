import 'dart:async';
import 'dart:io';

import 'package:deep_sage/views/core_screens/visualization_and_explorer/tabs/data_cleaning_tab.dart';
import 'package:deep_sage/views/core_screens/visualization_and_explorer/tabs/raw_data_tab.dart';
import 'package:deep_sage/views/core_screens/visualization_and_explorer/tabs/visualize_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import '../../../core/models/hive_models/recent_imports_model.dart';

class VisualizationAndExplorerScreens extends StatefulWidget {
  const VisualizationAndExplorerScreens({super.key});

  @override
  State<VisualizationAndExplorerScreens> createState() =>
      _VisualizationAndExplorerScreensState();
}

class _VisualizationAndExplorerScreensState
    extends State<VisualizationAndExplorerScreens>
    with TickerProviderStateMixin {
  /// [tabController] is used to manage the tabbed interface (Raw Data, Data Cleaning, Visualize).
  late TabController tabController;

  /// [tabControllerIndex] keeps track of the currently active tab's index.
  late int tabControllerIndex;

  /// [currentDataset] holds the name of the dataset currently selected or in use.
  late String? currentDataset = '';

  /// [currentDatasetPath] stores the file path of the currently selected dataset.
  late String? currentDatasetPath = '';

  /// [currentDatasetType] indicates the type (e.g., CSV, JSON, XLSX) of the current dataset.
  late String? currentDatasetType = '';

  /// [recentImportsBox] is a Hive box used to store and retrieve the history of recent file imports.
  /// This box persists data across sessions.
  ///
  /// It's initialized using the environment variable [RECENT_IMPORTS_HISTORY] from the .env file.
  /// This environment variable should define the name of the Hive box for recent imports.
  ///
  /// Hive is a lightweight database that can be used to store various types of data locally.
  /// It is useful for caching and other local storage needs.
  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  /// [selectedDatasetNotifier] is a [ValueNotifier] that notifies listeners whenever the selected dataset changes.
  /// It's used to trigger UI updates and other actions that depend on the currently selected dataset.
  /// The initial value is set to null, indicating no dataset is selected initially.
  final ValueNotifier<String?> selectedDatasetNotifier = ValueNotifier<String?>(
    null,
  );
  List<StreamSubscription<FileSystemEvent>> fileWatchers = [];
  Set<String> watchedFiles = {};

  final TextEditingController recentImportsSearchController =
      TextEditingController();
  List<RecentImportsModel> filteredRecentImports = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabControllerIndex = 0;

    recentImportsSearchController.addListener(_filterRecentImports);
    _loadRecentImports();

    _loadLastSelectedDataset();

    setupImportWatchers();
    recentImportsBox.listenable().addListener(setupImportWatchers);
    selectedDatasetNotifier.addListener(_handleDatasetSelectionChange);
  }

  /// [_loadLastSelectedDataset] attempts to load the last selected dataset's information from the Hive box.
  ///
  /// It checks if there is a previously selected dataset ('currentDatasetName') and its path
  /// ('currentDatasetPath') in the recentImportsBox. If both exist and the file at 'currentDatasetPath'
  /// exists, it sets [currentDataset] and [currentDatasetPath] to these values. Otherwise, it clears
  /// the stored information from the recentImportsBox, effectively resetting the last selected dataset.
  ///
  /// This function is called during the initialization of the state to restore the state of the application
  /// to the last used dataset.
  void _loadLastSelectedDataset() {
    currentDataset = recentImportsBox.get('currentDatasetName');
    currentDatasetPath = recentImportsBox.get('currentDatasetPath');
    currentDatasetType = recentImportsBox.get('currentDatasetType');

    if (currentDatasetPath != null &&
        File(currentDatasetPath!).existsSync() &&
        currentDataset != null) {
      selectedDatasetNotifier.value = currentDataset;
    } else {
      recentImportsBox.delete('currentDatasetName');
      recentImportsBox.delete('currentDatasetPath');
      recentImportsBox.delete('currentDatasetType');
    }
  }

  void _loadRecentImports() {
    var recentImportsData = recentImportsBox.get('recentImports');
    List<RecentImportsModel> imports = [];

    if (recentImportsData != null) {
      if (recentImportsData is List) {
        imports = recentImportsData.cast<RecentImportsModel>();
      } else if (recentImportsData is RecentImportsModel) {
        imports = [recentImportsData];
      }
    }

    setState(() {
      filteredRecentImports = List.from(imports);
    });
  }

  void _filterRecentImports() {
    final query = recentImportsSearchController.text.toLowerCase();

    var recentImportsData = recentImportsBox.get('recentImports');
    List<RecentImportsModel> imports = [];

    if (recentImportsData != null) {
      if (recentImportsData is List) {
        imports = recentImportsData.cast<RecentImportsModel>();
      } else if (recentImportsData is RecentImportsModel) {
        imports = [recentImportsData];
      }
    }

    setState(() {
      if (query.isEmpty) {
        filteredRecentImports = List.from(imports);
      } else {
        filteredRecentImports =
            imports.where((import) {
              return import.fileName.toLowerCase().contains(query) ||
                  import.fileType.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  Widget _buildRecentImportsSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: recentImportsSearchController,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          hintText: "Search recent imports",
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  /// [_handleDatasetSelectionChange] is a callback function triggered when [selectedDatasetNotifier] changes.
  ///
  /// It checks if the newly selected dataset is different from the currently loaded dataset. If they differ,
  /// it updates the state with the new dataset's name. It also stores the new dataset's information in the
  /// [recentImportsBox] under 'currentDatasetName', 'currentDatasetPath', and 'currentDatasetType'.
  ///
  /// This ensures that the application's state and the persistent storage are synchronized with the user's
  /// most recent dataset selection.
  void _handleDatasetSelectionChange() {
    if (selectedDatasetNotifier.value != null &&
        selectedDatasetNotifier.value != currentDataset) {
      setState(() {
        currentDataset = selectedDatasetNotifier.value;

        recentImportsBox.put('currentDatasetName', currentDataset);
        recentImportsBox.put('currentDatasetPath', currentDatasetPath);
        recentImportsBox.put('currentDatasetType', currentDatasetType);
      });
    }
  }

  /// [selectDataset] handles the selection of a dataset from the recent imports list.
  ///
  /// It takes a [RecentImportsModel] instance, which contains details about the imported dataset,
  /// such as its name, path, and type. This method updates the state variables ([currentDataset],
  /// [currentDatasetPath], [currentDatasetType]) to reflect the newly selected dataset.
  ///
  /// It also persists the selected dataset information to the [recentImportsBox] for future use.
  /// Additionally, it triggers a state update and notifies the [selectedDatasetNotifier] to signal
  /// other parts of the application that a new dataset has been selected.
  void selectDataset(RecentImportsModel import) {
    debugPrint('Selecting dataset: ${import.fileName} (${import.fileType})');

    recentImportsBox.put('currentDatasetName', import.fileName);
    recentImportsBox.put('currentDatasetPath', import.filePath);
    recentImportsBox.put('currentDatasetType', import.fileType);

    setState(() {
      currentDataset = import.fileName;
      currentDatasetPath = import.filePath;
      currentDatasetType = import.fileType;
    });

    selectedDatasetNotifier.value = null;

    Future.microtask(() => selectedDatasetNotifier.value = import.fileName);
  }

  /// [setupImportWatchers] configures file watchers for each recent import.
  ///
  /// This method iterates through the list of recent imports stored in [recentImportsBox] and sets up
  /// a file watcher for each file path. The file watcher monitors the file for any changes (e.g., deletion).
  /// If a change is detected, it triggers a state update. It also clears any existing file watchers and
  /// the list of watched files before setting up new ones to ensure that watchers are not duplicated.
  ///
  /// This method is called during the initialization phase and whenever the list of recent imports changes,
  /// ensuring that the app is always monitoring the correct set of files.
  void setupImportWatchers() {
    for (var watcher in fileWatchers) {
      watcher.cancel();
    }
    fileWatchers.clear();
    watchedFiles.clear();

    final dynamic recentImportsData = recentImportsBox.get('recentImports');
    if (recentImportsData == null) return;

    List<RecentImportsModel> recentImports = [];
    if (recentImportsData is List) {
      recentImports = recentImportsData.cast<RecentImportsModel>();
    } else if (recentImportsData is RecentImportsModel) {
      recentImports = [recentImportsData];
    }

    for (var import in recentImports) {
      if (import.filePath != null && import.filePath!.isNotEmpty) {
        setupFileWatcher(import.filePath!);
      }
    }
  }

  /// [setupFileWatcher] sets up a file watcher for a specific file path.
  ///
  /// This method takes a file path as input and checks if a watcher is already set up for that file.
  /// If not, it attempts to watch the directory containing the file for changes. If a change is detected,
  /// it checks if the change is a deletion or if the file no longer exists. If so, it triggers a state
  /// update. This allows the UI to react to file changes, such as removing a deleted file from the recent
  /// imports list.
  ///
  /// The method also manages the lifecycle of file watcher subscriptions and keeps track of the watched
  /// files to prevent duplicate watchers.
  void setupFileWatcher(String filePath) {
    if (watchedFiles.contains(filePath)) return;

    try {
      final file = File(filePath);
      final directory = file.parent;

      if (directory.existsSync()) {
        final subscription = directory.watch(recursive: false).listen((event) {
          if (event.path == filePath ||
              event.path.contains(file.uri.pathSegments.last)) {
            if (event.type == FileSystemEvent.delete ||
                !File(filePath).existsSync()) {
              debugPrint('File was deleted or moved: $filePath');
              setState(() {});
            }
          }
        });

        fileWatchers.add(subscription);
        watchedFiles.add(filePath);
        debugPrint('Watching file for changes: $filePath');
      }
    } catch (ex) {
      debugPrint('Error setting up file watcher: $ex');
    }
  }

  /// [returnTextBasedOnIndex] generates a string based on the current tab and dataset.
  ///
  /// It determines the name of the active tab (Raw Data, Data Cleaning, or Visualize) based on the
  /// [tabControllerIndex] and concatenates it with the name of the currently selected dataset
  /// ([currentDataset]). This function is used to create a dynamic title that reflects the current
  /// context in the application.
  String returnTextBasedOnIndex() {
    String tabName =
        tabControllerIndex == 0
            ? 'Raw Data'
            : tabControllerIndex == 1
            ? 'Data Cleaning'
            : 'Visualize';

    String datasetName = currentDataset ?? 'No Dataset';

    return '$tabName > $datasetName';
  }

  @override
  void dispose() {
    for (var watcher in fileWatchers) {
      watcher.cancel();
    }
    tabController.dispose();
    recentImportsBox.listenable().removeListener(setupImportWatchers);
    selectedDatasetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              color: isDarkMode ? Color(0xFF1F222A) : Colors.white,
            ),
            child: _buildRecentImportsSidebar(isDarkMode),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 35.0, top: 35.0),
                  child: Text('Explorer > ${returnTextBasedOnIndex()}'),
                ),
                TabBar(
                  padding: const EdgeInsets.only(left: 35.0, right: 35.0),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: isDarkMode ? Colors.white : Colors.black,
                  unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey,
                  indicatorColor: isDarkMode ? Colors.white : Colors.black,
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  controller: tabController,
                  tabs: const [
                    Tab(text: 'Raw Data'),
                    Tab(text: 'Data cleaning'),
                  ],
                  onTap: ((index) {
                    setState(() {
                      tabControllerIndex = index;
                    });
                  }),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      RawDataTab(
                        selectedDatasetNotifier: selectedDatasetNotifier,
                      ),
                      DataCleaningTab(
                        currentDataset: currentDataset,
                        currentDatasetPath: currentDatasetPath,
                        currentDatasetType: currentDatasetType,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [_buildRecentImportsSidebar] builds the sidebar that lists recent imports.
  ///
  /// This widget constructs the left sidebar of the application, displaying a list of
  /// recently imported files. Each item in the list represents a file that the user
  /// has imported into the application, and selecting an item loads that dataset for
  /// use. The sidebar also includes a button to clear the entire list of recent imports.
  ///
  /// Key components:
  /// - **Title**: A header indicating that the list displays 'Recent Imports'.
  /// - **Clear All Button**: An interactive button that, when tapped, prompts the user
  ///   to confirm clearing the entire list of recent imports.
  /// - **Recent Imports List**: A dynamic list that shows each recent import as an item.
  ///   Each item includes details like the file name, type, and import time.
  /// - **Empty State**: If no files have been imported, an empty state view is shown,
  ///   prompting the user to import datasets.
  ///
  /// Behavior:
  /// - The list is updated in real-time, reflecting any changes in the underlying
  ///   data storage where recent imports are saved.
  /// - Each file in the list is checked for existence; if a file is no longer available,
  ///   it is omitted from the list.
  /// - Clicking on a file in the list triggers the loading of that dataset.
  /// - The appearance (color scheme) of the sidebar adjusts based on whether the app
  ///   is in dark mode or light mode.
  ///
  /// Parameters:
  ///   - [isDarkMode]: A boolean indicating whether the app is in dark mode. This
  ///     affects the visual styling of the sidebar.
  ///
  /// Returns:
  ///   - A [Column] widget representing the complete structure of the recent imports sidebar.
  /// Builds the main UI structure for the Visualization and Explorer screens.
  ///
  /// This method constructs the user interface, which includes a sidebar for recent
  /// imports and a main content area with tabs for raw data, data cleaning, and
  /// visualization_and_explorer. It dynamically adjusts the appearance based on the current theme
  /// (light or dark mode).
  ///
  /// The UI is structured as follows:
  /// - **Sidebar**: Displays a list of recently imported datasets, allowing users
  ///   to select a dataset to work with. It also includes an option to clear the
  ///   list of recent imports.
  /// - **Main Content Area**: Contains a tabbed interface with three tabs:
  ///   - **Raw Data**: Displays the raw, unprocessed data of the selected dataset.
  ///   - **Data Cleaning**: Provides tools and options to clean and preprocess the data.
  ///   - **Visualize**: Offers visualization_and_explorer tools to create charts and graphs from the data.
  ///
  /// Each tab is implemented as a separate widget ([RawDataTab], [DataCleaningTab],
  /// [VisualizeTab]) and is managed by a [TabBar] and [TabBarView]. The selected dataset
  /// is passed to the [RawDataTab] to dynamically display its content.
  ///
  /// The state of the active tab is managed by [tabController] and [tabControllerIndex].
  /// The method also handles the dynamic title of the main content area, which changes
  /// based on the active tab and the selected dataset, using the [returnTextBasedOnIndex]
  /// method.
  ///
  /// The function ensures a responsive layout using [Expanded] and [Row]/[Column] widgets.
  /// The UI also changes its color scheme to match the system's dark or light mode.
  ///
  /// Parameters:
  ///   - [context]: The build context for this part of the widget tree.
  ///
  /// Returns:
  ///   - A [Scaffold] widget that contains the complete layout of the Visualization
  ///     and Explorer screens, including the sidebar and the main content area with tabs.
  ///

  Widget _buildRecentImportsSidebar(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Imports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              InkWell(
                onTap: _showClearConfirmationDialog,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color:
                        isDarkMode
                            ? Colors.grey[800]!.withValues(alpha: 0.3)
                            : Colors.grey[200]!.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildRecentImportsSearchBar(),
        ),
        Divider(
          height: 1,
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: recentImportsBox.listenable(),
            builder: (context, box, _) {
              final dynamic recentImportsData = box.get('recentImports');
              List<RecentImportsModel> recentImports = [];

              if (recentImportsData != null) {
                if (recentImportsData is List) {
                  recentImports = recentImportsData.cast<RecentImportsModel>();
                } else if (recentImportsData is RecentImportsModel) {
                  recentImports = [recentImportsData];
                }
              }

              // Filter by search term
              final query = recentImportsSearchController.text.toLowerCase();
              if (query.isNotEmpty) {
                recentImports =
                    recentImports.where((import) {
                      return import.fileName.toLowerCase().contains(query) ||
                          import.fileType.toLowerCase().contains(query);
                    }).toList();
              }

              // Filter out non-existent files
              recentImports =
                  recentImports
                      .where(
                        (import) =>
                            import.filePath != null &&
                            File(import.filePath!).existsSync(),
                      )
                      .toList();

              if (recentImports.isEmpty) {
                // Show empty state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        query.isNotEmpty ? Icons.search_off : Icons.history,
                        size: 48,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        query.isNotEmpty
                            ? 'No matching results'
                            : 'No recent imports',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        query.isNotEmpty
                            ? 'Try a different search term'
                            : 'Import datasets to see them here',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: recentImports.length,
                itemBuilder: (context, index) {
                  if (recentImports[index].filePath != null) {
                    setupFileWatcher(recentImports[index].filePath!);
                  }
                  return _buildImportItem(recentImports[index], isDarkMode);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// [_buildImportItem] constructs a single item for display in the recent imports list.
  ///
  /// Each item represents a recently imported dataset and includes details such as the
  /// file name, file type, file size, and the time of import. It also features an "Use"
  /// button that allows the user to immediately select and load the dataset.
  ///
  /// Key components of each item:
  /// - **File Icon**: An icon representing the file type (e.g., CSV, JSON).
  /// - **File Name**: The name of the imported file.
  /// - **Import Time**: The time when the file was imported, formatted as "just now,"
  ///   "X min ago," "X hr ago," or a date if older than a day.
  /// - **File Type Tag**: A tag indicating the file type.
  /// - **File Size Tag**: A tag showing the size of the file.
  /// - **Use Button**: An actionable button that, when pressed, loads the dataset for use
  ///   and switches to the "Raw Data" tab.
  ///
  /// Behavior:
  /// - If the file no longer exists at the specified path, the item is hidden (SizedBox.shrink).
  /// - The item's appearance (color scheme) adjusts based on the app's dark or light mode.
  /// - The "Use" button triggers the selection and loading of the associated dataset.
  /// - File size and type tags provide quick information about the dataset.
  ///
  /// Parameters:
  ///   - [import]: A [RecentImportsModel] instance containing the details of the imported file.
  ///   - [isDarkMode]: A boolean indicating whether the app is in dark mode, affecting the
  ///     styling of the item.
  ///
  /// Returns:
  ///   - A [Container] widget representing a single item in the recent imports list.
  ///
  /// Usage:
  ///   - This widget is used within the [ListView.builder] in the
  ///     [_buildRecentImportsSidebar] method to create the list of recent imports.
  ///
  /// Example:
  ///
  /// _buildImportItem(recentImports[index], isDarkMode);

  Widget _buildImportItem(RecentImportsModel import, bool isDarkMode) {
    final fileExists =
        import.filePath != null && File(import.filePath!).existsSync();
    final isCurrentDataset = import.fileName == currentDataset;

    if (!fileExists) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCurrentDataset
                ? (isDarkMode
                    ? Colors.blue.shade900.withValues(alpha: 0.2)
                    : Colors.blue.shade50)
                : (isDarkMode ? Color(0xFF1F222A) : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border:
            isCurrentDataset
                ? Border.all(color: Colors.blue.shade400, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFileIcon(import.fileType),
                color: _getFileColor(import.fileType),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            import.fileName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentDataset)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade400,
                            size: 20,
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatImportTime(import.importTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildInfoTag(import.fileType.toUpperCase(), isDarkMode),
              SizedBox(width: 6),
              _buildInfoTag(import.fileSize, isDarkMode),
              Spacer(),
              ElevatedButton(
                onPressed: () async {
                  selectDataset(import);
                  tabController.animateTo(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: Size(60, 30),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text('Use', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// [_buildInfoTag] creates a small, stylized tag containing information.
  ///
  /// This widget is used to display additional details about a recent import,
  /// such as its file type (e.g., CSV, JSON) or its file size. The tag is
  /// visually distinct and provides a clear, concise piece of information.
  ///
  /// Key features:
  /// - **Stylized Container**: The tag is enclosed in a container with a rounded
  ///   border and a background color that contrasts with the surrounding content.
  /// - **Text Display**: The tag displays a single line of text, which is passed
  ///   as a parameter.
  /// - **Dynamic Styling**: The appearance of the tag changes based on the
  ///   application's current theme mode (dark or light).
  ///
  /// Parameters:
  ///   - [text]: The text to be displayed inside the tag.
  ///   - [isDarkMode]: A boolean indicating whether the app is in dark mode. This
  ///     affects the visual styling of the tag.
  ///
  /// Returns:
  ///   - A [Container] widget representing the information tag.
  Widget _buildInfoTag(String text, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  /// [_formatImportTime] formats a DateTime object to a human-readable string representing the time since import.
  ///
  /// This method calculates the difference between the current time and the import time, then returns a string
  /// that describes how long ago the import occurred. The format changes depending on the time elapsed:
  ///
  /// - **Less than 1 minute**: "just now"
  /// - **Less than 1 hour**: "X min ago" (where X is the number of minutes)
  /// - **Less than 1 day**: "X hr ago" (where X is the number of hours)
  /// - **Less than 7 days**: "X days ago" (where X is the number of days)
  /// - **7 days or more**: Formats the date as "MMM d" (e.g., "Jan 15")
  ///
  /// Parameters:
  ///   - [time]: A [DateTime] object representing the time of the import.
  ///
  /// Returns:
  ///   - A [String] representing the formatted time since the import.
  ///
  /// Example:
  ///   - If the import was 5 minutes ago, it returns "5 min ago".
  ///   - If the import was yesterday, it returns "1 day ago".
  ///   - If the import was more than a week ago, it returns "Jan 1" (if the date was January 1st).
  String _formatImportTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  /// [_getFileIcon] determines the appropriate icon for a given file type.
  ///
  /// This method uses a switch statement to map file types (CSV, JSON, XLSX) to
  /// their corresponding icons from Flutter's Icons library. If the file type
  /// does not match any of the specified cases, it defaults to a generic file
  /// icon.
  ///
  /// Parameters:
  ///   - [fileType]: A [String] representing the file type (e.g., 'csv', 'json').
  ///
  /// Returns:
  ///   - An [IconData] object representing the icon associated with the file type.
  ///     Returns [Icons.insert_drive_file] for unknown file types.
  /// Example:
  ///   - If the [fileType] is `csv`, returns `Icons.table_chart`.
  ///   - If the [fileType] is `json`, returns `Icons.data_object`.
  ///   - If the [fileType] is `xlsx`, returns `Icons.grid_on`.
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

  /// [_getFileColor] determines the appropriate color for a given file type.
  ///
  /// This method uses a switch statement to map file types (CSV, JSON, XLSX) to
  /// their corresponding colors from Flutter's Colors library. If the file type
  /// does not match any of the specified cases, it defaults to a generic grey
  /// color.
  ///
  /// Parameters:
  ///   - [fileType]: A [String] representing the file type (e.g., 'csv', 'json').
  ///
  /// Returns:
  ///   - A [Color] object representing the color associated with the file type.
  ///     Returns [Colors.grey] for unknown file types.
  /// Example:
  ///   - If the [fileType] is `csv`, returns `Colors.green`.
  ///   - If the [fileType] is `json`, returns `Colors.orange`.
  ///   - If the [fileType] is `xlsx`, returns `Colors.blue`.
  /// [_getFileIcon] determines the appropriate icon for a given file type.
  ///
  /// This method uses a switch statement to map file types (CSV, JSON, XLSX) to
  /// their corresponding icons from Flutter's Icons library. If the file type
  /// does not match any of the specified cases, it defaults to a generic file
  /// icon.
  ///
  /// Parameters:
  ///   - [fileType]: A [String] representing the file type (e.g., 'csv', 'json').
  ///
  /// Returns:
  ///   - An [IconData] object representing the icon associated with the file type.
  ///     Returns [Icons.insert_drive_file] for unknown file types.

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

  /// [_showClearConfirmationDialog] displays a confirmation dialog when the user attempts to clear all recent imports.
  ///
  /// This method creates and shows an [AlertDialog] that asks the user to confirm their intention
  /// to clear all recent imports from the application. The dialog provides two options:
  ///
  /// - **Cancel**: Dismisses the dialog without taking any action, preserving the list of recent imports.
  /// - **Clear All**: Executes the [_clearAllRecentImports] method to remove all recent imports,
  ///   then closes the dialog. This button is highlighted in red to indicate it's a destructive action.
  ///
  /// The dialog contains:
  /// - A title clearly stating the purpose of the dialog ("Clear Recent Imports")
  /// - Content text explaining the consequences of the action and that it cannot be undone
  /// - Action buttons for confirming or canceling the operation
  ///
  /// This method uses the [showDialog] function to display a modal dialog that requires user
  /// interaction before returning to the main interface, ensuring that accidental clicks do not
  /// result in data loss.
  ///
  /// The method doesn't take any parameters and doesn't return any values. It directly interacts
  /// with the Flutter widget tree and user interface.

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Recent Imports'),
          content: Text(
            'Are you sure you want to clear all recent imports? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearAllRecentImports();
                Navigator.of(context).pop();
              },
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// [_clearAllRecentImports] removes all recent import history and resets the current dataset.
  ///
  /// This method performs a complete cleanup of the user's import history by:
  /// - Deleting all recent imports data from the [recentImportsBox] persistent storage
  /// - Removing the currently selected dataset information from storage
  /// - Resetting the state variables ([currentDataset], [currentDatasetPath],
  ///   [currentDatasetType]) to null
  /// - Notifying listeners via [selectedDatasetNotifier] that no dataset is selected
  /// - Displaying a confirmation message to the user via a [SnackBar]
  ///
  /// The method executes when the user confirms the "Clear All" action in the
  /// confirmation dialog displayed by [_showClearConfirmationDialog]. This is a
  /// destructive action that cannot be undone, as it permanently removes the list
  /// of recently imported datasets from the application's storage.
  ///
  /// After this method executes, the recent imports sidebar will show the empty state,
  /// and any previously selected dataset will no longer be available for immediate use.

  void _clearAllRecentImports() {
    recentImportsBox.delete('recentImports');
    recentImportsBox.delete('currentDatasetName');
    recentImportsBox.delete('currentDatasetPath');
    recentImportsBox.delete('currentDatasetType');

    setState(() {
      currentDataset = null;
      currentDatasetPath = null;
      currentDatasetType = null;
    });

    selectedDatasetNotifier.value = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All recent imports have been cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
