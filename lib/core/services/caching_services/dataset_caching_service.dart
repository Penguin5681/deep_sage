import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;

import '../core_services/data_preview_service.dart';

class DatasetCachingService {
  /// Service responsible for fetching and creating dataset previews.
  final DataPreviewService _previewService = DataPreviewService();

  /// Cache to store the dataset previews.
  /// Key: file path of the dataset.
  /// Value: a map containing the dataset preview.
  final Map<String, Map<String, dynamic>> _cachedPreviews = {};

  /// Queue to manage the order in which datasets should be cached.
  final List<String> _cachingQueue = [];

  /// Flag indicating whether the caching process is currently running.
  bool _isCaching = false;

  /// The maximum number of entries to keep in the cache.
  static const int maxCacheEntries = 5;

  /// The number of rows to load for the dataset preview.
  static const int preloadRowCount = 10;

  /// The delay between processing items in the caching queue.
  static const Duration cachingDelay = Duration(milliseconds: 200);

  /// Adds a dataset to the caching queue.
  ///
  /// This method checks if the dataset is already cached or in the queue before adding it.
  /// It then starts the caching process if it's not already running.
  ///
  /// Args:
  ///   filePath (String): The path to the dataset file.
  ///   fileType (String): The type of the dataset file (e.g., 'csv', 'json').
  void queueForCaching(String filePath, String fileType) {
    if (_cachedPreviews.containsKey(filePath) ||
        _cachingQueue.contains(filePath)) {
      return;
    }
    _cachingQueue.add(filePath);
    _startCachingIfNeeded();
  }

  /// Starts the caching process if it's not already running and there are items in the queue.
  ///
  /// This is a private method that sets the [_isCaching] flag to true and starts processing
  /// the queue by calling [_processCachingQueue].
  ///
  /// It will do nothing if:
  ///   1. [_isCaching] is true
  ///   2. [_cachingQueue] is empty.
  void _startCachingIfNeeded() {
    if (_isCaching || _cachingQueue.isEmpty) return;

    _isCaching = true;
    _processCachingQueue();
  }

  /// Processes the caching queue by loading dataset previews.
  ///
  /// This method is called recursively to process each item in the queue.
  /// It fetches the next item from the queue, loads its preview using [_previewService],
  /// caches the preview, and then removes it from the queue.
  ///
  /// If an error occurs while processing a dataset, it prints an error message.
  ///
  /// After processing the current item, it calls itself again to continue processing the queue.
  /// Once the queue is empty, it sets [_isCaching] to false, indicating that the caching process
  /// has finished.
  Future<void> _processCachingQueue() async {
    debugPrint('_processCachingQueue()');
    if (_cachingQueue.isEmpty) {
      _isCaching = false;
      return;
    }
    final filePath = _cachingQueue.removeAt(0);

    try {
      final fileType = path.extension(filePath).replaceFirst('.', '');

      await Future.delayed(cachingDelay);

      final preview = await _previewService.loadDatasetPreview(
        filePath,
        fileType,
        preloadRowCount,
      );

      if (preview != null) {
        _cachedPreviews[filePath] = preview;

        _trimCacheIfNeeded();
      }
    } catch (e) {
      debugPrint('Error caching dataset preview: $e');
    }

    _processCachingQueue();
  }

  /// Removes entries from the cache if it exceeds [maxCacheEntries].
  ///
  /// This method is called after caching a new preview. It checks if the cache size
  /// exceeds [maxCacheEntries], and if so, removes the oldest entries until the cache
  /// size is equal to [maxCacheEntries].
  void _trimCacheIfNeeded() {
    if (_cachedPreviews.length <= maxCacheEntries) return;

    final entriesToRemove = _cachedPreviews.length - maxCacheEntries;
    final keys = _cachedPreviews.keys.toList();

    for (var i = 0; i < entriesToRemove; i++) {
      _cachedPreviews.remove(keys[i]);
    }
  }

  /// Retrieves a cached dataset preview.
  ///
  /// If the preview for the given [filePath] is cached, it returns the cached preview.
  /// Otherwise, it returns null.
  ///
  /// Args:
  ///   filePath (String): The path to the dataset file.
  Map<String, dynamic>? getCachedPreview(String filePath) {
    return _cachedPreviews[filePath];
  }

  /// Checks if a dataset preview is cached.
  ///
  /// This method checks whether a preview for the specified [filePath] is currently
  /// in the cache.
  ///
  /// Args:
  ///   filePath (String): The path to the dataset file.
  bool isPreviewCached(String filePath) {
    return _cachedPreviews.containsKey(filePath);
  }
}
