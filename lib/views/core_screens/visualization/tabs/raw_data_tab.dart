import 'dart:io';

import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;

class RawDataTab extends StatefulWidget {
  final ValueNotifier<String?> selectedDatasetNotifier;

  const RawDataTab({super.key, required this.selectedDatasetNotifier});

  @override
  State<RawDataTab> createState() => _RawDataTabState();
}

class _RawDataTabState extends State<RawDataTab> {
  late bool isDatasetImported = false;
  late String importedDatasetPath = '';
  late String importedDatasetType = '';
  final Box importedDatasets = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);

  void retrieveRecentDataset() {
    final dynamic recentImportsData = importedDatasets.get('recentImports');

    List<RecentImportsModel> recentImports = [];
    if (recentImportsData is List) {
      recentImports = recentImportsData.cast<RecentImportsModel>();
    } else if (recentImportsData is RecentImportsModel) {
      recentImports = [recentImportsData];
    }

    if (recentImports.isNotEmpty &&
        recentImports[0].filePath != null &&
        recentImports[0].filePath!.isNotEmpty) {
      final recentImport = recentImports[0];
      setState(() {
        isDatasetImported = true;
        importedDatasetPath = recentImport.filePath!;
        importedDatasetType = recentImport.fileType;
      });
    } else {
      setState(() {
        isDatasetImported = false;
        importedDatasetPath = '';
        importedDatasetType = '';
      });
    }
  }

  void _loadSelectedDataset() {
    final storedDatasetPath = importedDatasets.get('currentDatasetPath');
    final storedDatasetType = importedDatasets.get('currentDatasetType');

    if (storedDatasetPath != null && File(storedDatasetPath).existsSync()) {
      setState(() {
        isDatasetImported = true;
        importedDatasetPath = storedDatasetPath;
        importedDatasetType = storedDatasetType ?? '';
      });
    } else {
      retrieveRecentDataset();
    }
  }

  void _handleDatasetChange() {
    if (widget.selectedDatasetNotifier.value == null) {
      setState(() {
        isDatasetImported = false;
        importedDatasetPath = '';
        importedDatasetType = '';
      });
    } else {
      final storedDatasetPath = importedDatasets.get('currentDatasetPath');
      final storedDatasetType = importedDatasets.get('currentDatasetType');

      if (storedDatasetPath != null && File(storedDatasetPath).existsSync()) {
        setState(() {
          isDatasetImported = true;
          importedDatasetPath = storedDatasetPath;
          importedDatasetType = storedDatasetType ?? '';
        });
      } else {
        setState(() {
          isDatasetImported = false;
          importedDatasetPath = '';
          importedDatasetType = '';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedDataset();
    widget.selectedDatasetNotifier.addListener(_handleDatasetChange);
  }

  @override
  void dispose() {
    widget.selectedDatasetNotifier.removeListener(_handleDatasetChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isDatasetImported && importedDatasetPath.isNotEmpty
            ? _buildDatasetView()
            : _buildNoDatasetView(),
      ),
    );
  }

  Widget _buildNoDatasetView() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'No Dataset imported yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26.0),
          ),
          const Text('Import a dataset to begin exploring and analyzing your data'),
          const SizedBox(height: 18.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // todo: upon clicking the button, redirect to folder_screen
                  // todo: on folder_screen, enable double clicking the dataset title

                  // todo: upon double click import the dataset, by import i mean just store the path
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Import Locally',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15.0),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade600, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  foregroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  "Browse Kaggle",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Add your dataset viewing widgets here
        ],
      ),
    );
  }

  Widget _buildDatasetView() {
    final fileName = path.basename(importedDatasetPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Dataset: $fileName',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26.0),
        ),
        SizedBox(height: 10),
        Text(
          'Type: ${importedDatasetType.toUpperCase()} • Path: $importedDatasetPath',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 20),

        // Add dataset preview here
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Dataset preview will be shown here'),
            ),
          ),
        ),
      ],
    );
  }
}
