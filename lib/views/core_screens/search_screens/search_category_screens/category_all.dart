import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CategoryAll extends StatefulWidget {
  const CategoryAll({super.key});

  @override
  _CategoryAllState createState() => _CategoryAllState();
}

class _CategoryAllState extends State<CategoryAll> {
  final ScrollController scrollController = ScrollController();
  String selectedPlatform = 'Kaggle';
  String selectedFilter = 'Hottest';

  final Map<String, List<String>> filterOptions = {
    'Kaggle': ['Hottest', 'Votes', 'Updated', 'Active', 'Published'],
    'Hugging Face': ['Downloads', 'Trending', 'Modified'],
  };

  List<Map<String, String>> popularDatasets = [
    {
      'title': 'Global Market Trends',
      'addedTime': 'Added today',
      'fileType': 'CSV',
      'fileSize': '234MB',
    },
    {
      'title': 'Consumer Behavior',
      'addedTime': 'Added 2d ago',
      'fileType': 'JSON',
      'fileSize': '156MB',
    },
    {
      'title': 'Economic Indicators',
      'addedTime': 'Added 3d ago',
      'fileType': 'CSV',
      'fileSize': '89MB',
    },
  ];

  final FocusNode platformFocusNode = FocusNode();
  final FocusNode filterFocusNode = FocusNode();

  void refreshDatasets() {
    // Logic to refresh datasets
    setState(() {
      // For demonstration, we are just reversing the list
      popularDatasets = List.from(popularDatasets.reversed);
    });
  }

  @override
  void dispose() {
    platformFocusNode.dispose();
    filterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 35.0, right: 35.0),
        child: Column(
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
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.aiLight,
                        darkIconPath: AppIcons.aiDark,
                        labelText: 'Explore AI & Tech Trends',
                        subLabelText:
                            'Latest datasets on AI, ML, and emerging technologies',
                        buttonText: 'Search',
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.healthLight,
                        darkIconPath: AppIcons.healthDark,
                        labelText: 'Explore Healthcare Insights',
                        subLabelText:
                            'Medical research, patient statistics, and health trends',
                        buttonText: 'Search',
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.governmentLight,
                        darkIconPath: AppIcons.governmentDark,
                        labelText: 'Explore Government Open Data',
                        subLabelText:
                            'Public reports, policies, and economic indicators',
                        buttonText: 'Search',
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.factoryLight,
                        darkIconPath: AppIcons.factoryDark,
                        labelText: 'Explore Manufacturing Analytics',
                        subLabelText:
                            'Production data, supply chain insights, and industrial trends',
                        buttonText: 'Search',
                      ),
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
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey),
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            focusNode: platformFocusNode,
                            value: selectedPlatform,
                            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            items: ['Kaggle', 'Hugging Face']
                                .map(
                                  (platform) => DropdownMenuItem(
                                    value: platform,
                                    child: Text(platform),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPlatform = value!;
                                selectedFilter = filterOptions[selectedPlatform]!.first;
                                platformFocusNode.unfocus();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey),
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            focusNode: filterFocusNode,
                            value: selectedFilter,
                            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            items: filterOptions[selectedPlatform]!
                                .map(
                                  (filter) => DropdownMenuItem(
                                    value: filter,
                                    child: Text(filter),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedFilter = value!;
                                filterFocusNode.unfocus();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Apply filters logic here
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 23.0,
                          ),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
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

class FileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String addedTime;
  final String fileType;
  final String fileSize;

  const FileListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.addedTime,
    required this.fileType,
    required this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            onPressed: () {
              // Download file logic here
            },
          ),
        ],
      ),
    );
  }
}