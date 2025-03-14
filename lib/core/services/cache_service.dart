import 'package:hive_flutter/adapters.dart';

/// A singleton service that handles caching operations using Hive.
///
/// This service manages four types of caches:
/// - Dataset cache for storing dataset data
/// - Recent datasets cache for tracking recently opened datasets
/// - Search result cache for storing search query results
/// - Analysis result cache for storing dataset analysis results
class CacheService {
  static final CacheService _instance = CacheService._internal();

  /// Factory constructor that returns the singleton instance
  factory CacheService() => _instance;

  /// Private constructor used for singleton pattern
  CacheService._internal();

  /// Box name for storing dataset cache data
  static const String datasetCacheBox = 'dataset_cache';

  /// Box name for storing recent datasets
  static const String recentDatasetCacheBox = 'recent_datasets';

  /// Box name for storing search results
  static const String searchResultBox = 'search_result_cache';

  /// Box name for storing analysis results
  static const String analysisResulBox = 'analysis_results';

  /// Box instance for dataset cache
  late Box _datasetBox;

  /// Box instance for recent datasets
  late Box _recentDatasetsBox;

  /// Box instance for search results
  late Box _searchResultsBox;

  /// Box instance for analysis results
  late Box _analysisResultBox;

  /// Flag indicating if the service has been initialized
  bool _isInitialized = false;

  /// Initializes all Hive boxes required for caching.
  ///
  /// This method must be called before using any other methods of this service.
  /// If already initialized, it will return immediately.
  Future<void> initCacheBox() async {
    if (_isInitialized) return;

    await Hive.openBox(datasetCacheBox);
    await Hive.openBox(recentDatasetCacheBox);
    await Hive.openBox(searchResultBox);
    await Hive.openBox(analysisResulBox);

    _isInitialized = true;
  }

  /// Stores dataset data in the cache.
  ///
  /// [path] The file path that serves as the unique key for the dataset
  /// [data] The dataset data to cache
  Future<void> cacheDataset(String path, Map<String, dynamic> data) async {
    await _datasetBox.put(path, {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieves cached dataset data if available and not expired.
  ///
  /// [path] The file path that serves as the unique key for the dataset
  ///
  /// Returns the cached dataset data if available and not older than 1 hour,
  /// otherwise returns null.
  Future<Map<String, dynamic>?> getCacheDataset(String path) async {
    final cachedData = _datasetBox.get(path);

    if (cachedData != null) {
      final timeStamp = DateTime.parse(cachedData['timestamp']);
      if (DateTime.now().difference(timeStamp).inHours < 1) {
        return cachedData['data'];
      }
    }
    return null;
  }

  /// Adds or updates a dataset in the recent datasets list.
  ///
  /// [path] The file path of the dataset
  /// [name] The name of the dataset
  /// [type] The type of the dataset
  /// [size] The size of the dataset
  ///
  /// This method maintains a list of the 10 most recently opened datasets.
  Future<void> addRecentDataset(
    String path,
    String name,
    String type,
    String size,
  ) async {
    List<Map<String, dynamic>> recent = _recentDatasetsBox.get(
      'recent',
      defaultValue: [],
    );

    final existingIndex = recent.indexWhere((item) => item['path'] == path);
    if (existingIndex != -1) {
      recent.removeAt(existingIndex);
    }

    recent.insert(0, {
      'path': path,
      'name': name,
      'type': type,
      'size': size,
      'lastOpened': DateTime.now().toIso8601String(),
    });

    if (recent.length > 10) {
      recent = recent.sublist(0, 10);
    }
    await _recentDatasetsBox.put('recent', recent);
  }

  /// Retrieves the list of recently opened datasets.
  ///
  /// Returns a list of maps containing information about recently opened datasets.
  Future<List<Map<String, dynamic>>> getRecentDatasets() async {
    return List<Map<String, dynamic>>.from(
      _recentDatasetsBox.get('recent', defaultValue: []),
    );
  }

  /// Caches search results for a specific query and category.
  ///
  /// [query] The search query string
  /// [category] The category of the search
  /// [results] The search results to cache
  Future<void> cacheSearchResults(
    String query,
    String category,
    List<dynamic> results,
  ) async {
    final cacheKey = '${query}_$category';
    await _searchResultsBox.put(cacheKey, {
      'results': results,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieves cached search results if available and not expired.
  ///
  /// [query] The search query string
  /// [category] The category of the search
  ///
  /// Returns the cached search results if available and not older than 30 minutes,
  /// otherwise returns null.
  Future<List<dynamic>?> getCachedSearchResults(
    String query,
    String category,
  ) async {
    final cacheKey = '${query}_$category';
    final cachedData = _searchResultsBox.get(cacheKey);

    if (cachedData != null) {
      final timestamp = DateTime.parse(cachedData['timestamp']);
      if (DateTime.now().difference(timestamp).inMinutes < 30) {
        return cachedData['results'];
      }
    }
    return null;
  }

  /// Caches analysis results for a specific dataset.
  ///
  /// [datasetPath] The path of the dataset that was analyzed
  /// [result] The analysis result to cache
  Future<void> cacheAnalysisResult(
    String datasetPath,
    Map<String, dynamic> result,
  ) async {
    await _analysisResultBox.put(datasetPath, {
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieves cached analysis results if available and not expired.
  ///
  /// [datasetPath] The path of the dataset that was analyzed
  ///
  /// Returns the cached analysis results if available and not older than 24 hours,
  /// otherwise returns null.
  Future<Map<String, dynamic>?> getCachedAnalysis(String datasetPath) async {
    final cachedData = _analysisResultBox.get(datasetPath);

    if (cachedData != null) {
      final timestamp = DateTime.parse(cachedData['timestamp']);
      if (DateTime.now().difference(timestamp).inHours < 24) {
        return cachedData['results'];
      }
    }
    return null;
  }

  /// Clears the cache for a specific box.
  ///
  /// [boxName] The name of the box to clear
  Future<void> clearCache(String boxName) async {
    final box = Hive.box(boxName);
    box.clear();
  }

  /// Clears all caches except for recent datasets.
  Future<void> clearAllCache() async {
    await clearCache(datasetCacheBox);
    await clearCache(searchResultBox);
    await clearCache(analysisResulBox);
  }
}
