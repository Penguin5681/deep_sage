import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Theme(
      data: darkModeEnabled ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: darkModeEnabled ? Colors.grey[900] : Colors.white,
        body: Row(
          children: [
            // Right content area
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: 600, // Set a fixed width for the content
                    padding: const EdgeInsets.all(24.0), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top navigation
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                'DeepSage AI',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: darkModeEnabled ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right, 
                                size: 18,
                                color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Profile card
                        Container(
                          padding: const EdgeInsets.all(16), // Reduced padding
                          decoration: BoxDecoration(
                            color: darkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline, 
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700]
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'User Profile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: darkModeEnabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your account information and preferences',
                                style: TextStyle(
                                  color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
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
                                    color: darkModeEnabled ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Change your profile photo',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Full Name
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: darkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          width: double.infinity,
                          child: Text(
                            'John Smith',
                            style: TextStyle(
                              color: darkModeEnabled ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Email
                        Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: darkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'john.smith@example.com',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.mail_outline,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced spacing
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24), // Reduced spacing
                        // Appearance
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Dark Mode
                        Row(
                          children: [
                            Icon(
                              Icons.dark_mode_outlined,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
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
                                    color: darkModeEnabled ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Toggle between light and dark theme',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Switch(
                              value: darkModeEnabled,
                              onChanged: (value) {
                                setState(() {
                                  darkModeEnabled = value;
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
                        const SizedBox(height: 24), // Reduced spacing
                        // Integrations
                        Text(
                          'Integrations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
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
                        const SizedBox(height: 16), // Reduced spacing
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
                        const SizedBox(height: 16), // Reduced spacing
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
                        const SizedBox(height: 24), // Reduced spacing
                        // API Management
                        Text(
                          'API Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Kaggle API Key
                        Text(
                          'Kaggle API Key',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: darkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: darkModeEnabled ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  'Enter your Kaggle API key',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.key_rounded,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Hugging Face API Key
                        Text(
                          'Hugging Face API Key',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: darkModeEnabled ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: darkModeEnabled ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  'Enter your Hugging Face API key',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.key_rounded,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24), // Reduced spacing
                        // Data Management
                        Text(
                          'Data Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkModeEnabled ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Clear Cache
                        Row(
                          children: [
                            Icon(
                              Icons.cleaning_services_outlined,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
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
                                    color: darkModeEnabled ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Remove temporary files and cached data',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.delete_outline_rounded,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        // Storage Usage
                        Row(
                          children: [
                            Icon(
                              Icons.storage_rounded,
                              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
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
                                    color: darkModeEnabled ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  '2.4 GB of 5 GB used',
                                  style: TextStyle(
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
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
                                    color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_sharp,
                                  color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40), // Reduced bottom padding
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

  Widget _buildSidebarItem(IconData icon, String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? (darkModeEnabled ? Colors.grey[800] : Colors.grey[200]) 
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: darkModeEnabled ? Colors.grey[400] : Colors.grey[800],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: darkModeEnabled ? Colors.white : Colors.black,
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
    return Row(
      children: [
        Icon(
          icon,
          color: darkModeEnabled ? Colors.grey[400] : Colors.grey[700],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: darkModeEnabled ? Colors.white : Colors.black,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: darkModeEnabled ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ],
    );
  }
}