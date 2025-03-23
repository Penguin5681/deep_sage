import 'dart:io';

import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/helpers/route_builder.dart';
import 'package:deep_sage/core/services/directory_path_service.dart';
import 'package:deep_sage/core/services/user_image_service.dart';
import 'package:deep_sage/views/authentication_screens/login_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import "package:googleapis_auth/auth_io.dart";
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

import '../../core/models/hive_models/user_api_model.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Indicates whether dark mode is enabled.
  bool darkModeEnabled = false;

  /// Indicates whether Google Drive integration is enabled.
  bool googleDriveEnabled = false;

  /// Indicates whether Dropbox integration is enabled.
  bool dropboxEnabled = false;

  /// Indicates whether the user should be prompted for a download location.
  bool shouldWeAskForDownloadLocation = false;

  /// Indicates whether AWS S3 integration is enabled.
  bool awsS3Enabled = false;

  /// The default path for downloads.
  String defaultDownloadPath = '';

  /// The URL of an uploaded image.
  String? uploadImageUrl;

  /// Tag used when the Kaggle username is not found.
  final kaggleUsernameNotFoundTag = 'kaggle username not found';

  /// Tag used when the Kaggle API key is not found.
  final kaggleApiKeyNotFoundTag = 'kaggle key not found';

  /// Text controller for the Kaggle username input field.
  final TextEditingController kaggleUsernameController = TextEditingController();

  /// Text controller for the Kaggle API input field.
  final TextEditingController kaggleApiInputController = TextEditingController();

  /// Text controller for the OpenAI API input field.
  final TextEditingController openAiApiInputController = TextEditingController();

  /// Hive box for storing API-related data.
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  /// The name of the Hive box for API data.
  final hiveApiBoxName = dotenv.env['API_HIVE_BOX_NAME'];

  /// Hive box for storing user-related data.
  final userHiveBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);

  /// Hive box for storing user preferences.
  final userPreferencesBox = Hive.box('user_preferences');

  /// Fallback image to use when a user avatar cannot be loaded.
  final Image fallbackUserAvatar = Image.asset('assets/fallback/fallback_user_image.png');

  /// Focus node for the Kaggle username input field.
  late FocusNode kaggleUsernameInputFocus = FocusNode();

  /// Focus node for the Kaggle API input field.
  late FocusNode kaggleApiInputFocus = FocusNode();

  /// [bool] Indicates whether Kaggle API credentials are saved.
  late bool isKaggleApiCredsSaved = false;

  /// [bool] Indicates whether a root directory for datasets has been selected by the user.
  late bool isRootDirectorySelected = false;

  /// [bool] Indicates whether the user has chosen to be asked for a download location every time.
  late bool isDownloadLocationChecked = false;

  /// [Map] Stores the result of checking if Kaggle credentials are saved.
  late Map<String, dynamic> credsSavedOrNotLetsFindOutResult = {};

  /// [String] Stores the selected root directory path for datasets.
  late String selectedRootDirectoryPath = '';

  /// [String] Stores the path to the image selected for upload.
  late String uploadImagePath = '';

  /// [String] Stores the display name of the user.
  late String displayName = '';

  /// [String] Stores the email of the user.
  late String userEmail = '';

  /// [String] Stores the URL of the user's avatar.
  late String userAvatarUrl = '';

  /// [String] Stores the unique identifier of the user.
  late String userId = '';

  /// [String] Stores Google Cloud Platform variables
  late String bucketName;
  late String projectId;
  late String credentialsPath;

  bool isGoogleSignIn = false;

  /// Checks if the user is signed in with Google and updates the UI accordingly.
  ///
  /// This method retrieves the current user's authentication data from Supabase,
  /// checks if the user signed in via Google, and if so, updates the state
  /// to reflect that the user is a Google user and fetches their avatar URL.
  /// If the user's avatar URL is present, it is stored in `userAvatarUrl`.
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

  /// Retrieves the user's preference for whether to ask for a download location.
  ///
  /// This method fetches the value of the 'askForDownloadLocation' key from the
  /// `userPreferencesBox` Hive box. If the value is present, it updates
  /// `isDownloadLocationChecked` with the retrieved value; otherwise, it defaults
  /// to `false`.
  Future<void> getUserPreferences() async {
    final value = await userPreferencesBox.get('askForDownloadLocation');
    setState(() {
      isDownloadLocationChecked = value ?? false;
    });
  }

  /// Retrieves the default downloads directory path or sets it to a platform-specific default.
  ///
  /// This method first attempts to retrieve a saved download path from the Hive box.
  /// If a path is found, it sets `defaultDownloadPath` to this saved path and returns.
  /// If no saved path is found, it determines a platform-specific default path
  /// (e.g., the Downloads folder on Windows, macOS, or Linux) and sets
  /// `defaultDownloadPath` to this value.
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

  /// Retrieves the [UserApi] object from the Hive box.
  ///
  /// This method attempts to retrieve the user API credentials from the Hive box.
  ///
  /// Returns:
  ///   - A [UserApi] object if found in the box.
  ///   - `null` if the box is empty or if an error occurs.
  ///
  UserApi? getUserApi() {
    if (hiveBox.isEmpty) return null;
    try {
      return hiveBox.getAt(0) as UserApi;
    } catch (e) {
      debugPrint('Error getting UserApi: $e');
      return null;
    }
  }

  /// Retrieves the Kaggle username from the UserApi object.
  ///
  /// This getter fetches the Kaggle username from the [UserApi] object. If the
  /// object is `null` or the username is empty, it returns an empty string.
  String get kaggleUsername => getUserApi()?.kaggleUserName ?? '';

  /// Retrieves the Kaggle API key from the UserApi object.
  ///
  /// This getter fetches the Kaggle API key from the [UserApi] object. If the
  /// object is `null` or the API key is empty, it returns an empty string.
  String get kaggleKey => getUserApi()?.kaggleApiKey ?? '';

  /// Checks if any user API data is saved.
  ///
  /// Returns:
  ///   - A [Map] with a "result" key:
  ///     - `true` if both Kaggle username and API key are saved.
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

  /// Builds an icon widget based on the current theme.
  ///
  /// This method constructs an [Image] widget that displays different icons based on
  /// whether the app is in dark mode or light mode.
  ///
  /// Parameters:
  ///   - `lightIcon`: The asset path for the icon to be used in light mode.
  ///   - `darkIcon`: The asset path for the icon to be used in dark mode.
  ///   - `size`: The size of the icon (default: 24).
  ///
  Widget getIconForTheme({required String lightIcon, required String darkIcon, double size = 24}) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(isDarkMode ? darkIcon : lightIcon, width: size, height: size);
      },
    );
  }

  /// Loads the root directory path for dataset storage from persistent storage
  /// or creates a default one.
  ///
  /// This method attempts to:
  /// 1. Retrieve a previously saved path from Hive storage
  /// 2. If a valid path exists, update the state with that path
  /// 3. If no path exists, create a default directory path using
  ///    [_createDefaultRootIfRootNotSelected]
  /// 4. Save the new path to persistent storage
  /// 5. Notify the [DirectoryPathService] about the change so other
  ///    components can react
  ///
  /// The selected path is critical for the application to know where to store
  /// and retrieve datasets.
  Future<void> _loadRootDirectoryPath() async {
    final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
    final savedPath = hiveBox.get('selectedRootDirectoryPath');

    debugPrint(savedPath);
    debugPrint(selectedRootDirectoryPath);
    if (savedPath != null && savedPath is String && savedPath.isNotEmpty) {
      setState(() {
        selectedRootDirectoryPath = savedPath;
        isRootDirectorySelected = true;
      });
      debugPrint(selectedRootDirectoryPath);
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

  /// Creates a default root directory for dataset storage if none exists.
  ///
  /// This method determines an appropriate platform-specific location for storing datasets:
  /// - On Windows: Creates a 'deep_sage_root' folder in the user's profile directory
  /// - On macOS/Linux: Creates a 'deep_sage_root' folder in the user's home directory
  /// - Other platforms: Throws an UnsupportedError as they're not handled
  ///
  /// If the directory doesn't already exist, it creates it with recursive path creation
  /// enabled to ensure parent directories are also created if necessary.
  ///
  /// Returns:
  ///   A [String] containing the absolute path to the created or existing directory
  ///
  /// Throws:
  ///   - [UnsupportedError] if the platform is not supported
  ///   - Rethrows any exceptions that occur during directory creation
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

  /// Obtains an authenticated client for Google Cloud Storage operations.
  ///
  /// This method creates an authenticated HTTP client that can be used for
  /// Google Cloud Storage API calls. It does this by:
  ///
  /// 1. Loading service account credentials from a JSON asset file
  /// 2. Creating credentials from the loaded JSON
  /// 3. Requesting auth scopes for full storage control and general cloud platform access
  /// 4. Obtaining and returning an authenticated client
  ///
  /// Returns:
  ///   An [AuthClient] that can make authenticated requests to Google Cloud APIs
  ///
  /// Note: This implementation loads credentials from an asset file, which is not
  /// recommended for production applications. A more secure approach would be to use
  /// environment variables or a secure credential store.
  Future<AuthClient> obtainAuthenticatedClient() async {
    // this is not a very good way to do shit. remember
    String serviceJson = await rootBundle.loadString('assets/deepsage-452909-06ec904ead63.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceJson);

    var scopes = [StorageApi.devstorageFullControlScope, StorageApi.cloudPlatformScope];

    AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);

    return client;
  }


  /// Allows the user to select and upload a profile image.
  ///
  /// This method handles the complete workflow for profile image management:
  /// 1. Opens a file picker dialog for the user to select an image file
  /// 2. Processes the selected image:
  ///    - Crops it to a square aspect ratio
  ///    - Checks file size constraints (max 12MB)
  /// 3. Uploads the processed image to Google Cloud Storage
  /// 4. Sets appropriate access permissions (public read access)
  /// 5. Updates local state and persistent storage with the new image URL
  ///
  /// The uploaded image is associated with the user's ID for future reference.
  ///
  /// Parameters:
  ///   - `context`: The BuildContext required for showing UI feedback
  ///
  /// Error handling:
  /// - Shows a SnackBar if the file is too large
  /// - Logs detailed error information for various failure points
  ///   (file selection, image processing, authentication, upload, permissions)
  ///
  /// Returns:
  ///   A Future that completes when the upload process is finished or fails

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select a profile photo',
        lockParentWindow: true,
        allowMultiple: false,
        allowedExtensions: ["jpg", "png", "jpeg"],
        type: FileType.custom,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        img.Image? image = img.decodeImage(await file.readAsBytes());

        if (image != null) {
          int cropSize = image.width < image.height ? image.width : image.height;
          int offsetX = (image.width - cropSize) ~/ 2;
          int offsetY = (image.height - cropSize) ~/ 2;
          img.Image croppedImage = img.copyCrop(
            image,
            x: offsetX,
            y: offsetY,
            width: cropSize,
            height: cropSize,
          );

          // Save the cropped image to a temporary file
          File croppedFile = await File(
            '${file.parent.path}/cropped_${file.uri.pathSegments.last}',
          ).writeAsBytes(img.encodeJpg(croppedImage));

          // Check file size limit (12MB)
          if (croppedFile.lengthSync() > 12 * 1024 * 1024) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('File size should not be more than 12MB')));
            return;
          }

          setState(() {
            uploadImagePath = croppedFile.path;
          });
          debugPrint("Selected file: ${croppedFile.path}");

          // get an authenticated client
          AuthClient gcpClient = await obtainAuthenticatedClient();
          debugPrint('Authentication successful');

          var storageClient = StorageApi(gcpClient);
          var media = Media(croppedFile.openRead(), await croppedFile.length());

          // file name is now jus curr time. will change it to supabase id
          // update. the file name is now changes to the supabase user uid. (testing awaited)
          String uniqueFileName = '$userId${path.extension(croppedFile.path).trim()}';
          debugPrint('Attempting to upload file as: $uniqueFileName');

          try {
            var object = await storageClient.objects.insert(
              Object()..name = uniqueFileName,
              'user_image_data',
              uploadMedia: media,
            );
            debugPrint('Object uploaded successfully: ${object.name}');

            try {
              // the role should be READER for us general public, when needed change it to WRITER or OWNER.
              await storageClient.objectAccessControls.insert(
                ObjectAccessControl()
                  ..entity = 'allUsers'
                  ..role = 'READER',
                'user_image_data',
                object.name!,
              );
              debugPrint('Public access set successfully');

              // bucket name is now fixed
              var imageUrl = 'https://storage.googleapis.com/$bucketName/${object.name}';
              userHiveBox.put('userAvatarUrl', imageUrl);

              UserImageService().updateProfileImageUrl(imageUrl);

              setState(() {
                userAvatarUrl = imageUrl;
              });
              debugPrint('File available at: $imageUrl');

              // Update the state with the new image URL
              setState(() {
                uploadImageUrl = imageUrl;
              });
            } catch (aclError) {
              debugPrint('Error setting public access: $aclError');
            }
          } catch (uploadError) {
            debugPrint('Error uploading object: $uploadError');
            if (uploadError is DetailedApiRequestError) {
              debugPrint('Error status: ${uploadError.status}');
              debugPrint('Error message: ${uploadError.message}');
            }
          }
        } else {
          debugPrint('Image decoding failed');
        }
      } else {
        debugPrint('No file selected');
      }
    } catch (ex) {
      debugPrint('General error: $ex');
    }
  }

  /// Loads and returns a user's profile image, attempting multiple sources in order:
  ///
  /// 1. First checks the [UserImageService] cache for a cached URL
  /// 2. Then attempts to retrieve from Hive storage using 'userAvatarUrl' key
  /// 3. If no stored URL, attempts to construct one using userId with different extensions
  /// 4. Falls back to a default avatar if all attempts fail
  ///
  /// The method follows this process:
  /// - Returns cached image from [UserImageService] if available
  /// - Checks Hive storage for previously saved URL
  /// - If userId exists, tries common image extensions (.jpg, .png, etc.)
  /// - Makes HEAD requests to check if constructed URLs are valid
  /// - Saves valid URL to Hive storage for future use
  /// - Returns fallback avatar if no valid image is found
  ///
  /// Parameters:
  ///   None
  ///
  /// Returns:
  ///   [Future<Image>] - An Image widget containing either:
  ///   - The user's profile image from network
  ///   - A fallback avatar image if no profile image is found
  ///
  /// Throws:
  ///   No exceptions are thrown, errors are caught and logged via [debugPrint]
  Future<Image> loadProfileImageFromHive() async {
    if (UserImageService().cachedUrl != null) {
      return Image.network(UserImageService().cachedUrl!);
    }

    final imageUrl = await userHiveBox.get('userAvatarUrl');
    if (imageUrl != null) {
      UserImageService().updateProfileImageUrl(imageUrl);
      return Image.network(imageUrl);
    }
    if (userId.isNotEmpty) {
      final extensions = ['.jpg', '.png', '.jpeg', '.svg'];

      for (final ext in extensions) {
        final constructedUrl = 'https://storage.googleapis.com/user_image_data/$userId$ext';

        try {
          final response = await http.head(Uri.parse(constructedUrl));

          if (response.statusCode == 200) {
            await userHiveBox.put('userAvatarUrl', constructedUrl);
            return Image.network(constructedUrl);
          }
        } catch (e) {
          debugPrint('Failed to check URL with extension $ext: $e');
        }
      }

      debugPrint('No valid image found for user ID: $userId');
    }
    return fallbackUserAvatar;
  }

  /// Builds a profile image widget based on different loading priorities.
  ///
  /// This method decides which profile image to display based on a set of priorities:
  /// 1. If the user is signed in with Google and has a non-empty avatar URL, use that.
  /// 2. If there's a cached URL in the [UserImageService], use that.
  /// 3. If neither of the above is true, try to load an image from Hive storage.
  /// 4. While loading from Hive, a placeholder with a progress indicator is displayed.
  /// 5. If loading from Hive fails, a fallback image is used.
  ///
  /// The widget updates reactively to changes in the [UserImageService]'s
  /// profileImageUrl value notifier.
  ///
  /// Parameters:
  ///   None
  ///
  /// Returns:
  ///   [Widget] - The profile image widget.
  ///
  /// Errors:
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

  /// Helper method to show fallback image
  Widget _buildFallbackImage() {
    return ClipOval(child: SizedBox(width: 48, height: 48, child: fallbackUserAvatar));
  }

  @override
  void initState() {
    super.initState();
    getUserMetadata();
    checkIfGoogleSignIn();
    getDownloadsDirectory();
    _loadRootDirectoryPath();
    kaggleApiInputFocus = FocusNode();
    kaggleUsernameInputFocus = FocusNode();
    credsSavedOrNotLetsFindOutResult = isAnyUserApiDataSaved();
    getUserPreferences();

    bucketName = 'user_image_data';
    projectId = dotenv.env['GCP_PROJECT_ID']!;
    credentialsPath = dotenv.env['GCP_CREDENTIALS_PATH']!;
  }

  @override
  void dispose() {
    kaggleApiInputFocus.dispose();
    kaggleUsernameInputFocus.dispose();
    super.dispose();
  }

  /// Retrieves the current user's metadata from Supabase and updates the state.
  ///
  /// This method fetches the current user's data from the Supabase authentication
  /// client. If a user is found, it extracts the display name, email, and user ID
  /// from their metadata. Additionally, if the user signed in with Google, it
  /// retrieves their avatar URL.
  ///
  /// - `displayName`: Set to the user's full name or display name if available,
  ///   otherwise defaults to "User".
  /// - `userEmail`: Set to the user's email, or "No Email" if not available.
  /// - `userId`: Set to the unique identifier of the user.
  void getUserMetadata() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        displayName =
            user.userMetadata?['full_name'] ?? user.userMetadata?['display_name'] ?? 'User';
        userEmail = user.email ?? 'No Email';
        userId = user.id;

        if (user.appMetadata['provider'] == 'google') {
          userAvatarUrl = user.userMetadata?['avatar_url'] ?? '';
        }
      });
    }
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
                              buildProfileImage(),
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
                              if (!isGoogleSignIn) // Only show the edit icon if the user did noy sign in with Google
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                  iconSize: 20,
                                  onPressed: () async {
                                    // alr, watch this.
                                    await _pickAndUploadImage(context);
                                  },
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
                            // Show the name on the text widget from supabase
                            child: Text(
                              displayName,
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
                                    // Show the email on the text widget from supabase
                                    userEmail,
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
                              onPressed: () async {
                                await Hive.box(
                                  dotenv.env['USER_HIVE_BOX']!,
                                ).delete('userSessionToken');
                                if (!context.mounted) return;
                                Navigator.of(
                                  context,
                                ).pushReplacement(RouteBuilder().build(LoginScreen(), 1.0, 0));
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
                                        'Ask for download location everytime',
                                        style: TextStyle(
                                          color: isDarkModeEnabled ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Prompt for download location before importing / downloading',
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
                                value: isDownloadLocationChecked,
                                onChanged: (value) async {
                                  setState(() {
                                    isDownloadLocationChecked = value;
                                  });
                                  await userPreferencesBox.put(
                                    'askForDownloadLocation',
                                    isDownloadLocationChecked,
                                  );
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

  /// Builds a widget representing a single integration item in the settings.
  ///
  /// This widget displays an icon, title, description, and a toggle switch for an
  /// integration. It's designed to be reusable for various types of integrations.
  ///
  /// Parameters:
  ///   - `icon`: The [IconData] for the integration item's icon.
  ///   - `title`: The main title text for the integration.
  ///   - `description`: A brief description of the integration.
  ///   - `value`: A [bool] indicating whether the integration is currently enabled.
  ///   - `onChanged`: A callback function that is called when the toggle switch is
  ///     toggled, providing a [bool] representing the new value of the switch.
  ///
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

  /// Builds and returns a widget that displays the API Management section of the Settings screen.
  ///
  /// This section allows users to manage their Kaggle API credentials, which are required
  /// for searching and downloading datasets from Kaggle. The section dynamically shows
  /// different UI components based on whether credentials are already saved:
  ///
  /// - If credentials are missing, it shows input fields and a save button
  /// - If credentials are already saved, it shows a card with options to update or remove them
  ///
  /// The method uses several helper methods:
  /// - [_buildSingleCredentialInput] for creating text input fields
  /// - [_buildSavedDataCard] for displaying saved credential information
  /// - [getUserApi] to retrieve current API credentials from storage
  /// - [isAnyUserApiDataSaved] to check if credentials are already saved
  ///
  /// Returns:
  ///   A [Widget] containing the complete API Management section UI.
  Widget buildApiManagementSection() {
    // Detect current theme for appropriate styling
    bool isDarkModeEnabled = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with title and help icon
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

        // Conditional UI: Show Kaggle username input field if not saved
        if (kaggleUsername.isEmpty)
          _buildSingleCredentialInput(
            title: 'Kaggle Username',
            hintText: 'Enter your Kaggle username',
            controller: kaggleUsernameController,
            focusNode: kaggleUsernameInputFocus,
            tooltip: "Required for search using Kaggle",
            obscureText: false,
          ),

        // Conditional UI: Show Kaggle API key input field if not saved
        if (kaggleKey.isEmpty)
          _buildSingleCredentialInput(
            title: 'Kaggle API Key',
            hintText: 'Enter your Kaggle API key',
            controller: kaggleApiInputController,
            focusNode: kaggleApiInputFocus,
            tooltip: "Required for search using Kaggle",
            obscureText: true,
          ),

        // Conditional UI: Show save button if either credential is missing
        if (kaggleUsername.isEmpty || kaggleKey.isEmpty)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Access the Hive storage box for API credentials
                final hiveBox = Hive.box(hiveApiBoxName!);

                // Get existing data or create empty credentials object
                UserApi existingData =
                    getUserApi() ?? UserApi(kaggleUserName: "", kaggleApiKey: "");

                // Create new user API object, preserving any existing values
                // that aren't being updated in the current form submission
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

                // Store credentials in Hive box
                if (hiveBox.isEmpty) {
                  hiveBox.add(userApiData);
                } else {
                  hiveBox.add(userApiData);
                }

                // Clear input fields after saving
                kaggleUsernameController.clear();
                kaggleApiInputController.clear();

                // Update UI state to reflect saved credentials
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

        // Conditional UI: Show saved credentials card if both are available
        if (kaggleUsername.isNotEmpty && kaggleKey.isNotEmpty)
          Column(
            children: [
              _buildSavedDataCard(
                source: 'kaggle',
                onRemovePress: () {
                  // Handle credential removal
                  final userApi = getUserApi();
                  if (userApi != null) {
                    // Replace with empty credentials
                    final updatedApi = UserApi(kaggleUserName: "", kaggleApiKey: "");
                    hiveBox.putAt(0, updatedApi);
                    setState(() {
                      credsSavedOrNotLetsFindOutResult = isAnyUserApiDataSaved();
                    });
                  }
                },
                onUpdatePress: () {
                  // Handle credential update request
                  setState(() {
                    // Populate input fields with current values for editing
                    kaggleUsernameController.text = kaggleUsername;
                    kaggleApiInputController.text = kaggleKey;

                    // Remove current credentials so input fields appear
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

  /// Builds a styled card display for saved API credentials.
  ///
  /// This widget creates a container that displays information about stored API
  /// credentials and provides action buttons to update or remove them.
  ///
  /// The card shows:
  ///   - A checkmark icon in a circular container
  ///   - The name of the API service (currently fixed to 'Kaggle API')
  ///   - A confirmation message that credentials are saved
  ///   - Two action buttons: Update and Remove
  ///
  /// Parameters:
  ///   - `source`: A string identifier for the API source (e.g., 'kaggle')
  ///   - `onUpdatePress`: Callback function triggered when the Update button is pressed
  ///   - `onRemovePress`: Callback function triggered when the Remove button is pressed
  ///
  /// The styling of this card adapts based on the current theme (light/dark mode).
  ///
  /// Returns:
  ///   A styled [Container] widget displaying the saved credentials information
  ///   and action buttons.
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

  /// Builds a styled input field for credential entry.
  ///
  /// This widget creates a complete input field component with a label, help icon,
  /// and a styled text field. It's specifically designed for credential entry in the
  /// API Management section.
  ///
  /// The component includes:
  /// - A row with the field title and a help tooltip icon
  /// - A styled [TextField] with appropriate theme-aware styling
  /// - Proper spacing between elements
  ///
  /// Parameters:
  ///   - `title`: The label text displayed above the input field
  ///   - `hintText`: Placeholder text shown in the empty input field
  ///   - `controller`: A [TextEditingController] that manages the text being edited
  ///   - `focusNode`: A [FocusNode] that manages the focus state of this input
  ///   - `tooltip`: Text shown when hovering over the help icon
  ///   - `obscureText`: Whether to hide the input text (for passwords/API keys)
  ///
  /// Returns:
  ///   A [Widget] containing the complete credential input field
  ///
  /// Example:
  ///   ```dart
  ///   _buildSingleCredentialInput(
  ///     title: 'API Key',
  ///     hintText: 'Enter your API key',
  ///     controller: apiKeyController,
  ///     focusNode: apiKeyFocusNode,
  ///     tooltip: "Required for API access",
  ///     obscureText: true,
  ///   )
  ///   ```
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
/// Update: i am gonna write docs gng ??
