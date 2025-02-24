import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var selectedIndex = 0;

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
      const Center(child: Text('Dashboard')),
      const Center(child: Text('Search')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        child: const Icon(Icons.brightness_6),
      ),
    );
  }
}
