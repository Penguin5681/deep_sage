import 'package:deep_sage/views/core_screens/visualization/tabs/data_cleaning_tab.dart';
import 'package:deep_sage/views/core_screens/visualization/tabs/raw_data_tab.dart';
import 'package:deep_sage/views/core_screens/visualization/tabs/visualize_tab.dart';
import 'package:flutter/material.dart';

class VisualizationAndExplorerScreens extends StatefulWidget {
  const VisualizationAndExplorerScreens({super.key});

  @override
  State<VisualizationAndExplorerScreens> createState() => _VisualizationAndExplorerScreensState();
}

class _VisualizationAndExplorerScreensState extends State<VisualizationAndExplorerScreens>
    with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 35.0),
            child: const Text('Explorer > Raw Data'),
          ),
          TabBar(
            padding: const EdgeInsets.only(left: 35.0, right: 35.0),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: isDarkMode ? Colors.white : Colors.black,
            unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey,
            indicatorColor: isDarkMode ? Colors.white : Colors.black,
            indicatorAnimation: TabIndicatorAnimation.elastic,
            controller: tabController,
            tabs: const [Tab(text: 'Raw Data'), Tab(text: 'Data cleaning'), Tab(text: 'Visualize')],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [RawDataTab(), DataCleaningTab(), VisualizeTab()],
            ),
          ),
        ],
      ),
    );
  }
}
