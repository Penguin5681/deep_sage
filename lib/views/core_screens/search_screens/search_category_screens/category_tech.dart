/// This file contains the implementation for the CategoryTechnology widget,
/// which displays a list of technology-related datasets.
library;

import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:flutter/material.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/api_config/popular_datasets.dart';

/// CategoryTechnology widget for displaying technology-related datasets.
class CategoryTechnology extends StatefulWidget {
  /// Callback function for handling search actions.
  final Function(String) onSearch;

  /// Constructor for CategoryTechnology widget.
  ///
  /// [onSearch] is a callback function invoked when a user initiates a search.
  const CategoryTechnology({super.key, required this.onSearch});

  @override
  State<CategoryTechnology> createState() => _CategoryTechnologyState();
}

class _CategoryTechnologyState extends State<CategoryTechnology> {
  /// Scroll controller for managing the scrollable content.
  final ScrollController scrollController = ScrollController();

  /// List to store popular datasets.
  List<PopularDataset> popularDatasets = [];

  /// Indicates if the data is still loading.
  bool isLoading = true;

  @override
  void initState() {
    /// Fetches popular datasets when the widget is initialized.
    super.initState();
    _fetchPopularDatasets();
  }

  Future<void> _fetchPopularDatasets() async {
    try {
      final service = PopularDatasetService();

      /// Fetches popular technology datasets from the service.
      ///
      /// Updates the state with the fetched data or error status.
      final datasets = await service.fetchPopularTechnologyDatasets();
      setState(() {
        popularDatasets = datasets;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        debugPrint('Error fetching popular datasets: $e');
      });
    }
  }

  /// Builds the UI for the CategoryTechnology widget.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 35.0, right: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          /// Contains a scrollable list of dataset cards.
          children: [
            Scrollbar(
              thumbVisibility: false,
              thickness: 4,
              radius: const Radius.circular(20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  /// Dataset cards for AI, IoT, and Cloud Computing.
                  children: [
                    DatasetCard(
                      lightIconPath: AppIcons.aiLight,
                      darkIconPath: AppIcons.aiDark,
                      labelText: 'Explore AI & Tech Trends',
                      subLabelText:
                          'Latest datasets on AI, ML, and emerging technologies',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('AI & Tech Trends'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.aiLight,
                      darkIconPath: AppIcons.aiDark,
                      labelText: 'Explore IoT Data',
                      subLabelText: 'Internet of Things data and trends',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('IoT Data'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.aiLight,
                      darkIconPath: AppIcons.aiDark,
                      labelText: 'Explore Cloud Computing',
                      subLabelText: 'Cloud infrastructure and services data',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('Cloud Computing'),
                    ),
                  ],
                ),
              ),
            ),

            /// Spacing between the scrollable area and the title.
            const SizedBox(height: 20),

            /// Title for the popular datasets section.
            const Text(
              'Popular Datasets',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              /// Displays a loading indicator or the list of popular datasets.
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: popularDatasets.length,
                        itemBuilder: (context, index) {
                          final dataset = popularDatasets[index];
                          return Column(
                            children: [
                              FileListItem(
                                icon: Icons.dataset_sharp,
                                title: dataset.title,
                                addedTime: dataset.addedTime,
                                fileType: dataset.fileType,
                                fileSize: dataset.fileSize,
                                datasetId: dataset.id,
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey[200],
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
