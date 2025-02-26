import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 35.0),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Home', style: TextStyle(fontSize: 16.0)),
                  ),
                ),
                const Text('  >  ', style: TextStyle(fontSize: 16.0)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Search',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 25.0, right: 35.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchBar(controller, (value) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Search has been completed'),
                        content: Text('You Searched for: $value'),
                      );
                    },
                  );
                }),
                const SizedBox(height: 25.0),
              ],
            ),
          ),
          TabBar(
            padding: EdgeInsets.only(right: 650.0),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: isDarkMode ? Colors.white : Colors.black,
            unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey,
            indicatorColor: isDarkMode ? Colors.white : Colors.black,
            indicatorAnimation: TabIndicatorAnimation.elastic,
            controller: tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Finances'),
              Tab(text: 'Technology'),
              Tab(text: 'Healthcare'),
              Tab(text: 'Government'),
              Tab(text: 'Manufacturing'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                // list of screens links to the respective tabs
                CategoryAll(),
                Center(child: Text('Screen 2')),
                Center(child: Text('Screen 3')),
                Center(child: Text('Screen 4')),
                Center(child: Text('Screen 5')),
                Center(child: Text('Screen 6')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget searchBar(
    TextEditingController controller,
    ValueChanged<String>? onSubmitted,
  ) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        hintText: 'Search Datasets by name, type or category',
      ),
    );
  }
}
