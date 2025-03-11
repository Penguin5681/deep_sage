import 'package:deep_sage/views/core_screens/folder_screens/folder_all.dart';
import 'package:deep_sage/views/core_screens/folder_screens/folder_starred.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:path/path.dart' as path;

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  late String rootDirectoryName = '';

  @override
  void initState() {
    super.initState();
    _loadRootDirectory();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRootDirectory() async {
    final boxName = dotenv.env['API_HIVE_BOX_NAME']!;
    final hiveBox = await Hive.openBox(boxName);

    final root = hiveBox.get('selectedRootDirectoryPath');
    if (root != null) {
      setState(() {
        rootDirectoryName = root;
      });
    } else {
      debugPrint('Root not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 35.0),
            child: Text('Datasets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Text(
              path.basename(rootDirectoryName),
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: MediaQuery.of(context).size.width / 4.5,
            // height: MediaQuery.of(context).size.height,
            child: TabBar(
              // labelPadding: EdgeInsets.only(right: 40),
              enableFeedback: false,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: isDarkMode ? Colors.white : Colors.black,
              unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey,
              indicatorColor: isDarkMode ? Colors.white : Colors.black,
              indicatorAnimation: TabIndicatorAnimation.elastic,
              controller: tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Recent'),
                Tab(text: 'Starred'),
                Tab(text: 'Shared'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [FolderAll(), FolderAll(), FolderStarred(), FolderAll()],
            ),
          ),
        ],
      ),
    );
  }
}
