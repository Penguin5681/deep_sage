import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:flutter/material.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/api_config/popular_datasets.dart';

/// A StatefulWidget representing the health category screen.
///
/// This screen displays a list of popular healthcare datasets and allows
/// the user to search for specific healthcare-related data.
class CategoryHealth extends StatefulWidget {
  final Function(String) onSearch;

  /// Creates a [CategoryHealth] widget.
  ///
  /// [onSearch] is a callback that is triggered when a search action is performed.
  const CategoryHealth({super.key, required this.onSearch});

  @override
  State<CategoryHealth> createState() => _CategoryHealthState();
}

/// The state class for the [CategoryHealth] widget.
class _CategoryHealthState extends State<CategoryHealth> {
  /// Controller for the scrollable list of popular datasets.
  final ScrollController scrollController = ScrollController();
  List<PopularDataset> popularDatasets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPopularDatasets();
  }

  /// Fetches popular healthcare datasets from the server.
  ///
  /// Updates the state with the fetched datasets or handles errors.

  Future<void> _fetchPopularDatasets() async {
    try {
      final service = PopularDatasetService();
      final datasets = await service.fetchPopularHealthcareDatasets();
      setState(() {
        popularDatasets = datasets;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error appropriately
      debugPrint('Error fetching popular datasets: $e');
    }
  }

  /// Builds the UI for the health category screen.
  ///
  /// Displays a horizontal list of dataset cards for quick search
  /// and a vertical list of popular datasets.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 35.0, right: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Scrollbar(
              thumbVisibility: false,
              thickness: 4,
              radius: const Radius.circular(20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DatasetCard(
                      lightIconPath: AppIcons.healthLight,
                      darkIconPath: AppIcons.healthDark,
                      labelText: 'Explore Healthcare Data',
                      subLabelText:
                          'Latest datasets on healthcare trends and analysis',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('Healthcare Data'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.healthLight,
                      darkIconPath: AppIcons.healthDark,
                      labelText: 'Explore Medical Data',
                      subLabelText: 'Medical research and clinical data',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('Medical Data'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.healthLight,
                      darkIconPath: AppIcons.healthDark,
                      labelText: 'Explore Pharmaceutical Data',
                      subLabelText: 'Pharmaceutical research and drug data',
                      buttonText: 'Search',
                      onButtonClick:
                          () => widget.onSearch('Pharmaceutical Data'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Popular Datasets',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
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
