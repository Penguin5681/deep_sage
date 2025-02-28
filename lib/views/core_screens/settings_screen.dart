import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_api_model.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkModeEnabled = false;
  bool googleDriveEnabled = false;
  bool dropboxEnabled = false;
  bool awsS3Enabled = false;

  @override
  Widget build(BuildContext context) {
    bool isDarkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController kaggleUsernameController = TextEditingController();
    final TextEditingController kaggleApiInputController = TextEditingController();
    final TextEditingController huggingFaceApiInputController = TextEditingController();
    final hiveApiBoxName = dotenv.env['API_HIVE_BOX_NAME'];
    return Theme(
      data: darkModeEnabled ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: isDarkModeEnabled ? Colors.grey[900] : Colors.white,
        body: Row(
          children: [
            // Right content area
            Expanded(
              child: SingleChildScrollView(
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
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
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
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
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
                            onPressed: () {},
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
                        // Dark Mode
                        // Inside _SettingsScreenState class, replace the dark mode switch implementation
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
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
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
                                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
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
                        // API Management
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
                                  "Kaggle Username and Kaggle Api are\nrequired to conduct search using kaggle.\nIf not provided the default search provider would be hugging face",
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Kaggle Username',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDarkModeEnabled ? Colors.white : Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.help),
                              tooltip: "Required for search using Kaggle",
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        isDarkModeEnabled ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: TextField(
                                  controller: kaggleUsernameController,
                                  style: TextStyle(
                                    color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your Kaggle username',
                                    hintStyle: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Reduced spacing
                        // Kaggle API Key
                        Row(
                          children: [
                            Text(
                              'Kaggle API Key',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDarkModeEnabled ? Colors.white : Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.help),
                              tooltip: "Required for search using Kaggle",
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        isDarkModeEnabled ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: TextField(
                                  obscureText: true,
                                  controller: kaggleApiInputController,
                                  style: TextStyle(
                                    color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your Kaggle API key',
                                    hintStyle: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Hugging Face API Key
                        Row(
                          children: [
                            Text(
                              'Hugging Face Token',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDarkModeEnabled ? Colors.white : Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.help),
                              tooltip:
                                  "Optional: hf token will only be used to download private datasets",
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDarkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        isDarkModeEnabled ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: TextField(
                                  obscureText: true,
                                  controller: huggingFaceApiInputController,
                                  style: TextStyle(
                                    color: isDarkModeEnabled ? Colors.white : Colors.black,
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your Hugging Face API key',
                                    hintStyle: TextStyle(
                                      color:
                                          isDarkModeEnabled ? Colors.grey[400] : Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Save Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final hiveBox = Hive.box(hiveApiBoxName!);
                              final userApiData = UserApi(
                                hfToken: huggingFaceApiInputController.text,
                                kaggleApiKey: kaggleApiInputController.text,
                                kaggleUserName: kaggleUsernameController.text,
                              );
                              hiveBox.add(userApiData);
                              kaggleUsernameController.clear();
                              kaggleApiInputController.clear();
                              huggingFaceApiInputController.clear();
                              // hiveBox.clear();
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
                        const SizedBox(height: 24),
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
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.delete_outline_rounded,
                              color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
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
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[600],
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
                                    color: isDarkModeEnabled ? Colors.grey[400] : Colors.grey[700],
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
}
