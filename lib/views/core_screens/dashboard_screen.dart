import 'dart:io';

import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/user_image_service.dart';
import 'package:deep_sage/views/core_screens/folder_screens/folder_screen.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_screen.dart';
import 'package:deep_sage/views/core_screens/settings_screen.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var selectedIndex = 0;
  late Widget currentScreen;
  final userHiveBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
  final Image fallbackUserAvatar = Image.asset('assets/fallback/fallback_user_image.png');

  @override
  void initState() {
    super.initState();
    currentScreen = Dashboard(onNavigate: navigateToIndex);
  }

  void navigateToIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final navigatorKey = GlobalKey<NavigatorState>();

  Widget getIconForTheme({required String lightIcon, required String darkIcon, double size = 24}) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(isDarkMode ? darkIcon : lightIcon, width: size, height: size);
      },
    );
  }

  Future<Image> loadProfileImageFromHive() async {
    final imageUrl = await userHiveBox.get('userAvatarUrl');
    if (imageUrl != null) {
      return Image.network(imageUrl);
    }
    return fallbackUserAvatar;
  }

  Widget buildProfileImage() {
    return ValueListenableBuilder<String?>(
      valueListenable: UserImageService().profileImageUrl,
      builder: (context, imageUrl, child) {
        if (imageUrl != null) {
          return ClipOval(child: SizedBox(width: 48, height: 48, child: Image.network(imageUrl)));
        }

        return FutureBuilder<Image>(
          future: loadProfileImageFromHive(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: 48,
                height: 48,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            } else if (snapshot.hasData) {
              return ClipOval(child: SizedBox(width: 48, height: 48, child: snapshot.data!));
            } else {
              return ClipOval(child: SizedBox(width: 48, height: 48, child: fallbackUserAvatar));
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = dotenv.env['FLUTTER_ENV'];
    final List<Widget> screens = [
      // This is an array of Screens
      Dashboard(onNavigate: navigateToIndex),
      SearchScreen(),
      FolderScreen(),
      const Center(child: Text('Visualizations')),
      const Center(child: Text('Reports')),
      SettingsScreen(),
    ];
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(13.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: getIconForTheme(
                              lightIcon: AppIcons.plusLight,
                              darkIcon: AppIcons.plusLight,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      MouseRegion(cursor: SystemMouseCursors.click, child: buildProfileImage()),
                    ],
                  ),
                ),
              ),
            ),
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            destinations: [
              NavigationRailDestination(
                icon: getIconForTheme(
                  lightIcon: AppIcons.homeOutlinedLight,
                  darkIcon: AppIcons.homeOutlinedDark,
                  size: 18,
                ),
                padding: EdgeInsets.only(top: 10),
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.homeLight,
                  darkIcon: AppIcons.homeDark,
                  size: 18,
                ),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: getIconForTheme(
                  lightIcon: AppIcons.searchOutlinedLight,
                  darkIcon: AppIcons.searchOutlinedDark,
                  size: 18,
                ),
                padding: EdgeInsets.symmetric(vertical: 4),
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.searchLight,
                  darkIcon: AppIcons.searchDark,
                  size: 18,
                ),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: getIconForTheme(
                  lightIcon: AppIcons.folderOutlinedLight,
                  darkIcon: AppIcons.folderOutlinedDark,
                  size: 18,
                ),
                padding: EdgeInsets.symmetric(vertical: 4),
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.folderLight,
                  darkIcon: AppIcons.folderDark,
                  size: 18,
                ),
                label: Text('Folders'),
              ),
              NavigationRailDestination(
                icon: getIconForTheme(
                  lightIcon: AppIcons.chartOutlinedLight,
                  darkIcon: AppIcons.chartOutlinedDark,
                  size: 18,
                ),
                padding: EdgeInsets.symmetric(vertical: 4),
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.chartLight,
                  darkIcon: AppIcons.chartDark,
                  size: 18,
                ),
                label: Text('Visualizations'),
              ),
              NavigationRailDestination(
                icon: getIconForTheme(
                  lightIcon: AppIcons.reportOutlinedLight,
                  darkIcon: AppIcons.reportOutlinedDark,
                  size: 18,
                ),
                padding: EdgeInsets.symmetric(vertical: 4),
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.reportLight,
                  darkIcon: AppIcons.reportDark,
                  size: 18,
                ),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: getIconForTheme(
                  lightIcon: AppIcons.settingsOutlinedLight,
                  darkIcon: AppIcons.settingsOutlinedDark,
                  size: 18,
                ),
                padding: EdgeInsets.symmetric(vertical: 4),
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.settingsLight,
                  darkIcon: AppIcons.settingsDark,
                  size: 18,
                ),
                label: Text('Settings'),
              ),
            ],
            selectedIndex: selectedIndex,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: screens[selectedIndex]),
        ],
      ),
      floatingActionButton: env == 'development' ? DevFAB(parentContext: context) : null,
    );
  }
}

