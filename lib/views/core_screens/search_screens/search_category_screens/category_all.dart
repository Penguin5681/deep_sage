import 'package:deep_sage/core/config/api_config/popular_datasets.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/download_overlay_service.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/widgets/kaggle_credentials_prompt.dart';
import 'package:deep_sage/widgets/popular_dataset_card.dart';
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

class _CategoryAllState extends State<CategoryAll> with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _featuredSectionController;
  late Animation<double> _featuredSectionAnimation;

  // Scroll controllers
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController scrollController = ScrollController();

  // Sort parameters
  final List<String> _sortParams = ['hottest', 'votes', 'updated', 'active', 'published'];
  int _currentSortIndex = 0;

  String get _currentSortParam => _sortParams[_currentSortIndex];

  // Scroll tracking variables
  final double _scrollThreshold = 50.0; // Increased threshold for better usability
  bool _isScrollingDown = false;
  double _lastScrollPosition = 0;

  // Data state
  bool isKaggleCredsLoaded = false;
  List<Map<String, String>> popularDatasets = [];

  // Focus nodes
  final FocusNode platformFocusNode = FocusNode();
  final FocusNode filterFocusNode = FocusNode();

  // UI state
  bool isHeaderVisible = true;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with longer duration for smoother animation
    _featuredSectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0, // Start fully visible
    );

    _featuredSectionAnimation = CurvedAnimation(
      parent: _featuredSectionController,
      curve: Curves.easeInOutCubic, // Smoother curve for better animation
    );

    // Set up scroll listener
    _mainScrollController.addListener(_handleScroll);

    // Check authentication on startup
    Future.delayed(Duration.zero, () {
      checkKaggleAuthentication();
    });
  }

  void _handleScroll() {
    final currentPosition = _mainScrollController.position.pixels;

    // At the top, make sure header is visible
    if (currentPosition <= 0) {
      if (!isHeaderVisible) {
        setState(() {
          isHeaderVisible = true;
        });
      }
      _featuredSectionController.animateTo(1.0);
      return;
    }

    // Determine scroll direction
    _isScrollingDown = currentPosition > _lastScrollPosition;
    _lastScrollPosition = currentPosition;

    // Show/hide based on direction and threshold
    if (_isScrollingDown && currentPosition > _scrollThreshold) {
      // Hide featured section when scrolling down past threshold
      if (isHeaderVisible) {
        setState(() {
          isHeaderVisible = false;
        });
      }
      _featuredSectionController.animateTo(0.0);
    } else if (!_isScrollingDown && currentPosition < _scrollThreshold * 2) {
      // Show featured section when scrolling up and near top
      if (!isHeaderVisible) {
        setState(() {
          isHeaderVisible = true;
        });
      }
      _featuredSectionController.animateTo(1.0);
    }
  }

  Future<void> fetchPopularDatasets() async {
    final service = PopularDatasetService();
    try {
      final datasets = await service.fetchPopularDatasets(sortBy: _currentSortParam);
      if (mounted) {
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
      }
    } catch (e) {
      debugPrint('Error fetching popular datasets: $e');
    }
  }

  Future<void> checkKaggleAuthentication() async {
    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

      final data = hiveBox.getAt(0);
      UserApi? userApiData;

      if (data is UserApi) {
        userApiData = data;
      } else if (data != null) {
        debugPrint('Invalid data type in Hive: ${data.runtimeType}');
      }

      if (userApiData != null &&
          userApiData.kaggleUserName.isNotEmpty &&
          userApiData.kaggleApiKey.isNotEmpty) {
        if (mounted) {
          setState(() {
            isKaggleCredsLoaded = true;
          });
        }
        await fetchPopularDatasets();
      } else {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: KaggleCredentialsPrompt(
                  onCredentialsAdded: () {
                    setState(() {
                      isKaggleCredsLoaded = true;
                    });
                    fetchPopularDatasets();
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking Kaggle authentication: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to check credentials. Please try again.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
              ),
        );
      }
    }
  }

  Future<void> refreshDatasets() async {
    setState(() {
      _currentSortIndex = (_currentSortIndex + 1) % _sortParams.length;
    });
    await fetchPopularDatasets();
  }

  @override
  void dispose() {
    _featuredSectionController.dispose();
    _mainScrollController.dispose();
    scrollController.dispose();
    platformFocusNode.dispose();
    filterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 800;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Animated Featured Datasets section with improved animation
            AnimatedBuilder(
              animation: _featuredSectionAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _featuredSectionAnimation,
                  axisAlignment: -1.0, // Align to the top
                  child: FadeTransition(opacity: _featuredSectionAnimation, child: child),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 35.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Datasets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child:
                          isSmallScreen
                              ? ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: _buildDatasetCards(16),
                              )
                              : Listener(
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
                                  thumbVisibility: true,
                                  thickness: 4,
                                  radius: const Radius.circular(20),
                                  child: ListView(
                                    physics: const BouncingScrollPhysics(),
                                    controller: scrollController,
                                    scrollDirection: Axis.horizontal,
                                    children: _buildDatasetCards(25),
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Popular Datasets section
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 35.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with sort button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Datasets',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 30,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: refreshDatasets,
                          tooltip:
                              'Change sort: ${_sortParams[(_currentSortIndex + 1) % _sortParams.length]}',
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_vert, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _currentSortParam.capitalize(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Sort indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      child: Text(
                        'Sorted by ${_currentSortParam.replaceAll('_', ' ')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // List of datasets
                    Expanded(
                      child:
                          popularDatasets.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_outlined,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ), // Updated from withValues
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isKaggleCredsLoaded
                                          ? 'Loading datasets...'
                                          : 'No datasets found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                controller: _mainScrollController,
                                physics: const BouncingScrollPhysics(),
                                itemCount: popularDatasets.length,
                                itemBuilder: (context, index) {
                                  final dataset = popularDatasets[index];
                                  return PopularDatasetCard(
                                    title: dataset['title']!,
                                    addedTime: dataset['addedTime']!,
                                    fileType: dataset['fileType']!,
                                    fileSize: dataset['fileSize']!,
                                    datasetId: dataset['id']!,
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDatasetCards(double gap) {
    return [
      DatasetCard(
        lightIconPath: AppIcons.chartLight,
        labelText: 'Explore Stock Market Data',
        subLabelText: 'Historical Stock prices and data',
        buttonText: 'Search',
        darkIconPath: AppIcons.chartDark,
        onButtonClick: () => widget.onSearch('Stock Market Data'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.aiLight,
        darkIconPath: AppIcons.aiDark,
        labelText: 'Explore AI & Tech Trends',
        subLabelText: 'Latest datasets on AI, ML, and emerging technologies',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('AI & Tech Trends'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.healthLight,
        darkIconPath: AppIcons.healthDark,
        labelText: 'Explore Healthcare Insights',
        subLabelText: 'Medical research, patient statistics, and health trends',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Healthcare Insights'),
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final downloadService = Provider.of<DownloadService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icon, color: textTheme.bodyLarge?.color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            icon: Icon(Icons.file_download_outlined, color: textTheme.bodyLarge?.color),
            onPressed: () async {
              await downloadService.downloadDataset(source: 'kaggle', datasetId: datasetId);
              if (!context.mounted) return;
              final overlayService = Provider.of<DownloadOverlayService>(context, listen: false);
              overlayService.showDownloadOverlay();
            },
          ),
        ],
      ),
    );
  }
}
