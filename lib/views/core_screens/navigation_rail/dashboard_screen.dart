import 'dart:async';

import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/keyboard/shortcut_service.dart';
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

import 'dashboard.dart';

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

  /// Displays a dialog that shows a gallery of available project templates.
  ///
  /// This method presents a general dialog to the user, offering a curated
  /// selection of project templates. These templates serve as starting points
  /// for new projects, categorized by their purpose and functionality.
  ///
  /// The dialog is styled with rounded corners and utilizes animations for a
  /// smooth appearance. It contains a title, a descriptive text, and a tabbed
  /// view to browse through the template categories.
  ///
  /// Parameters:
  ///   - [context]: The build context, used to access theme and navigation services.
  ///
  void _showTemplatesGallery(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Templates Gallery",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutQuint);

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              backgroundColor: isDarkMode ? Color(0xFF2A2D37) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 900, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Templates Gallery",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: "Close",
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Start a new project with one of our pre-built templates",
                        style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                      ),
                      SizedBox(height: 24),
                      Expanded(child: _buildTemplateCategories(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a tabbed view of template categories for display in the templates gallery.
  ///
  /// This method constructs a widget that organizes project templates into
  /// categories like Analytics, Machine Learning, Dashboards, and Reports.
  /// It uses a [DefaultTabController] to manage the tabbed interface and
  /// a [TabBar] for navigation between categories. The selected tab's label
  /// color is themed based on the application's color scheme, while the
  /// unselected labels are styled in gray.
  ///
  /// Within each tab, a grid of templates is displayed using [_buildTemplateGrid].
  ///
  /// Parameters:
  ///   - [context]: The build context used for theming and widget building.
  Widget _buildTemplateCategories(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: "Analytics"),
              Tab(text: "Machine Learning"),
              Tab(text: "Dashboards"),
              Tab(text: "Reports"),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              children: [
                _buildTemplateGrid(context, _getAnalyticsTemplates()),
                _buildTemplateGrid(context, _getMachineLearningTemplates()),
                _buildTemplateGrid(context, _getDashboardTemplates()),
                _buildTemplateGrid(context, _getReportTemplates()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a grid of project templates for a given category.
  ///
  /// This method creates a [GridView] to display project templates in a
  /// visually appealing grid layout. The grid is designed with a fixed number
  /// of columns and consistent spacing between items. Each template item is
  /// built using the [_buildTemplateCard] method.
  ///
  /// Parameters:
  ///   - [context]: The build context, used for theming and widget building.
  ///   - [templates]: A list of [TemplateItem] representing the templates to display.
  ///
  Widget _buildTemplateGrid(BuildContext context, List<TemplateItem> templates) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template);
      },
    );
  }

  /// Builds a card for a single project template.
  ///
  /// This method constructs a visually rich card to represent a project
  /// template. It includes the template's name, description, and an icon.
  /// The card changes appearance on hover, providing feedback to the user.
  ///
  /// The card is an interactive element that, when tapped, informs the user
  /// of their selection via a [SnackBar] and subsequently closes the dialog.
  ///
  /// The visual components of the card include:
  /// - A title that becomes highlighted on hover.
  /// - A brief description to convey the template's utility.
  /// - An icon and color associated with the template's theme.
  ///
  /// Parameters:
  ///   - [template]: The data model for the project template.
  Widget _buildTemplateCard(BuildContext context, TemplateItem template) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Selected template: ${template.name}")));
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: template.color.withValues(alpha: 0.1),
            highlightColor: template.color.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? (isHovered ? Color(0xFF3F4456) : Color(0xFF353A48))
                        : (isHovered ? Colors.grey[50] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isHovered
                          ? template.color.withValues(alpha: 0.5)
                          : isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                  width: isHovered ? 1.5 : 1,
                ),
                boxShadow:
                    isHovered
                        ? [
                          BoxShadow(
                            color: template.color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              transform:
                  isHovered
                      ? (Matrix4.identity()
                        ..translate(0.0, -4.0, 0.0)
                        ..scale(1.03))
                      : Matrix4.identity(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: template.color.withValues(alpha: isHovered ? 0.3 : 0.2),
                      child: Center(
                        child: AnimatedScale(
                          scale: isHovered ? 1.1 : 1.0,
                          duration: Duration(milliseconds: 200),
                          child: Icon(template.icon, size: 48, color: template.color),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isHovered ? template.color : null,
                          ),
                          child: Text(template.name),
                        ),
                        SizedBox(height: 4),
                        Text(
                          template.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns a list of template items for the "Analytics" category.
  ///
  /// This method defines a set of predefined templates specifically tailored
  /// for data analytics. Each template item includes a name, a brief description,
  /// an icon, and a color for visual differentiation.
  // Template categories
  List<TemplateItem> _getAnalyticsTemplates() {
    return [
      TemplateItem(
        name: "Data Exploration",
        description: "Start with basic data analysis and visualization",
        icon: Icons.bar_chart,
        color: Colors.blue,
      ),
      TemplateItem(
        name: "Time Series Analysis",
        description: "Analyze time-based data patterns and trends",
        icon: Icons.timeline,
        color: Colors.green,
      ),
      TemplateItem(
        name: "Statistical Analysis",
        description: "Perform statistical testing and hypothesis validation",
        icon: Icons.functions,
        color: Colors.purple,
      ),
      TemplateItem(
        name: "Data Cleaning",
        description: "Clean and preprocess data for further analysis",
        icon: Icons.cleaning_services,
        color: Colors.orange,
      ),
      TemplateItem(
        name: "Correlation Analysis",
        description: "Find relationships between different variables",
        icon: Icons.hub,
        color: Colors.red,
      ),
    ];
  }

  /// Returns a list of template items for the "Machine Learning" category.
  ///
  /// This method provides a collection of templates for various machine learning
  /// tasks, each item defined with its name, description, an associated icon,
  /// and a color.
  List<TemplateItem> _getMachineLearningTemplates() {
    return [
      TemplateItem(
        name: "Regression Model",
        description: "Predict numeric values with regression techniques",
        icon: Icons.show_chart,
        color: Colors.indigo,
      ),
      TemplateItem(
        name: "Classification",
        description: "Categorize data into predefined classes",
        icon: Icons.category,
        color: Colors.teal,
      ),
      TemplateItem(
        name: "Clustering",
        description: "Group similar data points into clusters",
        icon: Icons.bubble_chart,
        color: Colors.deepOrange,
      ),
    ];
  }

  /// Returns a list of template items for the "Dashboards" category.
  ///
  /// This method outlines a series of pre-designed dashboard templates, each
  /// specified with a name, descriptive text, an icon for quick recognition,
  /// and a color to fit its theme.
  List<TemplateItem> _getDashboardTemplates() {
    return [
      TemplateItem(
        name: "Executive Dashboard",
        description: "High-level metrics for decision makers",
        icon: Icons.dashboard,
        color: Colors.blue,
      ),
      TemplateItem(
        name: "Sales Analytics",
        description: "Track sales performance and customer metrics",
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      TemplateItem(
        name: "Marketing Performance",
        description: "Monitor marketing campaigns and ROI",
        icon: Icons.campaign,
        color: Colors.amber,
      ),
    ];
  }

  /// Returns a list of template items for the "Reports" category.
  ///
  /// This method specifies report templates, complete with a name, a succinct
  /// description, a related icon, and a color, making it easy to choose a
  /// relevant template.
  List<TemplateItem> _getReportTemplates() {
    return [
      TemplateItem(
        name: "Monthly Report",
        description: "Comprehensive monthly performance analysis",
        icon: Icons.description,
        color: Colors.purple,
      ),
      TemplateItem(
        name: "Comparative Analysis",
        description: "Compare data across different time periods",
        icon: Icons.compare_arrows,
        color: Colors.cyan,
      ),
      TemplateItem(
        name: "Executive Summary",
        description: "Concise overview for stakeholders",
        icon: Icons.summarize,
        color: Colors.brown,
      ),
    ];
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
    return ShortcutService(
      tabCount: screens.length,
      onTabChange: navigateToIndex,
      currentIndex: selectedIndex,
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF2A2D37)
                      : Colors.grey[100],
              selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
              unselectedIconTheme: IconThemeData(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[700],
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[700],
              ),
              useIndicator: true,
              indicatorColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              elevation: 1,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _showTemplatesGallery(context),
                          child: MouseRegion(
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
      ),
    );
  }
}

/// A data class to represent a project template with its name,
/// description, icon, and color.
///
/// Each template is displayed in the templates gallery and provides a
/// starting point for new projects.
///
/// - [name]: The name of the template.
/// - [description]: A brief description of the template.
/// - [icon]: The icon associated with the template.
/// - [color]: The color theme of the template.
class TemplateItem {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  TemplateItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
