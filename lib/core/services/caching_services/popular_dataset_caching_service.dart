import 'package:flutter/foundation.dart';
import 'package:deep_sage/core/config/api_config/popular_datasets.dart';

/// A service that provides in-memory caching of popular datasets during app lifecycle.
///
/// The cached data persists only while the app is running and is cleared when
/// the app is terminated.
class PopularDatasetCachingService {
  // Singleton instance
  static final PopularDatasetCachingService _instance = PopularDatasetCachingService._internal();

  // Factory constructor to return the singleton instance
  factory PopularDatasetCachingService() => _instance;

  // Private constructor
  PopularDatasetCachingService._internal();

  // Cache storage for different categories and sort parameters
  final Map<String, List<PopularDataset>> _cachedDatasets = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache validity duration - 15 minutes
  final Duration _cacheValidity = const Duration(minutes: 15);

  /// Gets datasets from cache if available and still valid
  List<PopularDataset>? getCachedDatasets(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    final datasets = _cachedDatasets[cacheKey];

    if (datasets == null || timestamp == null) return null;

    // Check if cache has expired
    if (DateTime.now().difference(timestamp) > _cacheValidity) {
      clearCache(cacheKey);
      return null;
    }

    debugPrint('Using cached data for: $cacheKey');
    return datasets;
  }

  /// Stores datasets in cache
  void cacheDatasets(String cacheKey, List<PopularDataset> datasets) {
    _cachedDatasets[cacheKey] = datasets;
    _cacheTimestamps[cacheKey] = DateTime.now();
    debugPrint('Cached data for: $cacheKey');
  }

  /// Clears cache for specific key
  void clearCache(String cacheKey) {
    _cachedDatasets.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  /// Clears all cached data
  void clearAllCache() {
    _cachedDatasets.clear();
    _cacheTimestamps.clear();
    debugPrint('Cleared all dataset cache');
  }
}