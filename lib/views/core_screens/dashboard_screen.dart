import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Dashboard Screen')),
    const Center(child: Text('Search')),
    const Center(child: Text('Stats')),
    const Center(child: Text('Settings')),
  ];

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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () {
                      // Add logout logic here
                    },
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
                selectedIcon: getIconForTheme(
                  lightIcon: AppIcons.homeLight,
                  darkIcon: AppIcons.homeDark,
                  size: 18,
                ),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified_user_outlined),
                label: Text('Profile'),
                selectedIcon: Icon(Icons.verified_user),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_graph_outlined),
                label: Text('Stats'),
                selectedIcon: Icon(Icons.auto_graph),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('Settings'),
                selectedIcon: Icon(Icons.settings),
              ),
            ],
            selectedIndex: selectedIndex,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[selectedIndex]),
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
