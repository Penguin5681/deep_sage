import 'dart:io';

import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/services/core_services/data_preview_service.dart';
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
  final DataPreviewService _previewService = DataPreviewService();

  Map<String, dynamic>? previewData;
  bool isLoading = false;

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
    final storedDatasetPath = importedDatasets.get('currentDatasetPath');
    final storedDatasetType = importedDatasets.get('currentDatasetType');

    debugPrint('Dataset changed: ${widget.selectedDatasetNotifier.value}');
    debugPrint('Path: $storedDatasetPath, Type: $storedDatasetType');

    if (storedDatasetPath == null || !File(storedDatasetPath).existsSync()) {
      setState(() {
        isDatasetImported = false;
        importedDatasetPath = '';
        importedDatasetType = '';
        previewData = null;
      });
      return;
    }

    bool isNewDataset = importedDatasetPath != storedDatasetPath;

    setState(() {
      isDatasetImported = true;
      importedDatasetPath = storedDatasetPath;
      importedDatasetType = storedDatasetType ?? '';
      if (isNewDataset) {
        previewData = null;
      }
    });

    _loadPreviewData();
  }


  Future<void> _loadPreviewData() async {
    if (!isDatasetImported || importedDatasetPath.isEmpty) {
      setState(() {
        previewData = null;
      });
      return;
    }

    final pathToLoad = importedDatasetPath;
    final typeToLoad = importedDatasetType;

    debugPrint('Loading preview: $pathToLoad ($typeToLoad)');

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _previewService.loadDatasetPreview(
        pathToLoad,
        typeToLoad,
        10,
      );

      debugPrint('typeToLoad $typeToLoad');

      if (mounted) {
        setState(() {
          previewData = result;
          isLoading = false;
        });
        debugPrint('Preview loaded: ${result != null ? 'success' : 'failed'}');
      }
    } catch (ex) {
      if (mounted) {
        setState(() {
          previewData = null;
          isLoading = false;
        });
      }
      debugPrint('Preview error: $ex');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedDataset();
    widget.selectedDatasetNotifier.addListener(_handleDatasetChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreviewData();
    });
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
        child:
            isDatasetImported && importedDatasetPath.isNotEmpty
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
          'Dataset: $fileName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
        const SizedBox(height: 16.0),
        _buildMetadataInfo(),
        const SizedBox(height: 8.0),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : previewData == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataInfo() {
    if (previewData == null || !previewData!.containsKey('metadata')) {
      return Text(
        'Preview (showing up to 10 rows):',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
      );
    }

    final metadata = previewData!['metadata'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total rows: ${metadata['total_rows']} · Size: ${metadata['file_size_formatted']}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Preview (showing up to ${metadata['preview_rows']} rows):',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (previewData == null || !previewData!.containsKey('preview') || !previewData!.containsKey('columns')) {
      return const Center(child: Text('Invalid data format'));
    }

    final columns = previewData!['columns'] as List<dynamic>;
    final preview = previewData!['preview'] as List<dynamic>;

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 40,
      columns: List<DataColumn>.generate(
        columns.length,
            (index) => DataColumn(
          label: Text(
            columns[index].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      rows: List<DataRow>.generate(
        preview.length,
            (rowIndex) {
          final row = preview[rowIndex] as Map<String, dynamic>;
          return DataRow(
            cells: List<DataCell>.generate(
              columns.length,
                  (cellIndex) => DataCell(
                Text(row[columns[cellIndex]]?.toString() ?? ''),
              ),
            ),
          );
        },
      ),
    );
  }
}
