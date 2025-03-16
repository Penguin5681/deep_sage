import 'dart:async';

import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/user_image_service.dart';
import 'package:deep_sage/views/core_screens/folder_screens/folder_screen.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_screen.dart';
import 'package:deep_sage/views/core_screens/settings_screen.dart';
import 'package:deep_sage/views/core_screens/visualization/visualization_and_explorer_screens.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../folder_screens/dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The index of the currently selected navigation item.
  var selectedIndex = 0;

  /// The currently displayed screen widget based on navigation selection.
  late Widget currentScreen;

  /// Reference to the Hive box storing user-related data.
  /// This box is configured with the name from the environment variables.
  final userHiveBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);

  /// Fallback user avatar image to display when no profile image is available.
  /// This asset is used as the default profile picture.
  final Image fallbackUserAvatar = Image.asset('assets/fallback/fallback_user_image.png');

  /// Checks if the current user signed in with Google authentication.
  ///
  /// This method evaluates the authentication provider from the user's metadata
  /// and updates the state variables related to Google authentication.
  /// If Google authentication is detected, it also fetches the avatar URL.
  void checkIfGoogleSignIn() {
    final user = Supabase.instance.client.auth.currentUser;
    final provider = user?.appMetadata['provider'];
    final avatarUrl = user?.userMetadata?['avatar_url'];

    setState(() {
      isGoogleSignIn = provider == 'google';
      if (isGoogleSignIn && avatarUrl != null) {
        userAvatarUrl = avatarUrl;
      }
    });
  }

  /// Retrieves and processes user metadata from Supabase.
  ///
  /// This method specifically focuses on extracting the avatar URL
  /// for Google Sign-In users and updates the state accordingly.
  void getUserMetadata() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        // For Google Sign In, get the avatar URL directly from metadata
        if (user.appMetadata['provider'] == 'google') {
          userAvatarUrl = user.userMetadata?['avatar_url'] ?? '';
        }
      });
    }
  }

  @override
  /// Initializes the widget state.
  ///
  /// This method is called when this object is inserted into the tree.
  /// It sets up the initial screen, retrieves user metadata, and checks
  /// if the user signed in with Google authentication.
  void initState() {
    super.initState();
    currentScreen = Dashboard(onNavigate: navigateToIndex);
    getUserMetadata();
    checkIfGoogleSignIn();
  }

  /// Navigates to a specified index in the navigation rail.
  ///
  /// This method updates the [selectedIndex] state variable to reflect the
  /// user's navigation choice. It triggers a rebuild of the widget to display
  /// the corresponding screen from the navigation rail's list of destinations.
  ///
  /// Parameters:
  ///   - index: The index of the navigation item selected by the user. This
  ///            determines which screen will be displayed next.
  ///
  void navigateToIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final navigatorKey = GlobalKey<NavigatorState>();

  /// Returns an icon widget that dynamically adapts to the current theme.
  ///
  /// This method creates an [Image.asset] widget, choosing between a light
  /// or dark icon variant based on the current brightness setting of the
  /// application's theme. This is useful for UI elements that need to match
  /// the theme (light or dark) of the application.
  ///
  /// Parameters:
  ///   - lightIcon: The asset path for the icon to be displayed in light mode.
  ///   - darkIcon: The asset path for the icon to be displayed in dark mode.
  ///   - size: The size (both width and height) of the icon. Defaults to 24.
  ///
  /// Returns: A widget that displays the appropriate icon for the current theme.

  Widget getIconForTheme({required String lightIcon, required String darkIcon, double size = 24}) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(isDarkMode ? darkIcon : lightIcon, width: size, height: size);
      },
    );
  }

  /// Asynchronously loads the user's profile image from the Hive storage.
  ///
  /// This method first checks if a cached image URL is available from the
  /// [UserImageService]. If so, it returns the cached image directly. Otherwise,
  /// it attempts to retrieve the image URL from the user's Hive box. If the
  /// image URL is found in Hive, it updates the [UserImageService] with the new
  /// URL and returns an [Image.network] widget. If no image URL is available, it
  /// returns a fallback image asset.
  ///
  /// This approach prioritizes:
  /// 1. Cached image from [UserImageService].
  /// 2. Image URL from Hive storage.
  /// 3. Fallback image asset.
  ///
  /// Returns: A [Future] that resolves to an [Image] widget.
  Future<Image> loadProfileImageFromHive() async {
    if (UserImageService().cachedUrl != null) {
      return Image.network(UserImageService().cachedUrl!);
    }

    final imageUrl = await userHiveBox.get('userAvatarUrl');
    if (imageUrl != null) {
      UserImageService().updateProfileImageUrl(imageUrl);
      return Image.network(imageUrl);
    }
    return fallbackUserAvatar;
  }

  /// Variable to check google sign in
  late String userAvatarUrl = '';
  bool isGoogleSignIn = false;

  /// Builds and returns the widget for displaying the user's profile image.
  ///
  /// This method implements a priority system to display the user's profile
  /// image, checking different sources in a specific order:
  ///
  /// 1. **Google Sign-In Avatar URL:** If the user signed in with Google and
  ///    a corresponding avatar URL is available, this image is used.
  /// 2. **Cached URL from UserImageService:** If no Google avatar is available
  ///    or if Google authentication was not used, it checks for a cached image
  ///    URL provided by the [UserImageService].
  /// 3. **Hive Storage:** As a last resort, it attempts to load the image from
  ///    the local Hive storage. If successful, the image URL is also updated
  ///    in the [UserImageService] for future use.
  ///
  /// If none of the above sources provides an image, a fallback image is displayed.
  ///
  /// The method uses [ValueListenableBuilder] to listen to changes in the
  /// [UserImageService]'s [profileImageUrl], allowing for reactive updates
  /// when the image URL changes.
  ///
  /// Returns:
  ///   - A [ValueListenableBuilder] that returns a [ClipOval] widget containing
  ///     the user's profile image or a loading indicator/fallback image if the
  ///     profile image cannot be loaded.
  ///
  /// See also: [loadProfileImageFromHive], [_buildFallbackImage]
  Widget buildProfileImage() {
    return ValueListenableBuilder<String?>(
      valueListenable: UserImageService().profileImageUrl,
      builder: (context, imageUrl, child) {
        // First priority: Google Sign-In with avatar URL
        if (isGoogleSignIn && userAvatarUrl.isNotEmpty) {
          return ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                userAvatarUrl,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to cached or default image if Google image fails to load
                  return _buildFallbackImage();
                },
              ),
            ),
          );
        }

        // Second priority: Cached URL from UserImageService
        if (UserImageService().cachedUrl != null) {
          return ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                UserImageService().cachedUrl!,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage();
                },
              ),
            ),
          );
        }

        // Third priority: Try to load from Hive storage
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
              return _buildFallbackImage();
            }
          },
        );
      },
    );
  }

  /// Builds and returns a fallback profile image widget.
  ///
  /// This method creates a circular profile image widget using the [fallbackUserAvatar]
  /// asset when the primary profile image sources (Google avatar, cached URL, or Hive storage)
  /// are unavailable or fail to load.
  ///
  /// The widget is constructed with the following components:
  /// - [ClipOval]: Creates a circular clipping for the image
  /// - [SizedBox]: Constrains the image dimensions to 48x48 pixels
  /// - [fallbackUserAvatar]: The default profile image asset
  ///
  /// Returns:
  ///   A [Widget] displaying the fallback profile image in a circular shape with
  ///   fixed dimensions of 48x48 pixels.
  ///
  /// See also:
  ///  * [buildProfileImage], which uses this method as a fallback
  ///  * [fallbackUserAvatar], the default image asset used
  Widget _buildFallbackImage() {
    return ClipOval(child: SizedBox(width: 48, height: 48, child: fallbackUserAvatar));
  }

  /// Builds the main application interface with a navigation rail and content area.
  ///
  /// This method constructs the primary UI structure of the application, consisting of:
  ///
  /// * A [NavigationRail] on the left side containing:
  ///   - Navigation destinations for different sections (Dashboard, Search, etc.)
  ///   - A "+" button at the bottom for quick actions
  ///   - A profile image display
  ///
  /// * A content area that displays different screens based on navigation selection
  ///
  /// The layout uses a [Row] to arrange the navigation rail and content horizontally,
  /// with a [VerticalDivider] separating them.
  ///
  /// Navigation destinations include:
  /// - Dashboard: Home screen with overview and recent items
  /// - Search: For finding datasets and content
  /// - Folders: File system navigation
  /// - Visualizations: Data visualization tools
  /// - Reports: Reporting interface
  /// - Settings: Application configuration
  ///
  /// In development mode (when env == 'development'), a floating action button
  /// is added using [DevFAB] for debug purposes.
  ///
  /// Returns:
  ///   A [Scaffold] widget containing the complete application layout.
  @override
  Widget build(BuildContext context) {
    final env = dotenv.env['FLUTTER_ENV'];
    final List<Widget> screens = [
      // This is an array of Screens
      Dashboard(onNavigate: navigateToIndex),
      SearchScreen(),
      FolderScreen(onNavigate: navigateToIndex),
      VisualizationAndExplorerScreens(),
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
