import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:deep_sage/core/models/download_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A service that manages dataset downloads from various sources.
///
/// This class handles downloading datasets, maintaining a download queue,
/// tracking download progress, and providing status updates through notifications.
class DownloadService extends ChangeNotifier {
  final Map<String, DownloadItem> _downloads = {};
  final Queue<Map<String, dynamic>> _downloadQueue =
      Queue<Map<String, dynamic>>();
  bool _isProcessingQueue = false;
  final StreamController<void> _downloadStreamController =
      StreamController<void>.broadcast();

  /// Stream that emits events when download status changes.
  Stream<void> get stream => _downloadStreamController.stream;

  /// Retries a previously failed or canceled download.
  ///
  /// @param datasetId The ID of the dataset to retry downloading.
  Future<void> retryDownload(String datasetId) async {
    if (_downloads.containsKey(datasetId)) {
      final download = _downloads[datasetId]!;
      await downloadDataset(source: download.source, datasetId: datasetId);
    }
  }

  /// Removes all completed downloads from the downloads list.
  void clearCompletedDownloads() {
    _downloads.removeWhere((_, item) => item.isComplete);
    notifyListeners();
  }

  /// Cancels an in-progress download.
  ///
  /// @param datasetId Optional ID of the dataset to cancel. If null, cancels the current download.
  Future<void> cancelDownload([String? datasetId]) async {
    if (datasetId == null) {
      if (_currentDownloadDatasetId != null) {
        await _cancelDownloadRequest(_currentDownloadDatasetId!);
      }
    } else if (_downloads.containsKey(datasetId)) {
      await _cancelDownloadRequest(datasetId);
      _downloads[datasetId] = _downloads[datasetId]!.copyWith(
        downloadSpeed: 'Cancelled',
        progress: 0.0,
      );
      notifyListeners();
    }
  }

