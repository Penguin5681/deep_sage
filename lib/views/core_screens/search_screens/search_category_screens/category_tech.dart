import 'package:deep_sage/core/config/api_config/popular_datasets.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/caching_services/popular_dataset_caching_service.dart';
import '../../../../widgets/popular_dataset_card.dart';

class CategoryTechnology extends StatefulWidget {
  /// Callback function triggered when a dataset card's search button is pressed.
  ///
  /// The `onSearch` callback is responsible for handling the search action
  /// based on the text provided by the dataset card.
  final Function(String) onSearch;

  /// Constructs a [CategoryTechnology] widget.
  ///
  /// Requires an [onSearch] callback function to be passed.
  const CategoryTechnology({super.key, required this.onSearch});

  @override
  State<CategoryTechnology> createState() => _CategoryTechnologyState();
}

/// The state class for [CategoryTechnology], managing the UI and data related
/// to the technology datasets category.
class _CategoryTechnologyState extends State<CategoryTechnology>
    with SingleTickerProviderStateMixin {
  /// Controller for the animation of the featured section's visibility.
  ///
  /// This controller manages the animation for showing and hiding the
  /// "Featured Technology Datasets" section.
  late AnimationController _featuredSectionController;

  /// Animation object derived from [_featuredSectionController].
  late Animation<double> _featuredSectionAnimation;

  // Scroll controllers
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController scrollController = ScrollController();

  // Scroll tracking variables
  final double _scrollThreshold = 50.0;
  bool _isScrollingDown = false;
  double _lastScrollPosition = 0;

  // Data state
  bool isLoading = true;
  List<PopularDataset> popularDatasets = [];

  // UI state
  bool isHeaderVisible = true;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _featuredSectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),

      // Start fully visible
      value: 1.0, // Start fully visible
    );

    _featuredSectionAnimation = CurvedAnimation(
      parent: _featuredSectionController,
      curve: Curves.easeInOutCubic,
    );

    // Set up scroll listener
    _mainScrollController.addListener(_handleScroll);

    // Fetch technology datasets
    _fetchPopularDatasets();
  }

  /// Handles scroll events from [_mainScrollController].
  ///
  /// This function determines if the user is scrolling up or down and
  /// then shows or hides the header based on the scroll position and
  /// a predefined threshold.
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
      if (isHeaderVisible) {
        setState(() {
          isHeaderVisible = false;
        });
      }
      _featuredSectionController.animateTo(0.0);
    } else if (!_isScrollingDown && currentPosition < _scrollThreshold * 2) {
      if (!isHeaderVisible) {
        setState(() {
          isHeaderVisible = true;
        });
      }
      _featuredSectionController.animateTo(1.0);
    }
  }

  /// Fetches popular technology datasets from the [PopularDatasetService].
  ///
  /// This method updates the `popularDatasets` list with fetched data and
  /// sets `isLoading` to `false`. It also handles errors by logging them
  /// and updating the state accordingly.
  Future<void> _fetchPopularDatasets() async {
    final cacheService = PopularDatasetCachingService();
    final cacheKey = 'tech';

    final cachedData = cacheService.getCachedDatasets(cacheKey);
    if (cachedData != null) {
      if (mounted) {
        setState(() {
          popularDatasets = cachedData;
          isLoading = false;
        });
      }
      return;
    }

    try {
      final service = PopularDatasetService();
      final datasets = await service.fetchPopularTechnologyDatasets();

      cacheService.cacheDatasets(cacheKey, datasets);

      if (mounted) {
        setState(() {
          popularDatasets = datasets;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint('Error fetching popular datasets: $e');
    }
  }

  /// Disposes of resources used by the state.
  ///
  /// This method disposes of the animation and scroll controllers to prevent
  /// memory leaks.
  @override
  void dispose() {
    _featuredSectionController.dispose();
    _mainScrollController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// Builds the main UI for the technology category view.
  ///
  /// This method creates a [Scaffold] with two main sections:
  /// 1. An animated header section showing featured datasets.
  /// 2. A scrollable list of popular technology datasets.
  /// It also handles different layouts for small and large screens.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 800;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Animated Featured Datasets section
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
                      'Featured Technology Datasets',
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
                    Text(
                      'Popular Technology Datasets',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of technology datasets
                    Expanded(
                      child:
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : popularDatasets.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_outlined,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No datasets found',
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
                                    title: dataset.title,
                                    addedTime: dataset.addedTime,
                                    fileType: dataset.fileType,
                                    fileSize: dataset.fileSize,
                                    datasetId: dataset.id,
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

  /// Builds a list of [DatasetCard] widgets with predefined content.
  ///
  /// This method returns a list containing three [DatasetCard] widgets, each
  /// representing a specific technology-related topic. It also includes
  /// [SizedBox] widgets to provide spacing between the cards.
  ///
  /// [gap] The horizontal gap between each dataset card.
  /// Returns a list of [Widget] that represent the dataset cards.
  List<Widget> _buildDatasetCards(double gap) {
    return [
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
        lightIconPath: AppIcons.aiLight,
        darkIconPath: AppIcons.aiDark,
        labelText: 'Explore IoT Data',
        subLabelText: 'Internet of Things data and trends',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('IoT Data'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.aiLight,
        darkIconPath: AppIcons.aiDark,
        labelText: 'Explore Cloud Computing',
        subLabelText: 'Cloud infrastructure and services data',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Cloud Computing'),
      ),
    ];
  }
}
