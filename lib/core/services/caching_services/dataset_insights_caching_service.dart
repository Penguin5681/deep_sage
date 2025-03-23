import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// A service for caching and retrieving dataset insights data.
/// This service provides functionality to store and retrieve analysis results
/// from both in-memory cache and persistent storage using SharedPreferences.
class DatasetInsightsCachingService {
  /// In-memory cache for quick access to insights data
  /// Map structure: {cacheKey: insightsData}
  static final Map<String, Map<String, dynamic>> _insightsCache = {};

  /// Prefix used for all SharedPreferences keys related to dataset insights
  static const String _keyPrefix = 'dataset_insights_';

  /// Generates a unique cache key based on file path and last modification timestamp
  ///
  /// This ensures the cache is invalidated when the file is modified
  ///
  /// @param filePath Path to the dataset file
  /// @return A unique string key combining filename and modification timestamp
  String _generateCacheKey(String filePath) {
    final fileName = path.basename(filePath);
    final fileStats = File(filePath).statSync();
    final lastModified = fileStats.modified.millisecondsSinceEpoch.toString();
    return '$fileName-$lastModified';
  }

  /// Creates the full SharedPreferences key by adding the prefix
  ///
  /// @param cacheKey The cache key to be prefixed
  /// @return The complete SharedPreferences key
  String _getPrefKey(String cacheKey) {
    return '$_keyPrefix$cacheKey';
  }

  /// Retrieves cached insights for a specific file
  ///
  /// First checks the in-memory cache, then falls back to SharedPreferences
  /// if not found in memory. Deserializes JSON data and converts dynamic maps
  /// to string-keyed maps when necessary.
  ///
  /// @param filePath Path to the dataset file
  /// @return The cached insights data, or null if not found or on error
  Future<Map<String, dynamic>?> getCachedInsights(String filePath) async {
    final cacheKey = _generateCacheKey(filePath);

    if (_insightsCache.containsKey(cacheKey)) {
      return _insightsCache[cacheKey];
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getPrefKey(cacheKey));

    if (jsonString != null) {
      try {
        final decodedJson = json.decode(jsonString);

        final Map<String, dynamic> cachedData =
            decodedJson is Map<String, dynamic>
                ? decodedJson
                : _convertMapToStringKeys(decodedJson as Map<dynamic, dynamic>);

        _insightsCache[cacheKey] = cachedData;
        return cachedData;
      } catch (e) {
        debugPrint('Error decoding cached insights: $e');
        return null;
      }
    }

    return null;
  }

  /// Stores insights data for a specific file in both memory and SharedPreferences
  ///
  /// Serializes the insights map to JSON before storing in SharedPreferences
  ///
  /// @param filePath Path to the dataset file
  /// @param insights The insights data to cache
  Future<void> cacheInsights(String filePath, Map<String, dynamic> insights) async {
    final cacheKey = _generateCacheKey(filePath);

    _insightsCache[cacheKey] = insights;

    try {
      final jsonString = json.encode(insights);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getPrefKey(cacheKey), jsonString);
    } catch (e) {
      debugPrint('Error caching insights: $e');
    }
  }

  /// Recursively converts a map with dynamic keys to one with string keys
  ///
  /// This is needed because JSON deserialization may produce maps with dynamic keys
  /// which need to be normalized to string keys for consistent handling
  ///
  /// @param map The map with dynamic keys to convert
  /// @return A new map with all keys converted to strings
  Map<String, dynamic> _convertMapToStringKeys(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (value is Map<dynamic, dynamic>) {
        return MapEntry(key.toString(), _convertMapToStringKeys(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _convertListItems(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }

  /// Recursively processes list items to convert any nested maps to have string keys
  ///
  /// @param list The list to process
  /// @return A new list with all nested maps converted to have string keys
  dynamic _convertListItems(List list) {
    return list.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertMapToStringKeys(item);
      } else if (item is List) {
        return _convertListItems(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Clears the cached insights for a specific file
  ///
  /// Removes the insights from both in-memory cache and SharedPreferences
  ///
  /// @param filePath Path to the dataset file
  Future<void> clearInsightsCache(String filePath) async {
    final cacheKey = _generateCacheKey(filePath);
    _insightsCache.remove(cacheKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getPrefKey(cacheKey));
  }

  /// Clears all cached insights data
  ///
  /// Removes all insights from both in-memory cache and SharedPreferences
  Future<void> clearAllInsightsCache() async {
    _insightsCache.clear();

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final insightKeys = allKeys.where((key) => key.startsWith(_keyPrefix));

    for (final key in insightKeys) {
      await prefs.remove(key);
    }
  }
}