  /// Sends a cancellation request to the server.
  ///
  /// @param datasetId ID of the dataset to cancel.
  Future<void> _cancelDownloadRequest(String datasetId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/datasets/cancel');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dataset_id': datasetId}),
      );

      debugPrint('$response');

      if (response.statusCode == 200) {
        debugPrint('$response');
        if (datasetId == _currentDownloadDatasetId) {
          _cleanupDownload();
        }
        _downloads.remove(datasetId);
        notifyListeners();
      } else {
        debugPrint('Failed to cancel download: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error cancelling download: $e');
    }
  }

  /// Gets a list of all current downloads.
  List<DownloadItem> get downloads => _downloads.values.toList();

  final String _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:5000';
  StreamSubscription? _sseSubscription;
  bool _isConnected = false;

  String? _currentDownloadDatasetId;

  /// Whether a download is currently in progress.
  bool get isDownloading => _currentDownloadDatasetId != null;

  /// Processes the download queue in a sequential manner.
  ///
  /// This method handles the queue of download requests and processes them one by one.
  Future<void> _processQueue() async {
    if (_downloadQueue.isEmpty || _isProcessingQueue) return;

    _isProcessingQueue = true;

    while (_downloadQueue.isNotEmpty) {
      final downloadInfo = _downloadQueue.first;
      final datasetId = downloadInfo['datasetId'];

      if (_downloads.containsKey(datasetId)) {
        final download = _downloads[datasetId]!;
        _downloads[datasetId] = download.copyWith(size: 'Starting...');
        notifyListeners();
      }

      _currentDownloadDatasetId = datasetId;

      try {
        final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
        final userApiHive = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

        final userApi = userApiHive.getAt(0);
        final kaggleUsername = userApi?.kaggleUserName ?? '';
        final kaggleKey = userApi?.kaggleApiKey ?? '';

        if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
          _updateDownloadWithError(
            datasetId,
            'Kaggle credentials not found. Please update them in settings.',
          );
          _downloadQueue.removeFirst();
          continue;
        }

        final downloadPath = hiveBox.get('selectedRootDirectoryPath');

        if (downloadPath == null || downloadPath.isEmpty) {
          _updateDownloadWithError(
            datasetId,
            'Download path not set. Please set it in settings.',
          );
          _downloadQueue.removeFirst();
          continue;
        }

        await _startDownload(
          datasetId: datasetId,
          source: downloadInfo['source'],
          path: downloadPath,
          unzip: downloadInfo['unzip'],
          kaggleUsername: kaggleUsername,
          kaggleKey: kaggleKey,
        );

        await _waitForDownloadCompletion();
      } catch (e) {
        _updateDownloadWithError(
          datasetId,
          'Failed to start download: ${e.toString()}',
        );
      }

      _downloadQueue.removeFirst();
    }

    _isProcessingQueue = false;
  }

  /// Waits for the current download to complete or fail.
  ///
  /// @returns A Future that completes when the download is finished.
  Future<void> _waitForDownloadCompletion() {
    final completer = Completer<void>();

    if (!_isConnected) {
      completer.complete();
      return completer.future;
    }

    late StreamSubscription subscription;
    subscription = stream.listen(
      (event) {},
      onDone: () {
        subscription.cancel();
        completer.complete();
      },
      onError: (error) {
        subscription.cancel();
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  /// Initiates a dataset download.
  ///
  /// @param source The source platform for the dataset.
  /// @param datasetId The ID of the dataset to download.
  /// @param unzip Whether to automatically unzip the downloaded dataset.
  Future<void> downloadDataset({
    required String source,
    required String datasetId,
    bool unzip = false,
  }) async {
    if (isDownloading) {
      throw Exception('A download is already in progress');
    }

    _currentDownloadDatasetId = datasetId;

    final fileName = datasetId.split('/').last;

    final initialDownload = DownloadItem(
      name: fileName,
      datasetId: datasetId,
      size: 'Queued...',
      timeStarted: DateTime.now(),
      progress: 0.0,
      isComplete: false,
      source: source,
    );

    _downloads[datasetId] = initialDownload;
    notifyListeners();

    _downloadQueue.add({
      'source': source,
      'datasetId': datasetId,
      'unzip': unzip,
    });

    if (!_isProcessingQueue) {
      _processQueue();
    }

    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
      final userApiHive = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

      final userApi = userApiHive.getAt(0);
      final kaggleUsername = userApi?.kaggleUserName ?? '';
      final kaggleKey = userApi?.kaggleApiKey ?? '';

      if (kaggleUsername.isEmpty || kaggleKey.isEmpty) {
        _updateDownloadWithError(
          datasetId,
          'Kaggle credentials not found. Please update them in settings.',
        );
        return;
      }

      final downloadPath = hiveBox.get('selectedRootDirectoryPath');

      if (downloadPath == null || downloadPath.isEmpty) {
        _updateDownloadWithError(
          datasetId,
          'Download path not set. Please set it in settings.',
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
      _updateDownloadWithError(
        datasetId,
        'Failed to start download: ${e.toString()}',
      );
    }
  }

  /// Starts the actual download process by making an API request.
  ///
  /// @param datasetId The ID of the dataset to download.
  /// @param source The source platform for the dataset.
  /// @param path The local path to save the downloaded dataset.
  /// @param unzip Whether to automatically unzip the downloaded dataset.
  /// @param kaggleUsername Kaggle username for authentication.
  /// @param kaggleKey Kaggle API key for authentication.
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

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

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

  /// Processes Server-Sent Events (SSE) updates for download progress.
  ///
  /// @param jsonData The JSON data received from the server.
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
      // final message = data['message'] ?? 'Downloading...';

      String size = '0 B';
      if (bytesDownloaded > 0) {
        if (bytesDownloaded < 1024) {
          size = '$bytesDownloaded B';
        } else if (bytesDownloaded < 1024 * 1024) {
          size = '${(bytesDownloaded / 1024).toStringAsFixed(1)} KB';
        } else if (bytesDownloaded < 1024 * 1024 * 1024) {
          size = '${(bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          size =
              '${(bytesDownloaded / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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

  /// Updates a download with error information.
  ///
  /// @param datasetId The ID of the dataset that encountered an error.
  /// @param errorMessage The error message to display.
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

  /// Cleans up resources after a download completes or fails.
  void _cleanupDownload() {
    _currentDownloadDatasetId = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _isConnected = false;
    notifyListeners();
  }

  /// Cleans up resources when the service is disposed.
  @override
  void dispose() {
    _sseSubscription?.cancel();
    _downloadStreamController.close();
    super.dispose();
  }
}
