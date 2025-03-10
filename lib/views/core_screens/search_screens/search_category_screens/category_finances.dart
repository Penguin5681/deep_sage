// import 'package:flutter/material.dart';

// import '../../../../core/config/api_config/popular_datasets.dart';

// class CategoryFinances extends StatefulWidget {
//   final Function(String) onSearch;

//   const CategoryFinances({super.key, required this.onSearch});

//   @override
//   State<CategoryFinances> createState() => _CategoryFinancesState();
// }

// class _CategoryFinancesState extends State<CategoryFinances> {
//   final ScrollController scrollController = ScrollController();
//   String selectedPlatform = 'Hugging Face';
//   String selectedFilter = 'Downloads';

//   final Map<String, List<String>> filterOptions = {
//     'Hugging Face': ['Downloads', 'Trending', 'Modified'],
//     'Kaggle': ['Hottest', 'Votes', 'Updated', 'Active', 'Published'],
//   };

//   List<Map<String, String>> popularDatasets = [];

//   final FocusNode platformFocusNode = FocusNode();
//   final FocusNode filterFocusNode = FocusNode();

//   Future<void> fetchPopularDatasets() async {
//     final service = PopularDatasetService();
//     try {
//       final datasets = await service.fetchPopularDatasets();
//       setState(() {
//         popularDatasets =
//             datasets
//                 .map(
//                   (dataset) => {
//                     'title': dataset.title,
//                     'addedTime': dataset.addedTime,
//                     'fileType': dataset.fileType,
//                     'fileSize': dataset.fileSize,
//                   },
//                 )
//                 .toList();
//       });
//     } catch (e) {
//       debugPrint('Error fetching popular datasets: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }

// }

import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:flutter/material.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/api_config/popular_datasets.dart';

class CategoryFinances extends StatefulWidget {
  final Function(String) onSearch;

  const CategoryFinances({super.key, required this.onSearch});

  @override
  State<CategoryFinances> createState() => _CategoryFinancesState();
}

class _CategoryFinancesState extends State<CategoryFinances> {
  final ScrollController scrollController = ScrollController();
  List<Map<String, String>> popularDatasets = [];

  @override
  void initState() {
    super.initState();
    fetchPopularDatasets();
  }

  Future<void> fetchPopularDatasets() async {
    final service = PopularDatasetService();
    try {
      final datasets = await service.fetchPopularDatasets();
      setState(() {
        popularDatasets = datasets
            .where((dataset) => dataset.category == 'Finances')
            .map((dataset) => {
                  'title': dataset.title,
                  'addedTime': dataset.addedTime,
                  'fileType': dataset.fileType,
                  'fileSize': dataset.fileSize,
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching popular datasets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 35.0, right: 35.0),
        child: Column(
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
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'View Financial Reports',
                      subLabelText: 'Annual and quarterly financial reports',
                      buttonText: 'Search',
                      onSearch: () => widget.onSearch('Financial Reports'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Explore Stock Market Data',
                      subLabelText: 'Historical stock prices and data',
                      buttonText: 'Search',
                      onSearch: () => widget.onSearch('Stock Market Data'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Economic Indicators',
                      subLabelText: 'GDP, inflation, and other economic data',
                      buttonText: 'Search',
                      onSearch: () => widget.onSearch('Economic Indicators'),
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
                        datasetId: dataset['title']!,
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),
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