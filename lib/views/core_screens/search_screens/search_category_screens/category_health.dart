import 'package:deep_sage/core/config/api_config/popular_datasets.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/widgets/popular_dataset_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A StatefulWidget that displays the health category screen.
///
/// This screen shows featured and popular healthcare datasets,
/// and allows users to search for datasets within specific subcategories.
class CategoryHealth extends StatefulWidget {
  /// Callback function to perform a search when a dataset subcategory is selected.
  final Function(String) onSearch;

  /// Creates a [CategoryHealth] widget.
  ///
  /// [onSearch] is a required callback that is invoked when the user wants to
  /// search for datasets in a specific subcategory.
  const CategoryHealth({super.key, required this.onSearch});

  @override
  State<CategoryHealth> createState() => _CategoryHealthState();
}

/// The state for the [CategoryHealth] widget.
class _CategoryHealthState extends State<CategoryHealth> with SingleTickerProviderStateMixin {
  /// Animation controller for the featured section.
  ///
  /// Controls the visibility and animation of the featured datasets section.
  late AnimationController _featuredSectionController;

  /// Animation for the featured section.
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
      value: 1.0, // Start fully visible
    );

    _featuredSectionAnimation = CurvedAnimation(
      parent: _featuredSectionController,
      curve: Curves.easeInOutCubic,
    );

    // Set up scroll listener
    _mainScrollController.addListener(_handleScroll);

    // Fetch health datasets
    // Initialize datasets fetching
    _fetchPopularDatasets();
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

  /// Fetches popular healthcare datasets.
  ///
  /// Calls the [PopularDatasetService] to fetch data from the backend and
  /// updates the UI accordingly.
  Future<void> _fetchPopularDatasets() async {
    try {
      final service = PopularDatasetService();
      final datasets = await service.fetchPopularHealthcareDatasets();
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

  @override
  void dispose() {
    _featuredSectionController.dispose();
    _mainScrollController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// Builds the main UI of the category health screen.
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
                      'Featured Healthcare Datasets',
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
                      'Popular Healthcare Datasets',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                                      'No healthcare datasets found',
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

  /// Builds a list of [DatasetCard] widgets.
  ///
  /// This method creates and returns a list of cards representing different
  /// healthcare subcategories. Each card allows the user to search for
  /// datasets within that specific subcategory.
  /// The gap is used to manage space between each card.
  List<Widget> _buildDatasetCards(double gap) {
    return [
      DatasetCard(
        lightIconPath: AppIcons.healthLight,
        darkIconPath: AppIcons.healthDark,
        labelText: 'Medical Research Data',
        subLabelText: 'Clinical trials and medical research datasets',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Medical Research'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.healthLight,
        darkIconPath: AppIcons.healthDark,
        labelText: 'Epidemiology & Public Health',
        subLabelText: 'Disease tracking, vaccination, and population health data',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Epidemiology'),
      ),
      SizedBox(width: gap),
      DatasetCard(
        lightIconPath: AppIcons.healthLight,
        darkIconPath: AppIcons.healthDark,
        labelText: 'Genomics & Bioinformatics',
        subLabelText: 'DNA sequencing, genetic analysis, and bioinformatics data',
        buttonText: 'Search',
        onButtonClick: () => widget.onSearch('Genomics'),
      ),
    ];
  }
}
