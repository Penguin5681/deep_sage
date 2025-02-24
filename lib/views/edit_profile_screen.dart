import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: DevFAB(parentContext: context),
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DataVision AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16), // Reduced spacing
                _buildNavItem(Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(Icons.dataset_outlined, 'Data Sets'),
                _buildNavItem(Icons.analytics_outlined, 'Analysis'),
                _buildNavItem(Icons.description_outlined, 'Reports'),
                _buildNavItem(
                  Icons.settings_outlined,
                  'Settings',
                  isSelected: true,
                ),
                const Spacer(),
                // Profile section at bottom
                const Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                    SizedBox(width: 8), // Reduced spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Smith',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Data Scientist',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  width: 600, // Set a fixed width for the content
                  padding: const EdgeInsets.all(24.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          Text(
                            'DataVision AI',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                          Text(
                            'Settings',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Reduced spacing
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24), // Reduced spacing
                      // Profile Photo Section
                      Container(
                        padding: const EdgeInsets.all(16), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload a new profile photo or remove the current one',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12), // Reduced spacing
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Upload Photo'),
                                ),
                                const SizedBox(width: 8), // Reduced spacing
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // Reduced spacing
                      // Form Fields
                      _buildFormField(
                        'Full Name',
                        'John Smith',
                        Icons.person_outline,
                      ),
                      _buildFormField(
                        'Job Title',
                        'Data Scientist',
                        Icons.work_outline,
                      ),
                      _buildFormField(
                        'Email',
                        'john.smith@example.com',
                        Icons.email_outlined,
                      ),
                      _buildFormField(
                        'Bio',
                        'Tell us about yourself',
                        null,
                        isMultiline: true,
                      ),
                      const SizedBox(height: 24), // Reduced spacing
                      // Action Buttons
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Save Changes'),
                          ),
                          const SizedBox(width: 8), // Reduced spacing
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24), // Reduced bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 20),
          const SizedBox(width: 8), // Reduced spacing
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    String placeholder,
    IconData? icon, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Reduced spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: isMultiline ? 4 : 1,
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            ),
          ),
        ],
      ),
    );
  }
}
