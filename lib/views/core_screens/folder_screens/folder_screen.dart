import 'package:deep_sage/views/core_screens/folder_screens/folder_all.dart';
import 'package:deep_sage/views/core_screens/folder_screens/folder_recent.dart';
import 'package:deep_sage/views/core_screens/folder_screens/folder_starred.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:path/path.dart' as path;

/// StatefulWidget that represents the folder screen.
///
/// This screen displays various dataset folders, categorized into tabs.
class FolderScreen extends StatefulWidget {
  /// Callback function for navigation events.
  final Function(int)? onNavigate;

  /// Constructor for the FolderScreen widget.
  const FolderScreen({super.key, this.onNavigate});

  /// Creates the mutable state for this widget.
  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

/// State class for the FolderScreen widget.
class _FolderScreenState extends State<FolderScreen>
    with SingleTickerProviderStateMixin {
  /// TabController to manage the tabs.
  late TabController tabController;

  /// Name of the root directory.
  late String rootDirectoryName = '';

  /// Initializes the state of the widget.
  @override
  void initState() {
    // Load the root directory information and initialize the tab controller.
    super.initState();
    _loadRootDirectory();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    // Dispose of the tab controller when the widget is disposed.
    tabController.dispose();
    super.dispose();
  }

  /// Loads the root directory information from Hive storage.
  Future<void> _loadRootDirectory() async {
    // Retrieve the Hive box name from the environment variables.
    final boxName = dotenv.env['API_HIVE_BOX_NAME']!;
    // Open the Hive box.
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

  /// Builds the UI for the FolderScreen.
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 18.0,
              horizontal: 35.0,
            ),
            child: Text(
              'Datasets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
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
              children: [
                FolderAll(onNavigate: widget.onNavigate),
                FolderRecent(onNavigate: widget.onNavigate),
                FolderStarred(),
                FolderStarred(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
