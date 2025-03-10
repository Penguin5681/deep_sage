import 'package:hive_flutter/adapters.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() => _instance;

  CacheService._internal();

  static const String datasetCacheBox = 'dataset_cache';
  static const String recentDatasetCacheBox = 'recent_datasets';
  static const String searchResultBox = 'search_result_cache';
  static const String analysisResulBox = 'analysis_results';

  late Box _datasetBox;
  late Box _recentDatasetsBox;
  late Box _searchResultsBox;
  late Box _analysisResultBox;
  bool _isInitialized = false;

  Future<void> initCacheBox() async {
    if (_isInitialized) return;

    await Hive.openBox(datasetCacheBox);
    await Hive.openBox(recentDatasetCacheBox);
    await Hive.openBox(searchResultBox);
    await Hive.openBox(analysisResulBox);

    _isInitialized = true;
  }

  Future<void> cacheDataset(String path, Map<String, dynamic> data) async {
    await _datasetBox.put(path, {'data': data, 'timestamp': DateTime.now().toIso8601String()});
  }

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

  Future<void> addRecentDataset(String path, String name, String type, String size) async {
    List<Map<String, dynamic>> recent = _recentDatasetsBox.get('recent', defaultValue: []);

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

  Future<List<Map<String, dynamic>>> getRecentDatasets() async {
    return List<Map<String, dynamic>>.from(_recentDatasetsBox.get('recent', defaultValue: []));
  }

  Future<void> cacheSearchResults(String query, String category, List<dynamic> results) async {
    final cacheKey = '${query}_$category';
    await _searchResultsBox.put(cacheKey, {
      'results': results,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<dynamic>?> getCachedSearchResults(String query, String category) async {
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

  Future<void> cacheAnalysisResult(String datasetPath, Map<String, dynamic> result) async {
    await _analysisResultBox.put(datasetPath, {
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

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

  Future<void> clearCache(String boxName) async {
    final box = Hive.box(boxName);
    box.clear();
  }

  Future<void> clearAllCache() async {
    await clearCache(datasetCacheBox);
    await clearCache(searchResultBox);
    await clearCache(analysisResulBox);
  }
}
