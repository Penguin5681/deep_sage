import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MachineLearningScreen extends StatefulWidget {
  const MachineLearningScreen({super.key});

  @override
  State<MachineLearningScreen> createState() => _MachineLearningScreenState();
}

class _MachineLearningScreenState extends State<MachineLearningScreen> {
  late String? currentDatasetPath = '';
  late String? currentDatasetType = '';
  late String? currentDatasetName = '';
  bool _isDatasetSelected = false;

  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  void loadDatasetMetadata() {
    currentDatasetPath = recentImportsBox.get('currentDatasetPath');
    currentDatasetType = recentImportsBox.get('currentDatasetType');
    currentDatasetName = recentImportsBox.get('currentDatasetName');

    _isDatasetSelected = currentDatasetPath != null &&
                        currentDatasetPath!.isNotEmpty &&
                        currentDatasetName != null &&
                        currentDatasetName!.isNotEmpty;
  }

  void _showDatasetSelectionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dataset Selection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isDatasetSelected) ...[
                Text('Currently selected dataset:'),
                SizedBox(height: 8),
                Text('$currentDatasetName',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Type: $currentDatasetType'),
                SizedBox(height: 16),
                Text('Would you like to continue with this dataset or import a new one?')
              ] else
                Text('No dataset is currently selected. Would you like to import one?'),
            ],
          ),
          actions: [
            if (_isDatasetSelected)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: will perform some operations here with the current dataset
                  setState(() {});
                },
                child: Text('Use Current Dataset'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: open a file picker here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import functionality to be implemented')),
                );
              },
              child: Text('Import New Dataset'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadDatasetMetadata();
    debugPrint('Current Dataset: \n$currentDatasetName\n$currentDatasetType\n$currentDatasetPath\n');

    // Show the overlay after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDatasetSelectionOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isDatasetSelected
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Working with dataset: $currentDatasetName',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Machine learning options will appear here',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _showDatasetSelectionOverlay,
                    child: Text('Change Dataset'),
                  ),
                ],
              )
            : Text(
                'No dataset selected',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

/*

How do i design this?!

Since I Already have the dataset metadata, i'll just show an overlay if the user wants to keep using
this dataset or import another one (this would a whole different file management)

 */