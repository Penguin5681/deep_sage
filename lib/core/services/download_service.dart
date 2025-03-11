import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:deep_sage/core/models/download_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DownloadService extends ChangeNotifier {
  final Map<String, DownloadItem> _downloads = {};
  final Queue<String> _downloadQueue = Queue<String>();
  // final Box<dynamic> _downloadHistoryBox;
  Future<void> retryDownload(String datasetId) async {
    if (_downloads.containsKey(datasetId)) {
      final download = _downloads[datasetId]!;
      await downloadDataset(
          source: download.source,
          datasetId: datasetId
      );
    }
  }

  void clearCompletedDownloads() {
    _downloads.removeWhere((_, item) => item.isComplete);
    notifyListeners();
  }

  List<DownloadItem> get downloads => _downloads.values.toList();

  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';
  StreamSubscription? _sseSubscription;
  bool _isConnected = false;

  String? _currentDownloadDatasetId;

  bool get isDownloading => _currentDownloadDatasetId != null;


  Future<void> downloadDataset({
    required String source,
    required String datasetId,
    bool unzip = false,
  }) async {
    if (isDownloading) {
      throw Exception('A download is already in progress');
    }

    _currentDownloadDatasetId = datasetId;

    final initialDownload = DownloadItem(
      name: datasetId
          .split('/')
          .last,
      size: 'Calculating...',
      timeStarted: DateTime.now(),
      progress: 0.0,
      isComplete: false,
      source: source,
    );

    _downloads[datasetId] = initialDownload;
    notifyListeners();

    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
      final userApiHive = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

      final userApi = userApiHive.getAt(0);
      final kaggleUsername = userApi?.kaggleUserName ?? '';
      final kaggleKey = userApi?.kaggleApiKey ?? '';

      if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
        _updateDownloadWithError(
            datasetId,
            'Kaggle credentials not found. Please update them in settings.'
        );
        return;
      }

      final downloadPath = hiveBox.get('selectedRootDirectoryPath');

      if (downloadPath == null || downloadPath.isEmpty) {
        _updateDownloadWithError(
            datasetId,
            'Download path not set. Please set it in settings.'
        );
        return;
      }

      await _startDownload(
        datasetId: datasetId,
        source: source,
        path: downloadPath,
        unzip: unzip,
        kaggleUsername: kaggleUsername,
        kaggleKey: kaggleKey,
      );
    } catch (e) {
      _updateDownloadWithError(datasetId, 'Failed to start download: ${e.toString()}');
    }
  }

  Future<void> _startDownload({
    required String datasetId,
    required String source,
    required String path,
    required bool unzip,
    required String kaggleUsername,
    required String kaggleKey,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/datasets/download');

    final client = http.Client();

    try {
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['X-Kaggle-Username'] = kaggleUsername;
      request.headers['X-Kaggle-Key'] = kaggleKey;

      request.body = jsonEncode({
        'source': source,
        'dataset_id': datasetId,
        'path': path,
        'unzip': unzip,
      });

      final response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();
        _updateDownloadWithError(datasetId, 'Server error: $error');
        return;
      }

      _sseSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
          if (line.startsWith('data:')) {
            final jsonData = line.substring(5).trim();
            _processDownloadUpdate(jsonData);
          }
        },
        onDone: () {
          _isConnected = false;
          _cleanupDownload();
        },
        onError: (error) {
          _isConnected = false;
          _updateDownloadWithError(datasetId, 'Connection error: $error');
          _cleanupDownload();
        },
        cancelOnError: true,
      );

      _isConnected = true;
    } catch (e) {
      _updateDownloadWithError(datasetId, 'Network error: ${e.toString()}');
      client.close();
    }
  }

  void _processDownloadUpdate(String jsonData) {
    try {
      final data = jsonDecode(jsonData);
      final state = data['state'];
      final datasetId = data['dataset_id'];

      if (datasetId != _currentDownloadDatasetId) return;

      if (state == 'error') {
        _updateDownloadWithError(datasetId, data['error'] ?? 'Unknown error');
        _cleanupDownload();
        return;
      }

      final progress = (data['progress'] ?? 0) / 100.0;
      final bytesDownloaded = data['bytes_downloaded'] ?? 0;
      final speed = data['speed'] ?? '0 B/s';
      final message = data['message'] ?? 'Downloading...';

      String size = '0 B';
      if (bytesDownloaded > 0) {
        if (bytesDownloaded < 1024) {
          size = '$bytesDownloaded B';
        } else if (bytesDownloaded < 1024 * 1024) {
          size = '${(bytesDownloaded / 1024).toStringAsFixed(1)} KB';
        } else if (bytesDownloaded < 1024 * 1024 * 1024) {
          size = '${(bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          size = '${(bytesDownloaded / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
        }
      }

      final isComplete = state == 'completed';

      final updatedDownload = _downloads[datasetId]?.copyWith(
        progress: progress,
        isComplete: isComplete,
        size: size,
        downloadSpeed: speed,
      );

      if (updatedDownload != null) {
        _downloads[datasetId] = updatedDownload;
        notifyListeners();
      }

      if (isComplete) {
        _cleanupDownload();
      }
    } catch (e) {
      debugPrint('Error processing download update: $e');
    }
  }

  void _updateDownloadWithError(String datasetId, String errorMessage) {
    final download = _downloads[datasetId];
    if (download != null) {
      _downloads[datasetId] = download.copyWith(
        isComplete: true,
        progress: 0.0,
        downloadSpeed: 'Error',
      );
      notifyListeners();
    }
    debugPrint('Download error: $errorMessage');
  }

  void _cleanupDownload() {
    _currentDownloadDatasetId = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _isConnected = false;
    notifyListeners();
  }

  void cancelDownload() {
    _cleanupDownload();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }
}