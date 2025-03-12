// import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
// import 'package:flutter/material.dart';
// import 'package:deep_sage/widgets/dataset_card.dart';
// import 'package:deep_sage/core/config/helpers/app_icons.dart';

// class CategoryFinances extends StatefulWidget {
//   final Function(String) onSearch;

//   const CategoryFinances({super.key, required this.onSearch});

//   @override
//   State<CategoryFinances> createState() => _CategoryFinancesState();
// }

// class _CategoryFinancesState extends State<CategoryFinances> {
//   final ScrollController scrollController = ScrollController();
//   List<Map<String, String>> popularDatasets = [];

//   @override
//   void initState() {
//     super.initState();
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.only(top: 25.0, left: 35.0, right: 35.0),
//         child: Column(
//           children: [
//             Scrollbar(
//               thumbVisibility: false,
//               thickness: 4,
//               radius: const Radius.circular(20),
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     DatasetCard(
//                       lightIconPath: AppIcons.aiLight,
//                       darkIconPath: AppIcons.aiDark,
//                       labelText: 'Explore AI & Tech Trends',
//                       subLabelText: 'Latest datasets on AI, ML, and emerging technologies',
//                       buttonText: 'Search',
//                       onButtonClick: () => widget.onSearch('AI & Tech Trends'),
//                     ),
//                     const SizedBox(width: 25),
//                     DatasetCard(
//                       lightIconPath: AppIcons.aiLight,
//                       darkIconPath: AppIcons.aiDark,
//                       labelText: 'Explore IoT Data',
//                       subLabelText: 'Internet of Things data and trends',
//                       buttonText: 'Search',
//                       onButtonClick: () => widget.onSearch('IoT Data'),
//                     ),
//                     const SizedBox(width: 25),
//                     DatasetCard(
//                       lightIconPath: AppIcons.aiLight,
//                       darkIconPath: AppIcons.aiDark,
//                       labelText: 'Explore Cloud Computing',
//                       subLabelText: 'Cloud infrastructure and services data',
//                       buttonText: 'Search',
//                       onButtonClick: () => widget.onSearch('Cloud Computing'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Popular Datasets',
//               style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: popularDatasets.length,
//                 itemBuilder: (context, index) {
//                   final dataset = popularDatasets[index];
//                   return Column(
//                     children: [
//                       FileListItem(
//                         icon: Icons.dataset_sharp,
//                         title: dataset['title']!,
//                         addedTime: dataset['addedTime']!,
//                         fileType: dataset['fileType']!,
//                         fileSize: dataset['fileSize']!,
//                         datasetId: dataset['title']!,
//                       ),
//                       Divider(height: 1, thickness: 1, color: Colors.grey[200]),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
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
  List<PopularDataset> popularDatasets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPopularDatasets();
  }

  Future<void> _fetchPopularDatasets() async {
    try {
      final service = PopularDatasetService();
      final datasets = await service.fetchPopularFinanceDatasets();
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
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Explore Stock Market Data',
                      subLabelText: 'Latest datasets on stock market trends and analysis',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('Stock Market Data'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Explore Cryptocurrency Data',
                      subLabelText: 'Cryptocurrency trends and analysis',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('Cryptocurrency Data'),
                    ),
                    const SizedBox(width: 25),
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Explore Banking Data',
                      subLabelText: 'Banking and financial services data',
                      buttonText: 'Search',
                      onButtonClick: () => widget.onSearch('Banking Data'),
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
              child: isLoading
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