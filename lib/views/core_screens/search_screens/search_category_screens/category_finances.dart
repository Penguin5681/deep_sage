import 'package:flutter/material.dart';

import '../../../../core/config/api_config/popular_datasets.dart';

class CategoryFinances extends StatefulWidget {
  const CategoryFinances({super.key});

  @override
  State<CategoryFinances> createState() => _CategoryFinancesState();
}

class _CategoryFinancesState extends State<CategoryFinances> {
  final ScrollController scrollController = ScrollController();
  String selectedPlatform = 'Hugging Face';
  String selectedFilter = 'Downloads';

  final Map<String, List<String>> filterOptions = {
    'Hugging Face': ['Downloads', 'Trending', 'Modified'],
    'Kaggle': ['Hottest', 'Votes', 'Updated', 'Active', 'Published'],
  };

  List<Map<String, String>> popularDatasets = [];

  final FocusNode platformFocusNode = FocusNode();
  final FocusNode filterFocusNode = FocusNode();

  Future<void> fetchPopularDatasets() async {
    final service = PopularDatasetService();
    try {
      final datasets = await service.fetchPopularDatasets();
      setState(() {
        popularDatasets =
            datasets
                .map(
                  (dataset) => {
                'title': dataset.title,
                'addedTime': dataset.addedTime,
                'fileType': dataset.fileType,
                'fileSize': dataset.fileSize,
              },
            )
                .toList();
      });
    } catch (e) {
      debugPrint('Error fetching popular datasets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