// the actual screen starts from here for the dashboard

class Dashboard extends StatefulWidget {
  final Function(int) onNavigate;

  const Dashboard({super.key, required this.onNavigate});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late var isDatasetUploaded = false;
  late var datasetPath = '';
  late String userName = '';

  Future<void> retrieveDisplayName() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      userName = user!.userMetadata?['display_name'] ?? 'User';
    });
  }

  @override
  void initState() {
    super.initState();
    retrieveDisplayName();
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            dialogTitle: "Import a dataset",
                            lockParentWindow: true,
                            type: FileType.custom,
                            allowedExtensions: ["json", "xlsx", "csv"],
                          );
                          if (result != null) {
                            File file = File(result.files.single.path!);
                            setState(() {
                              isDatasetUploaded = true;
                              datasetPath = file.path;
                            });
                            debugPrint(file.path);
                          } else {
                            debugPrint('file operation cancelled');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          "Upload Dataset",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          widget.onNavigate(1);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue.shade600, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          "Search Public Datasets",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // current uploaded dataset
                  if (isDatasetUploaded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Dataset successfully uploaded',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                              ),
                            ),
                            const SizedBox(width: 25),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  // reset states
                                  setState(() {
                                    isDatasetUploaded = false;
                                  });
                                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                                    dialogTitle: "Import a dataset",
                                    lockParentWindow: true,
                                    type: FileType.custom,
                                    allowedExtensions: ["json", "xlsx", "csv"],
                                  );
                                  if (result != null) {
                                    File file = File(result.files.single.path!);
                                    setState(() {
                                      isDatasetUploaded = true;
                                      datasetPath = file.path;
                                    });
                                    debugPrint(file.path);
                                  } else {
                                    debugPrint('file operation cancelled');
                                  }
                                },
                                child: Text(
                                  'Change dataset',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        DatasetCard(
                          lightIconPath: AppIcons.checkLight,
                          labelText: 'Current Dataset',
                          subLabelText: datasetPath,
                          buttonText: 'Analyze',
                          darkIconPath: AppIcons.checkDark,
                          onSearch: () {},
                        ),
                      ],
                    ),

                  const SizedBox(height: 16.0),
                  const Text('Recent Datasets', style: TextStyle(fontSize: 20.0)),
                  const SizedBox(height: 20),
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
                      thumbVisibility: false,
                      controller: scrollController,
                      thickness: 4,
                      radius: const Radius.circular(20),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 30.0),
                          child: Row(
                            children: [
                              DatasetCard(
                                lightIconPath: AppIcons.chartLight,
                                darkIconPath: AppIcons.chartDark,
                                labelText:
                                    'Sales '
                                    'Analysis 2003',
                                subLabelText: 'Last opened 2 hours ago',
                                buttonText: 'Open',
                                onSearch: () {},
                              ),
                              const SizedBox(width: 15.0),
                              DatasetCard(
                                lightIconPath: AppIcons.chartLight,
                                darkIconPath: AppIcons.chartDark,
                                labelText: 'Customer Behaviour',
                                subLabelText: 'Last opened yesterday',
                                buttonText: 'Open',
                                onSearch: () {},
                              ),
                              const SizedBox(width: 15.0),
                              DatasetCard(
                                lightIconPath: AppIcons.chartLight,
                                darkIconPath: AppIcons.chartDark,
                                labelText: 'Market Research',
                                subLabelText: 'Last opened 3 days ago',
                                buttonText: 'Open',
                                onSearch: () {},
                              ),
                              const SizedBox(width: 15.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('AI Insights', style: TextStyle(fontSize: 20.0)),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(right: 30.0, bottom: 40.0),
                    child: Row(
                      children: [
                        DatasetCard(
                          lightIconPath: AppIcons.chartLight,
                          darkIconPath: AppIcons.chartDark,
                          labelText: 'Dataset Analysis Summary',
                          subLabelText:
                              'Your recent datasets show a 23% increase in customer engagement patterns',
                          subLabelSize: 17.0,
                          buttonText: 'Open',
                          onSearch: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
