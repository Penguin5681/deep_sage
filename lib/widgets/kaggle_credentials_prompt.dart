import 'package:deep_sage/core/models/user_api_model.dart';
import 'package:deep_sage/core/services/kaggle_update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';

class KaggleCredentialsPrompt extends StatefulWidget {
  final VoidCallback onCredentialsAdded;

  const KaggleCredentialsPrompt({super.key, required this.onCredentialsAdded});

  @override
  State<KaggleCredentialsPrompt> createState() =>
      _KaggleCredentialsPromptState();
}

class _KaggleCredentialsPromptState extends State<KaggleCredentialsPrompt> {
  late TextEditingController usernameController;
  late TextEditingController apiKeyController;
  late Box hiveBox;
  bool _disposed = false;

  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode apiKeyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    apiKeyController = TextEditingController();
    hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
  }

  void _saveCredentials() async {
    if (_disposed) return;

    if (usernameController.text.isEmpty || apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both username and key are required')),
      );
      return;
    }

    final userApiData = UserApi(
      kaggleApiKey: apiKeyController.text,
      kaggleUserName: usernameController.text,
    );

    try {
      if (!hiveBox.isOpen) {
        await Hive.openBox(dotenv.env['API_HIVE_BOX_NAME']!);
      }

      await hiveBox.clear();
      await hiveBox.add(userApiData);

      KaggleUpdateService().updateKaggleCreds(
        usernameController.text,
        apiKeyController.text,
      );

      debugPrint('Credentials saved successfully: ${usernameController.text}');

      if (!_disposed) {
        widget.onCredentialsAdded();
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
      if (!mounted) return;
      if (!_disposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    usernameController.dispose();
    apiKeyController.dispose();
    apiKeyFocusNode.dispose();
    usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.api, color: Colors.blue),
              SizedBox(width: 12),
              Text(
                'Kaggle API Credentials Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'To search and download datasets from Kaggle, please enter your credentials:',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 24),
          TextField(
            controller: usernameController,
            focusNode: usernameFocusNode,
            decoration: InputDecoration(
              labelText: 'Kaggle Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: apiKeyController,
            focusNode: apiKeyFocusNode,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Kaggle API Key',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key),
              helperText: 'Get your API key from kaggle.com/account',
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Skip'),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saveCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Save Credentials'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
