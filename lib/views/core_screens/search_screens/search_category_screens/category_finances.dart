import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/api_config/popular_datasets.dart';

import '../../../../widgets/popular_dataset_card.dart';

/// A StatefulWidget that displays the 'Finances' category search screen.
///
/// This screen shows a list of popular datasets related to finances
/// and allows the user to search within the finance category.
class CategoryFinances extends StatefulWidget {
  final Function(String) onSearch;

  /// A callback function triggered when a search is initiated within the
  /// finance category. It passes the search term as an argument.

  /// Creates a [CategoryFinances] widget.
  ///
  /// [onSearch] is a callback function that is called when a search is initiated.
  const CategoryFinances({super.key, required this.onSearch});

  @override
  State<CategoryFinances> createState() => _CategoryFinancesState();
}

/// The state for [CategoryFinances].
class _CategoryFinancesState extends State<CategoryFinances> with SingleTickerProviderStateMixin {
  /// Controls the scrolling behavior of the horizontal list of featured datasets.
  final ScrollController scrollController = ScrollController();
  /// Manages the animation for the visibility of the featured datasets section.
  late AnimationController _featuredSectionController;
  /// Defines the animation properties for the featured datasets section.
  late Animation<double> _featuredSectionAnimation;

  /// Controls the scrolling behavior of the main list of popular datasets.
  final ScrollController _mainScrollController = ScrollController();

  /// The distance in pixels a user needs to scroll before the header starts to hide.
  final double _scrollThreshold = 50.0;
  /// Indicates whether the user is scrolling down.
  bool _isScrollingDown = false;
  /// Stores the previous scroll position to determine the scrolling direction.
  double _lastScrollPosition = 0;

  /// Indicates whether the popular datasets are still being loaded.
  bool isLoading = true;
  /// Holds the list of popular finance datasets.
  List<PopularDataset> popularDatasets = [];

  /// Determines whether the header (featured datasets section) is visible.
  bool isHeaderVisible = true;

  /// Initializes the state of the widget.
  ///
  /// This method is called when the widget is inserted into the widget tree.
  /// It initializes the animation controller for the featured section,
  /// sets up the animation properties, adds a listener to the main scroll
  /// controller to handle scrolling events, and initiates the fetching
  /// of popular finance datasets.
  ///
  /// - `_featuredSectionController`: Configured to manage the animation of the featured
  ///   section's visibility.
  /// - `_featuredSectionAnimation`: Defines the animation curve and applies it to the
  ///   animation controller.
  /// - `_mainScrollController`: A listener is added to track scrolling behavior.
  /// - `_fetchPopularDatasets()`: This function is called to load the initial dataset.
  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _featuredSectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0, // Start fully visible
    );

    _featuredSectionAnimation = CurvedAnimation(
      parent: _featuredSectionController,
      curve: Curves.easeInOutCubic,
    );

    // Set up scroll listener
    _mainScrollController.addListener(_handleScroll);

    // Fetch finance datasets
    _fetchPopularDatasets();
  }

  /// Handles scroll events to show or hide the featured datasets section.
  ///
  /// This method is called whenever the user scrolls the main list of popular
  /// datasets. It determines the scroll direction and position, and updates
  /// the `isHeaderVisible` state and triggers the featured section's animation
  /// accordingly.
  ///
  /// - If the user is at the top, the header is made visible.
  /// - If scrolling down and past the threshold, the header is hidden.
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

  /// Fetches the popular finance datasets from the service.
  ///
  /// This method uses `PopularDatasetService` to fetch a list of popular
  /// finance datasets. It updates the `popularDatasets` and `isLoading` states
  /// based on the result of the fetch.
  ///
  /// If an error occurs during the fetch, it updates the `isLoading` state
  /// and prints an error message to the console.
  Future<void> _fetchPopularDatasets() async {
    try {
      final service = PopularDatasetService();
      final datasets = await service.fetchPopularFinanceDatasets();
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

  /// Disposes of resources used by the widget.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It is used to release resources such as the animation controller and
  /// scroll controllers, which can help prevent memory leaks.
  ///
  /// - `_featuredSectionController`: Clears the animation.
  /// - `_mainScrollController`: Removes the listener and dispose of it.
  /// - `scrollController`: Disposes of the horizontal scroll.
  @override
  void dispose() {
    _featuredSectionController.dispose();
    _mainScrollController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// Builds the UI for the category finances screen.
  ///
  /// This method constructs the layout of the screen, including the
  /// featured datasets section and the list of popular finance datasets.
  /// It uses various widgets like `Scaffold`, `SafeArea`, `Column`,
  /// `AnimatedBuilder`, `SizeTransition`, `FadeTransition`, `ListView`,
  /// and `PopularDatasetCard` to create the interactive elements of the screen.
  ///
  /// - The layout adapts to different screen sizes based on the `isSmallScreen`
  ///   variable.
  /// - It uses `AnimatedBuilder` to animate the visibility of the featured
  ///   datasets section.
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
                      'Featured Finance Datasets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: isSmallScreen
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
                      'Popular Finance Datasets',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of finance datasets
                    Expanded(
                      child: isLoading
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
                              'No finance datasets found',
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
  /// Builds a list of dataset cards for the featured datasets section.
  ///
  /// This method creates a list of `DatasetCard` widgets, each representing
  /// a featured dataset. It uses predefined icons, labels, sub-labels, and
  /// search terms for each card. The cards are designed to navigate the user
  /// to a search page pre-filled with a specific query related to the dataset.
  ///
  /// - Each card includes a light and dark icon, a label, a sub-label, and a
  ///   search button.
  /// - The `onButtonClick` callback triggers a search with the specified term.
  List<Widget> _buildDatasetCards(double gap) {
    return [
      DatasetCard(
        lightIconPath: AppIcons.chartLight,
        labelText: 'Stock Market Analysis',
        subLabelText: 'Historical stock prices and financial indicators',
        buttonText: 'Search',
        darkIconPath: AppIcons.chartDark,
        onButtonClick: () => widget.onSearch('Stock Market Analysis'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.chartLight,
        darkIconPath: AppIcons.chartDark,
        labelText: 'Financial Reports',
        subLabelText: 'Company earnings, balance sheets, and cash flow data',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Financial Reports'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.chartLight,
        darkIconPath: AppIcons.chartDark,
        labelText: 'Banking & Investment',
        subLabelText: 'Credit scoring, risk analysis, and investment performance',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Banking Investment'),
      ),
    ];
  }
}
