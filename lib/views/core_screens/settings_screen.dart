import 'dart:io';

import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/services/directory_path_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_api_model.dart';
import '../../providers/theme_provider.dart';

import 'package:path/path.dart' as path;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkModeEnabled = false;
  bool googleDriveEnabled = false;
  bool dropboxEnabled = false;
  bool shouldWeAskForDownloadLocation = false;
  bool awsS3Enabled = false;
  String defaultDownloadPath = '';
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
  final kaggleUsernameNotFoundTag = 'kaggle username not found';
  final kaggleApiKeyNotFoundTag = 'kaggle key not found';

  late FocusNode kaggleUsernameInputFocus = FocusNode();
  late FocusNode kaggleApiInputFocus = FocusNode();
  late FocusNode hfTokenInputFocus = FocusNode();
  late bool isKaggleApiCredsSaved = false;
  late bool isRootDirectorySelected = false;
  late String selectedRootDirectoryPath = '';
  late Map<String, dynamic> credsSavedOrNotLetsFindOutResult = {};

  final TextEditingController kaggleUsernameController = TextEditingController();
  final TextEditingController kaggleApiInputController = TextEditingController();
  final hiveApiBoxName = dotenv.env['API_HIVE_BOX_NAME'];

  Future<void> getDownloadsDirectory() async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    String? savedPath = hiveBox.get('downloadPath');

    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        defaultDownloadPath = savedPath;
      });
      return;
    }

    String? downloadsPath;

    if (Platform.isWindows) {
      downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
    } else if (Platform.isMacOS || Platform.isLinux) {
      downloadsPath = '${Platform.environment['HOME']}/Downloads';
    } else {
      downloadsPath = '';
    }

    setState(() {
      defaultDownloadPath = downloadsPath!;
    });

    debugPrint(defaultDownloadPath);
  }

  UserApi? getUserApi() {
    if (hiveBox.isEmpty) return null;
    try {
      return hiveBox.getAt(0) as UserApi;
    } catch (e) {
      debugPrint('Error getting UserApi: $e');
      return null;
    }
  }

  String get kaggleUsername => getUserApi()?.kaggleUserName ?? '';

  String get kaggleKey => getUserApi()?.kaggleApiKey ?? '';

  Map<String, dynamic> isAnyUserApiDataSaved() {
    final userApi = getUserApi();
    if (userApi == null) {
      return {"result": false};
    }

    if (userApi.kaggleUserName.isEmpty) {
      return {"result": kaggleUsernameNotFoundTag};
    } else if (userApi.kaggleApiKey.isEmpty) {
      return {"result": kaggleApiKeyNotFoundTag};
    }

    return {"result": true};
  }

  Widget getIconForTheme({required String lightIcon, required String darkIcon, double size = 24}) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(isDarkMode ? darkIcon : lightIcon, width: size, height: size);
      },
    );
  }

  Future<void> _loadRootDirectoryPath() async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final savedPath = hiveBox.get('selectedRootDirectoryPath');

    if (savedPath != null && savedPath.toString().isNotEmpty) {
      setState(() {
        selectedRootDirectoryPath = savedPath;
        isRootDirectorySelected = true;
      });
    } else {
      try {
        final defaultPath = await _createDefaultRootIfRootNotSelected();
        setState(() {
          selectedRootDirectoryPath = defaultPath;
          isRootDirectorySelected = true;
        });
        await hiveBox.put('selectedRootDirectoryPath', defaultPath);
        DirectoryPathService().notifyPathChange(defaultPath);
      } catch (ex) {
        debugPrint('Error occurred while choosing the def directory: $ex');
      }
    }
  }

  // what are we tryna do here?
  // i'll also grab the root directory name and put it to hive as well
  // in case the user wants to select a directory as the root folder. then we'll replace the root name

  Future<String> _createDefaultRootIfRootNotSelected() async {
    String defaultPath;

    if (Platform.isWindows) {
      defaultPath = path.join(Platform.environment['USERPROFILE']!, 'deep_sage_root');
    } else if (Platform.isLinux || Platform.isMacOS) {
      defaultPath = path.join(Platform.environment['HOME']!, 'deep_sage_root');
    } else {
      throw UnsupportedError('Platform not supported?. Bruh how did we get here??');
    }
    
    try {
      final directory = Directory(defaultPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return defaultPath;
    } catch (ex) {
      debugPrint('Error creating directory: $ex');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    getDownloadsDirectory();
    _loadRootDirectoryPath();
    kaggleApiInputFocus = FocusNode();
    kaggleUsernameInputFocus = FocusNode();
    hfTokenInputFocus = FocusNode();
    credsSavedOrNotLetsFindOutResult = isAnyUserApiDataSaved();
  }

  @override
  void dispose() {
    kaggleApiInputFocus.dispose();
    kaggleUsernameInputFocus.dispose();
    hfTokenInputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkModeEnabled = Theme.of(context).brightness == Brightness.dark;

    final ScrollController rootScrollController = ScrollController();
    final focusNode = FocusNode();

    void handleKeyEvent(KeyEvent event) {
      var offset = rootScrollController.offset;
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (kReleaseMode) {
            rootScrollController.animateTo(
              offset - 200,
              duration: Duration(milliseconds: 30),
              curve: Curves.ease,
            );
          } else {
            rootScrollController.animateTo(
              offset - 200,
              duration: Duration(milliseconds: 30),
              curve: Curves.ease,
            );
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (kReleaseMode) {
            rootScrollController.animateTo(
              offset + 200,
              duration: Duration(milliseconds: 30),
              curve: Curves.ease,
            );
          } else {
            rootScrollController.animateTo(
              offset + 200,
              duration: Duration(milliseconds: 30),
              curve: Curves.ease,
            );
          }
        });
      }
    }

    return Theme(
      data: darkModeEnabled ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: isDarkModeEnabled ? Colors.grey[900] : Colors.white,
        body: Row(
          children: [
            // Right content area
            Expanded(
              child: KeyboardListener(
                onKeyEvent: handleKeyEvent,
                focusNode: focusNode,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  controller: rootScrollController,
                  child: Center(
                    child: Container(
                      width: 600,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top navigation
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'Dashboard',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkModeEnabled ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Profile card
                          Container(
                            padding: const EdgeInsets.all(16), // Reduced padding
                            decoration: BoxDecoration(
                              color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'User Profile',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDarkModeEnabled ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage your account information and preferences',
                                  style: TextStyle(
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Profile picture
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: const AssetImage('assets/larry/larry.png'),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile Picture',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Change your profile photo',
                                    style: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(
                                Icons.edit,
                                color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Full Name
                          Text(
                            'Full Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            width: double.infinity,
                            child: Text(
                              'John Smith',
                              style: TextStyle(
                                color: isDarkModeEnabled ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Email
                          Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'john.smith@example.com',
                                    style: TextStyle(
                                      color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.mail_outline,
                                color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Sign Out Button
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: () {
                                // todo: sign out from here can clear the hive data
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Reduced spacing
                          // Appearance
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          Row(
                            children: [
                              Icon(
                                Icons.dark_mode_outlined,
                                color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dark Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Toggle between light and dark theme',
                                    style: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Switch(
                                value: Theme.of(context).brightness == Brightness.dark,
                                onChanged: (value) {
                                  setState(() {
                                    isDarkModeEnabled = value;
                                    Provider.of<ThemeProvider>(
                                      context,
                                      listen: false,
                                    ).toggleTheme();
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Reduced spacing
                          // Integrations
                          Text(
                            'Integrations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Google Drive
                          _buildIntegrationItem(
                            icon: Icons.cloud_outlined,
                            title: 'Google Drive',
                            description: 'Connect your Google Drive account',
                            value: googleDriveEnabled,
                            onChanged: (value) {
                              setState(() {
                                googleDriveEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Dropbox
                          _buildIntegrationItem(
                            icon: Icons.folder_outlined,
                            title: 'Dropbox',
                            description: 'Connect your Dropbox account',
                            value: dropboxEnabled,
                            onChanged: (value) {
                              setState(() {
                                dropboxEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // AWS S3
                          _buildIntegrationItem(
                            icon: Icons.storage_outlined,
                            title: 'AWS S3',
                            description: 'Connect your AWS S3 bucket',
                            value: awsS3Enabled,
                            onChanged: (value) {
                              setState(() {
                                awsS3Enabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          buildApiManagementSection(),
                          const SizedBox(height: 24),
                          // Download settings
                          Text(
                            'Download Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Default download location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        defaultDownloadPath,
                                        style: TextStyle(
                                          color:
                                              isDarkModeEnabled
                                                  ? Colors.grey[400]
                                                  : Colors.grey[500],
                                        ),
                                      ),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () async {
                                            String? selectedDir = await FilePicker.platform
                                                .getDirectoryPath(
                                                  dialogTitle:
                                                      'Select the default download directory',
                                                );
                                            if (selectedDir != null) {
                                              setState(() {
                                                defaultDownloadPath = selectedDir;
                                              });

                                              final hiveBox = Hive.box(
                                                dotenv.env['API_HIVE_BOX_NAME']!,
                                              );
                                              hiveBox.put('downloadPath', selectedDir);
                                            }
                                          },
                                          child: Icon(
                                            Icons.folder_open_outlined,
                                            color: isDarkModeEnabled ? Colors.white : Colors.black,
                                            size: 18.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color:
                                          isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 17.0,
                                        vertical: 17.0,
                                      ),
                                      child: Image.asset(
                                        !isDarkModeEnabled
                                            ? AppIcons.downloadLight
                                            : AppIcons.downloadDark,
                                        width: 14.0,
                                        height: 14.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14.0),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ask for location everytime',
                                        style: TextStyle(
                                          color: isDarkModeEnabled ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Prompt for download location before saving files',
                                        style: TextStyle(
                                          color:
                                              isDarkModeEnabled
                                                  ? Colors.grey[600]
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: shouldWeAskForDownloadLocation,
                                onChanged: (value) {
                                  setState(() {
                                    shouldWeAskForDownloadLocation = value;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'File Storage Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Default dataset location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedRootDirectoryPath.isEmpty
                                            ? "No path selected"
                                            : selectedRootDirectoryPath,
                                        style: TextStyle(
                                          color:
                                              isDarkModeEnabled
                                                  ? Colors.grey[400]
                                                  : Colors.grey[500],
                                        ),
                                      ),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () async {
                                            String? selectedDir = await FilePicker.platform
                                                .getDirectoryPath(
                                                  dialogTitle: 'Select root directory for datasets',
                                                );
                                            if (selectedDir != null) {
                                              setState(() {
                                                selectedRootDirectoryPath = selectedDir;
                                              });

                                              final hiveBox = Hive.box(
                                                dotenv.env['API_HIVE_BOX_NAME']!,
                                              );
                                              hiveBox.put('selectedRootDirectoryPath', selectedDir);
                                              DirectoryPathService().notifyPathChange(selectedDir);
                                            }
                                          },
                                          child: Icon(
                                            Icons.folder_open_outlined,
                                            color: isDarkModeEnabled ? Colors.white : Colors.black,
                                            size: 18.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Data Management
                          Text(
                            'Data Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Clear Cache
                          Row(
                            children: [
                              Icon(
                                Icons.cleaning_services_outlined,
                                color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Clear Cache',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Remove temporary files and cached data',
                                    style: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    // do something here
                                  },
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Reduced spacing
                          // Storage Usage
                          Row(
                            children: [
                              Icon(
                                Icons.storage_rounded,
                                color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Storage Usage',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '2.4 GB of 5 GB used',
                                    style: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    'Select',
                                    style: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_sharp,
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Reduced bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationItem({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
      ],
    );
  }

  Widget buildApiManagementSection() {
    bool isDarkModeEnabled = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'API Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkModeEnabled ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.help),
              tooltip:
                  "Kaggle Username and Kaggle Api are\nrequired to conduct search using kaggle",
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (kaggleUsername.isEmpty)
          _buildSingleCredentialInput(
            title: 'Kaggle Username',
            hintText: 'Enter your Kaggle username',
            controller: kaggleUsernameController,
            focusNode: kaggleUsernameInputFocus,
            tooltip: "Required for search using Kaggle",
            obscureText: false,
          ),

        if (kaggleKey.isEmpty)
          _buildSingleCredentialInput(
            title: 'Kaggle API Key',
            hintText: 'Enter your Kaggle API key',
            controller: kaggleApiInputController,
            focusNode: kaggleApiInputFocus,
            tooltip: "Required for search using Kaggle",
            obscureText: true,
          ),

        if (kaggleUsername.isEmpty || kaggleKey.isEmpty)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                final hiveBox = Hive.box(hiveApiBoxName!);

                UserApi existingData =
                    getUserApi() ?? UserApi(kaggleUserName: "", kaggleApiKey: "");

                UserApi userApiData = UserApi(
                  kaggleApiKey:
                      kaggleApiInputController.text.isNotEmpty
                          ? kaggleApiInputController.text
                          : existingData.kaggleApiKey,
                  kaggleUserName:
                      kaggleUsernameController.text.isNotEmpty
                          ? kaggleUsernameController.text
                          : existingData.kaggleUserName,
                );

                if (hiveBox.isEmpty) {
                  hiveBox.add(userApiData);
                } else {
                  hiveBox.putAt(0, userApiData);
                }

                kaggleUsernameController.clear();
                kaggleApiInputController.clear();

                setState(() {
                  credsSavedOrNotLetsFindOutResult = isAnyUserApiDataSaved();
                });
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        const SizedBox(height: 16),

        if (kaggleUsername.isNotEmpty && kaggleKey.isNotEmpty)
          Column(
            children: [
              _buildSavedDataCard(
                source: 'kaggle',
                onRemovePress: () {
                  final userApi = getUserApi();
                  if (userApi != null) {
                    final updatedApi = UserApi(kaggleUserName: "", kaggleApiKey: "");
                    hiveBox.putAt(0, updatedApi);
                    setState(() {
                      credsSavedOrNotLetsFindOutResult = isAnyUserApiDataSaved();
                    });
                  }
                },
                onUpdatePress: () {
                  setState(() {
                    kaggleUsernameController.text = kaggleUsername;
                    kaggleApiInputController.text = kaggleKey;

                    final userApi = getUserApi();
                    if (userApi != null) {
                      final updatedApi = UserApi(kaggleUserName: "", kaggleApiKey: "");
                      hiveBox.putAt(0, updatedApi);
                    }
                    credsSavedOrNotLetsFindOutResult = isAnyUserApiDataSaved();
                  });
                },
              ),
              SizedBox(height: 16),
            ],
          ),
      ],
    );
  }

  Widget _buildSavedDataCard({
    required String source,
    required Function() onUpdatePress,
    required Function() onRemovePress,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 23.0, bottom: 23.0, left: 23.0, right: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  !isDarkMode ? AppIcons.checkLight : AppIcons.checkDark,
                  width: 16,
                  height: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Kaggle API',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21.0,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              "Your Kaggle API credentials are saved",
              style: TextStyle(fontSize: 15.0, color: isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onUpdatePress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  child: Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onRemovePress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Color(0xffb6b6b6) : Color(0xffeaeaea),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleCredentialInput({
    required String title,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String tooltip,
    required bool obscureText,
  }) {
    bool isDarkModeEnabled = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDarkModeEnabled ? Colors.white : Colors.black,
              ),
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.help), tooltip: tooltip),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: isDarkModeEnabled ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: TextStyle(color: isDarkModeEnabled ? Colors.white : Colors.black, fontSize: 12),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Disclaimer: I ain't writing any shitty docs for the code, despite knowing I am gonna forget what I wrote.
