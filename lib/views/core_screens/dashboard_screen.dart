import 'dart:io';

import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/user_image_service.dart';
import 'package:deep_sage/views/core_screens/folder_screens/folder_screen.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_screen.dart';
import 'package:deep_sage/views/core_screens/settings_screen.dart';
import 'package:deep_sage/views/core_screens/visualization/visualization_and_explorer_screens.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/helpers/file_transfer_util.dart';

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
  final Image fallbackUserAvatar = Image.asset(
    'assets/fallback/fallback_user_image.png',
  );

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
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else if (snapshot.hasData) {
              return ClipOval(
                child: SizedBox(width: 48, height: 48, child: snapshot.data!),
              );
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
    return ClipOval(
      child: SizedBox(width: 48, height: 48, child: fallbackUserAvatar),
    );
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: buildProfileImage(),
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

/// Represents the main dashboard screen within the application.
///
/// This widget provides an overview of recent datasets, allows users to upload
/// new datasets, and navigate to different sections of the application.
///
/// It includes functionality for displaying a user-specific welcome message,
/// providing access to dataset upload, and showing a list of recently accessed
/// datasets.
class Dashboard extends StatefulWidget {
  final Function(int) onNavigate;

  const Dashboard({super.key, required this.onNavigate});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  /// Flag indicating whether a dataset has been uploaded.
  late var isDatasetUploaded = false;

  /// Path to the uploaded dataset.
  late var datasetPath = '';

  /// The display name of the user.
  late String userName = '';

  /// The selected root directory path for storing datasets.
  late String selectedRootDirectoryPath = '';

  /// Retrieves the user's display name from Supabase.
  ///
  /// This method fetches the current user from Supabase authentication and
  /// extracts the display name from the user's metadata. If a display name
  /// is found, it updates the [userName] state variable; otherwise, it sets
  /// [userName] to 'User' as a default.
  /// This function is typically called during the widget's initialization.
  Future<void> retrieveDisplayName() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      userName = user!.userMetadata?['display_name'] ?? 'User';
    });
  }

  /// Retrieves the selected root directory path from Hive.
  ///
  /// This method attempts to retrieve the 'selectedRootDirectoryPath' from
  /// the Hive box specified by the 'API_HIVE_BOX_NAME' environment variable.
  /// If a path is found, it updates the [selectedRootDirectoryPath] state
  /// variable with the retrieved path. This allows the application to remember
  /// the user's preferred location for storing datasets across sessions.
  /// This function is typically called during the widget's initialization to
  /// restore the last selected root directory path.
  Future<void> retrieveRootPath() async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final savedPath = hiveBox.get('selectedRootDirectoryPath');
    if (savedPath != null) {
      setState(() {
        selectedRootDirectoryPath = savedPath;
      });
    }
  }

  /// Initializes the widget's state and performs setup tasks.
  ///
  /// This method is called when the widget is first inserted into the widget tree.
  /// It calls the parent class's `initState` method and then proceeds to retrieve
  /// the user's display name and the previously selected root directory path,
  /// ensuring they are available when the dashboard is first rendered.
  @override
  void initState() {
    super.initState();
    retrieveDisplayName();
    retrieveRootPath();
  }

  /// Builds the main dashboard interface of the application.
  ///
  /// This method constructs a complex layout consisting of several key sections:
  ///
  /// 1. **Welcome Section**
  ///    - Displays a personalized greeting with the user's name
  ///
  /// 2. **Action Buttons**
  ///    - "Upload Dataset": Allows users to select and upload multiple dataset files
  ///      (supports JSON, CSV, XLSX, XLS formats)
  ///    - "Search Public Datasets": Navigates to the search interface
  ///
  /// 3. **Current Dataset Section** (conditionally rendered)
  ///    - Shows when a dataset is uploaded
  ///    - Displays upload confirmation and dataset details
  ///    - Provides option to change the current dataset
  ///
  /// 4. **Recent Datasets Section**
  ///    - Horizontally scrollable list of recently accessed datasets
  ///    - Each dataset displayed as a card with metadata
  ///    - Supports mouse wheel scrolling with smooth animation
  ///
  /// 5. **AI Insights Section**
  ///    - Shows AI-generated analysis of dataset patterns
  ///    - Presented in a card format with summary information
  ///
  /// The layout uses various Flutter widgets for optimal presentation:
  /// - [SingleChildScrollView] for vertical scrolling
  /// - [Scrollbar] and [Listener] for horizontal scrolling in recent datasets
  /// - [DatasetCard] for consistent dataset presentation
  /// - Custom styling for buttons and text elements
  ///
  /// The method manages file operations through [FilePicker] and handles
  /// dataset uploads using [FileTransferUtil], with appropriate error handling
  /// and user feedback through [SnackBar] messages.

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
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                dialogTitle: 'Select dataset(s)',
                                allowMultiple: true,
                                type: FileType.custom,
                                allowedExtensions: [
                                  "json",
                                  "csv",
                                  "xlsx",
                                  "xls",
                                ],
                                lockParentWindow: true,
                              );
                          if (result != null && result.files.isNotEmpty) {
                            List<String> filePaths =
                                result.files
                                    .where((file) => file.path != null)
                                    .map((file) => file.path!)
                                    .toList();

                            if (filePaths.isNotEmpty) {
                              for (String path in filePaths) {
                                debugPrint('Selected file: $path');
                              }

                              try {
                                List<String> newPaths =
                                    await FileTransferUtil.moveFiles(
                                      sourcePaths: filePaths,
                                      destinationDirectory:
                                          selectedRootDirectoryPath,
                                      overwriteExisting: false,
                                    );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Dataset uploaded successfully',
                                    ),
                                  ),
                                );
                                // todo: add a acknowledgement toast
                                debugPrint(
                                  'Files moved successfully to: $newPaths',
                                );
                              } catch (ex) {
                                debugPrint('Cannot move files: $ex');
                              }
                            }
                          }
                        },
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
                        onPressed: () {
                          widget.onNavigate(1);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.blue.shade600,
                            width: 2,
                          ),
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
                                  FilePickerResult? result = await FilePicker
                                      .platform
                                      .pickFiles(
                                        dialogTitle: "Import a dataset",
                                        lockParentWindow: true,
                                        type: FileType.custom,
                                        allowedExtensions: [
                                          "json",
                                          "xlsx",
                                          "csv",
                                        ],
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
                          onButtonClick: () {},
                        ),
                      ],
                    ),

                  const SizedBox(height: 16.0),
                  const Text(
                    'Recent Datasets',
                    style: TextStyle(fontSize: 20.0),
                  ),
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
                                onButtonClick: () {},
                              ),
                              const SizedBox(width: 15.0),
                              DatasetCard(
                                lightIconPath: AppIcons.chartLight,
                                darkIconPath: AppIcons.chartDark,
                                labelText: 'Customer Behaviour',
                                subLabelText: 'Last opened yesterday',
                                buttonText: 'Open',
                                onButtonClick: () {},
                              ),
                              const SizedBox(width: 15.0),
                              DatasetCard(
                                lightIconPath: AppIcons.chartLight,
                                darkIconPath: AppIcons.chartDark,
                                labelText: 'Market Research',
                                subLabelText: 'Last opened 3 days ago',
                                buttonText: 'Open',
                                onButtonClick: () {},
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
                          onButtonClick: () {},
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
