import 'package:deep_sage/core/config/api_config/popular_datasets.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/download_overlay_service.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/widgets/kaggle_credentials_prompt.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/hive_models/user_api_model.dart';
import '../../../../core/services/download_service.dart';

class CategoryAll extends StatefulWidget {
  final Function(String) onSearch;

  const CategoryAll({super.key, required this.onSearch});

  @override
  State<CategoryAll> createState() => _CategoryAllState();
}

/// Represents the state for the CategoryAll widget.
///
/// This class manages the UI and logic for displaying all dataset categories,
/// including fetching, sorting, and displaying datasets, and handling Kaggle
/// authentication.
class _CategoryAllState extends State<CategoryAll> {
  final List<String> _sortParams = [
    'hottest',
    'votes',
    'updated',
    'active',
    'published',
  ];

  /// Index for the current sorting parameter.
  int _currentSortIndex = 0;

  /// Returns the current sorting parameter based on [_currentSortIndex].
  String get _currentSortParam => _sortParams[_currentSortIndex];

  /// Controller for the scrollable list of datasets.
  final ScrollController scrollController = ScrollController();

  /// Flag to indicate if Kaggle credentials have been loaded.
  late bool isKaggleCredsLoaded = false;

  /// List to store popular datasets fetched from the service.
  List<Map<String, String>> popularDatasets = [];

  /// Focus node for platform-related focus.
  final FocusNode platformFocusNode = FocusNode();

  /// Focus node for filter-related focus.
  final FocusNode filterFocusNode = FocusNode();

  /// Flag to indicate if the download overlay is visible.
  bool isDownloadOverlayVisible = false;

  /// Initializes the state and checks for Kaggle authentication on startup.
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      checkKaggleAuthentication();
    });
  }

  Future<void> fetchPopularDatasets() async {
    final service = PopularDatasetService();
    try {
      final datasets = await service.fetchPopularDatasets(
        sortBy: _currentSortParam,
      );
      setState(() {
        popularDatasets =
            datasets
                .map(
                  (dataset) => {
                    'title': dataset.title,
                    'addedTime': dataset.addedTime,
                    'fileType': dataset.fileType,
                    'fileSize': dataset.fileSize,
                    'id': dataset.id,
                  },
                )
                .toList();
      });
    } catch (e) {
      debugPrint('Error fetching popular datasets: $e');
    }
  }

  /// Checks for Kaggle authentication and prompts the user for credentials if not found.
  ///
  /// This method looks for stored Kaggle credentials in Hive. If valid
  /// credentials are found, it fetches popular datasets. If not, it displays a
  /// prompt to the user to enter their Kaggle username and API key. Errors
  /// during the process are also handled.
  Future checkKaggleAuthentication() async {
    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

      final data = hiveBox.getAt(0);
      UserApi? userApiData;

      if (data is UserApi) {
        userApiData = data;
      } else if (data != null) {
        debugPrint('Invalid data type in Hive: ${data.runtimeType}');
        // await hiveBox.clear();
      }

      if (userApiData != null &&
          userApiData.kaggleUserName.isNotEmpty &&
          userApiData.kaggleApiKey.isNotEmpty) {
        setState(() {
          isKaggleCredsLoaded = true;
        });
        fetchPopularDatasets();
      } else {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: KaggleCredentialsPrompt(
                  onCredentialsAdded: () {
                    Navigator.of(context).pop();
                    setState(() {
                      isKaggleCredsLoaded = true;
                    });
                    fetchPopularDatasets();
                  },
                ),
              );
            },
          );
        }
        debugPrint('No valid Kaggle credentials found.');
      }
    } catch (e) {
      debugPrint('Error checking Kaggle authentication: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Error'),
                content: Text('Failed to check credentials. Please try again.'),
                actions: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  /// Refreshes the datasets by changing the sort parameter and refetching.
  ///
  /// This method cycles through the available sort parameters and triggers a
  /// new fetch of datasets. It's used to update the displayed datasets with a
  /// different sorting order.
  Future<void> refreshDatasets() async {
    setState(() {
      _currentSortIndex = (_currentSortIndex + 1) % _sortParams.length;
    });
    await fetchPopularDatasets();
    debugPrint('Fetching datasets sorted by: $_currentSortParam');
  }

  /// Disposes of the focus nodes when the widget is removed from the widget tree.
  @override
  void dispose() {
    platformFocusNode.dispose();
    filterFocusNode.dispose();
    super.dispose();
  }

  /// Builds the UI for the CategoryAll screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 35.0, right: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Listener(
              onPointerSignal: (PointerSignalEvent event) {
                if (event is PointerScrollEvent) {
                  final offset = event.scrollDelta.dy;
                  scrollController.animateTo(
                    (scrollController.offset + offset).clamp(
                      0.0,
                      scrollController.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: false,
                thickness: 4,
                radius: const Radius.circular(20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DatasetCard(
                        lightIconPath: AppIcons.chartLight,
                        labelText: 'Explore Stock Market Data',
                        subLabelText: 'Historical Stock prices and data',
                        buttonText: 'Search',
                        darkIconPath: AppIcons.chartDark,
                        onButtonClick:
                            () => widget.onSearch('Stock Market Data'),
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.aiLight,
                        darkIconPath: AppIcons.aiDark,
                        labelText: 'Explore AI & Tech Trends',
                        subLabelText:
                            'Latest datasets on AI, ML, and emerging technologies',
                        buttonText: 'Search',
                        onButtonClick:
                            () => widget.onSearch('AI & Tech Trends'),
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.healthLight,
                        darkIconPath: AppIcons.healthDark,
                        labelText: 'Explore Healthcare Insights',
                        subLabelText:
                            'Medical research, patient statistics, and health trends',
                        buttonText: 'Search',
                        onButtonClick:
                            () => widget.onSearch('Healthcare Insights'),
                      ),
                      const SizedBox(width: 25),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Datasets',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: popularDatasets.length,
                itemBuilder: (context, index) {
                  final dataset = popularDatasets[index];
                  return Column(
                    children: [
                      FileListItem(
                        icon: Icons.dataset_sharp,
                        title: dataset['title']!,
                        addedTime: dataset['addedTime']!,
                        fileType: dataset['fileType']!,
                        fileSize: dataset['fileSize']!,
                        datasetId: dataset['id']!,
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: refreshDatasets,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Refresh Datasets',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget for displaying a single file list item in the dataset list.
///
/// This widget shows the file's icon, title, added time, file type, file size,
/// and a button to download the dataset.
///
/// Parameters:
///   - icon: The icon to represent the file type.
///   - title: The title of the dataset.
///   - addedTime: The time when the dataset was added.
///   - fileType: The type of the file (e.g., CSV, TXT).
///   - fileSize: The size of the file.
///   - datasetId: The unique identifier for the dataset.
class FileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String addedTime;
  final String fileType;
  final String fileSize;
  final String datasetId;

  const FileListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.addedTime,
    required this.fileType,
    required this.fileSize,
    required this.datasetId,
  });

  /// Builds the UI for a single file list item.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final downloadService = Provider.of<DownloadService>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icon, color: textTheme.bodyLarge?.color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              addedTime,
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileType,
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileSize,
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.file_download_outlined,
              color: textTheme.bodyLarge?.color,
            ),
            onPressed: () async {
              await downloadService.downloadDataset(
                source: 'kaggle',
                datasetId: datasetId,
              );
              if (!context.mounted) return;
              final overlayService = Provider.of<DownloadOverlayService>(
                context,
                listen: false,
              );
              overlayService.showDownloadOverlay();
            },
          ),
        ],
      ),
    );
  }
}
