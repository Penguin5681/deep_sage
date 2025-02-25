import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/views/core_screens/search_screen.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var selectedIndex = 0;
  final navigatorKey = GlobalKey<NavigatorState>();

  Widget getIconForTheme({
    required String lightIcon,
    required String darkIcon,
    double size = 24,
  }) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(
          isDarkMode ? darkIcon : lightIcon,
          width: size,
          height: size,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = dotenv.env['FLUTTER_ENV'];
    final List<Widget> screens = [
      // This is an array of Screens
      Dashboard(),
      SearchScreen(),
      const Center(child: Text('Folders')),
      const Center(child: Text('Visualizations')),
      const Center(child: Text('Reports')),
      const Center(child: Text('Settings')),
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ClipOval(
                          child: Image.asset(
                            AppIcons.larry,
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
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
      floatingActionButton:
          env == 'development' ? DevFAB(parentContext: context) : null,
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back, Larry',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Upload Dataset",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade600, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Search Public Datasets",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Recent Datasets', style: TextStyle(fontSize: 20.0)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText:
                          'Sales '
                          'Analysis 2003',
                      subLabelText: 'Last opened 2 hours ago',
                      buttonText: 'Open',
                    ),
                    const SizedBox(width: 15.0),
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Customer Behaviour',
                      subLabelText: 'Last opened yesterday',
                      buttonText: 'Open',
                    ),
                    const SizedBox(width: 15.0),
                    DatasetCard(
                      lightIconPath: AppIcons.chartLight,
                      darkIconPath: AppIcons.chartDark,
                      labelText: 'Market Research',
                      subLabelText: 'Last opened 3 days ago',
                      buttonText: 'Open',
                    ),
                    const SizedBox(width: 15.0),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('AI Insights', style: TextStyle(fontSize: 20.0)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0, bottom: 40.0),
                  child: Row(
                    children: [
                      DatasetCard(
                        expanded: false,
                        lightIconPath: AppIcons.chartLight,
                        darkIconPath: AppIcons.chartDark,
                        labelText: 'Dataset Analysis Summary',
                        subLabelText:
                            'Your recent datasets show a 23% increase in customer engagement patterns. Consider exploring correlation with your new marketing campaign.',
                        subLabelSize: 17.0,
                        buttonText: 'Open',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
