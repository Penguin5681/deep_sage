import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service class that manages the application's cache.
///
/// Provides functionality to:
/// - Monitor and calculate cache size across different storage areas
/// - Clear specific cache types or all caches
/// - Present UI for selective cache clearing
class CacheService {
  /// Notifies listeners about the total cache size in megabytes.
  final ValueNotifier<double> totalCacheSizeInMB = ValueNotifier(0.0);

  /// Notifies listeners about detailed cache sizes organized by storage type.
  /// Keys represent cache types (e.g., 'Hive Storage'), values are sizes in MB.
  final ValueNotifier<Map<String, double>> detailedCacheSizes = ValueNotifier(
    {},
  );

  /// Calculates the size of various cache types and updates the ValueNotifiers.
  ///
  /// This method measures cache sizes from:
  /// - Application support directory (Hive storage)
  /// - Shared preferences
  /// - Dataset directory (if configured)
  ///
  /// All size calculations are updated in the [totalCacheSizeInMB] and
  /// [detailedCacheSizes] value notifiers.
  Future<void> calculateCacheSize() async {
    try {
      Map<String, double> cacheSizes = {};
      double totalSize = 0.0;

      final appSupportDirectory = await getApplicationSupportDirectory();
      final appSupportSize = await _calculateDirectorySize(appSupportDirectory);
      cacheSizes['Hive Storage'] = appSupportSize / (1024 * 1024);
      totalSize += appSupportSize;

      final sharedPrefsSize = await _calculateSharedPreferencesSize();
      cacheSizes['Shared Preferences'] = sharedPrefsSize / (1024 * 1024);
      totalSize += sharedPrefsSize;

      try {
        // final directoryPathService = DirectoryPathService();
        final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
        final savedPath = hiveBox.get('selectedRootDirectoryPath');
        if (savedPath.isNotEmpty) {
          final rootDir = Directory(savedPath);
          if (await rootDir.exists()) {
            final datasetsSize = await _calculateDirectorySize(rootDir);
            cacheSizes['Datasets'] = datasetsSize / (1024 * 1024);
          }
        }
      } catch (e) {
        debugPrint('Error calculating dataset size: $e');
      }

      // Update value notifiers
      detailedCacheSizes.value = cacheSizes;
      totalCacheSizeInMB.value = totalSize / (1024 * 1024);
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
    }
  }

  /// Calculates the size of a directory in bytes.
  ///
  /// Recursively traverses all files in the provided [directory]
  /// and sums their sizes.
  ///
  /// Returns the total size in bytes, or 0 if the directory doesn't exist
  /// or an error occurs.
  Future<double> _calculateDirectorySize(Directory directory) async {
    try {
      double totalSize = 0;
      if (await directory.exists()) {
        await for (var entity in directory.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
      return 0;
    }
  }

  /// Calculates the size of shared preferences storage.
  ///
  /// This method approximates the storage size by estimating the memory
  /// footprint of each preference value:
  /// - Strings: actual length in bytes
  /// - Booleans: 1 byte
  /// - Integers/Doubles: 8 bytes
  /// - String lists: sum of string lengths
  ///
  /// Returns the total estimated size in bytes, or 0 if an error occurs.
  Future<double> _calculateSharedPreferencesSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      double totalSize = 0;

      for (var key in keys) {
        var value = prefs.get(key);
        if (value != null) {
          if (value is String) {
            totalSize += value.length;
          } else if (value is bool) {
            totalSize += 1;
          } else if (value is int) {
            totalSize += 8;
          } else if (value is double) {
            totalSize += 8;
          } else if (value is List<String>) {
            for (var item in value) {
              totalSize += item.length;
            }
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating shared preferences size: $e');
      return 0;
    }
  }

  /// Clears all application caches.
  ///
  /// This method clears:
  /// - App support directory (Hive storage)
  /// - Shared preferences
  /// - Flutter's image cache
  ///
  /// After clearing, recalculates the cache size to update the
  /// value notifiers.
  Future<void> clearAllCaches() async {
    await clearAppSupportCache();
    await clearSharedPreferences();
    await _clearImageCache();
    await calculateCacheSize();
  }

  /// Clears the app support directory cache (Hive storage).
  ///
  /// Deletes all files and directories in the app support directory
  /// where Hive data is typically stored.
  Future<void> clearAppSupportCache() async {
    try {
      final appSupportDirectory = await getApplicationSupportDirectory();
      final dir = Directory(appSupportDirectory.path);

      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing app support cache: $e');
    }
  }

  /// Clears all shared preferences.
  ///
  /// This will remove all key-value pairs stored in the app's
  /// shared preferences.
  Future<void> clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing shared preferences: $e');
    }
  }

  /// Clears Flutter's in-memory image cache.
  ///
  /// This removes both the live images currently being displayed
  /// and the cached images stored in memory.
  Future<void> _clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Clears the datasets directory.
  ///
  /// Removes all files and directories in the configured datasets path.
  /// Does nothing if no path is configured or the directory doesn't exist.
  Future<void> _clearDatasets() async {
    try {
      final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
      final savedPath = hiveBox.get('selectedRootDirectoryPath');
      if (savedPath.isNotEmpty) {
        final rootDir = Directory(savedPath);
        if (await rootDir.exists()) {
          await for (var entity in rootDir.list()) {
            if (entity is Directory) {
              await entity.delete(recursive: true);
            } else if (entity is File) {
              await entity.delete();
            }
          }
        }
      } else {
        debugPrint('Now Here in else');
      }
    } catch (e) {
      debugPrint('Error clearing datasets: $e');
    }
  }

  /// Displays a dialog that allows the user to selectively clear different types of cache.
  ///
  /// The dialog includes options to clear:
  /// - Hive Storage (app data and settings)
  /// - Shared Preferences (app preferences)
  /// - Image Cache (temporary image files)
  /// - Datasets (downloaded datasets)
  ///
  /// The dialog also provides an option to 'Select All' and indicates if the app
  /// will need to restart after clearing.
  ///
  /// Returns a [Future] that resolves to a map with two boolean values:
  /// - 'shouldRestart': true if clearing Hive or Shared Preferences was selected, otherwise false.
  /// - 'didClearCache': true if any cache clearing action was performed, otherwise false.

  Future<Map<String, bool>> showCacheClearDialog(BuildContext context) async {
    bool shouldRestart = false;
    bool clearHive = false;
    bool clearSharedPrefs = false;
    bool clearImageCache = false;
    bool clearDatasets = false;
    bool didClearCache = false;
    bool selectAll = false;

    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Color(0xFF252525);
    final cardColor = Color(0xFF303030);
    final textColor = Colors.white;
    final subtitleColor = Colors.grey[400];

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              void updateAllCheckboxes(bool value) {
                setState(() {
                  selectAll = value;
                  clearHive = value;
                  clearSharedPrefs = value;
                  clearImageCache = value;
                  clearDatasets = value;
                  if (value) shouldRestart = true;
                });
              }

              return AlertDialog(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                // Add constraints to limit width
                insetPadding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.cleaning_services_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Clear Cache',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Free up space by removing cached data',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          'Select All',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        value: selectAll,
                        onChanged:
                            (value) => updateAllCheckboxes(value ?? false),
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildCompactCacheItem(
                      setState,
                      title: 'Hive Storage',
                      subtitle: 'App data and settings',
                      icon: Icons.storage_rounded,
                      isChecked: clearHive,
                      size:
                          '${detailedCacheSizes.value['Hive Storage']?.toStringAsFixed(2) ?? "0.00"} MB',
                      onChanged: (value) {
                        setState(() {
                          clearHive = value ?? false;
                          if (clearHive) shouldRestart = true;
                          selectAll = _areAllSelected(
                            clearHive,
                            clearSharedPrefs,
                            clearImageCache,
                            clearDatasets,
                          );
                        });
                      },
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                    ),
                    _buildCompactCacheItem(
                      setState,
                      title: 'Shared Preferences',
                      subtitle: 'App preferences',
                      icon: Icons.settings_rounded,
                      isChecked: clearSharedPrefs,
                      size:
                          '${detailedCacheSizes.value['Shared Preferences']?.toStringAsFixed(2) ?? "0.00"} MB',
                      onChanged: (value) {
                        setState(() {
                          clearSharedPrefs = value ?? false;
                          if (clearSharedPrefs) shouldRestart = true;
                          selectAll = _areAllSelected(
                            clearHive,
                            clearSharedPrefs,
                            clearImageCache,
                            clearDatasets,
                          );
                        });
                      },
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                    ),
                    _buildCompactCacheItem(
                      setState,
                      title: 'Image Cache',
                      subtitle: 'Temporary image files',
                      icon: Icons.image_rounded,
                      isChecked: clearImageCache,
                      size: '0.00 MB',
                      onChanged: (value) {
                        setState(() {
                          clearImageCache = value ?? false;
                          selectAll = _areAllSelected(
                            clearHive,
                            clearSharedPrefs,
                            clearImageCache,
                            clearDatasets,
                          );
                        });
                      },
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                    ),
                    _buildCompactCacheItem(
                      setState,
                      title: 'Datasets',
                      subtitle: 'Downloaded datasets',
                      icon: Icons.folder_rounded,
                      isChecked: clearDatasets,
                      size:
                          '${detailedCacheSizes.value['Datasets']?.toStringAsFixed(2) ?? "0.00"} MB',
                      onChanged: (value) {
                        setState(() {
                          clearDatasets = value ?? false;
                          selectAll = _areAllSelected(
                            clearHive,
                            clearSharedPrefs,
                            clearImageCache,
                            clearDatasets,
                          );
                        });
                      },
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                    ),
                    if (clearHive || clearSharedPrefs)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[900]!.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber[700]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber[900]!.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.restart_alt_rounded,
                                  color: Colors.amber[300],
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'App will restart after clearing',
                                  style: TextStyle(
                                    color: Colors.amber[200],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        (!clearHive &&
                                !clearSharedPrefs &&
                                !clearImageCache &&
                                !clearDatasets)
                            ? null
                            : () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => AlertDialog(
                                      backgroundColor: backgroundColor,
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(
                                            color: primaryColor,
                                          ),
                                          SizedBox(width: 20),
                                          Text(
                                            'Clearing cache...',
                                            style: TextStyle(color: textColor),
                                          ),
                                        ],
                                      ),
                                    ),
                              );

                              if (clearHive) await clearAppSupportCache();
                              if (clearSharedPrefs) {
                                await clearSharedPreferences();
                              }
                              if (clearImageCache) await _clearImageCache();
                              if (clearDatasets) await _clearDatasets();

                              await calculateCacheSize();

                              didClearCache = true;

                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[700]?.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
                actionsPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              );
            },
          ),
    );

    return {'shouldRestart': shouldRestart, 'didClearCache': didClearCache};
  }

  /// Builds a compact cache item widget for the cache clearing dialog.
  ///
  /// This widget represents a single cache item with a checkbox, title, subtitle,
  /// icon, and size information. It's used within the cache clearing dialog to allow
  /// users to selectively choose which cache types to clear.
  ///
  /// Parameters:
  ///   - [setState]: The state setter function to update the parent widget's state.
  ///   - [title]: The title of the cache item (e.g., 'Hive Storage').
  ///   - [subtitle]: The subtitle providing a brief description (e.g., 'App data and settings').
  ///   - [icon]: The icon to display for this cache type.
  ///   - [isChecked]: Whether the checkbox is currently checked.
  ///   - [size]: The size of the cache in a formatted string (e.g., '10.50 MB').
  ///   - [onChanged]: Callback function triggered when the checkbox's state changes.
  ///   - [textColor]: The color of the title text.
  ///   - [subtitleColor]: The color of the subtitle text.
  ///   - [primaryColor]: The primary color of the app, used for active elements.
  ///   - [cardColor]: The background color of the cache item card.
  ///
  /// Returns:
  ///   - A [Widget] that represents a single cache item in the dialog.
  ///
  /// Example:
  ///   _buildCompactCacheItem(setState, title: 'Hive Storage', subtitle: 'App data',
  ///     icon: Icons.storage, isChecked: true, size: '50.00 MB', onChanged: (value) {...},
  ///     textColor: Colors.white, subtitleColor: Colors.grey, primaryColor: Colors.blue, cardColor: Colors.grey[800]!);
  Widget _buildCompactCacheItem(
    StateSetter setState, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isChecked,
    required String size,
    required Function(bool?) onChanged,
    required Color textColor,
    required Color? subtitleColor,
    required Color primaryColor,
    required Color cardColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: CheckboxListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        isChecked
                            ? primaryColor.withValues(alpha: 0.15)
                            : Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isChecked ? primaryColor : Colors.grey[400],
                    size: 16,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        value: isChecked,
        onChanged: onChanged,
        activeColor: primaryColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  /// Determines if all cache clearing checkboxes are selected.
  ///
  /// This helper function checks the state of the Hive, Shared Preferences, Image Cache,
  /// and Datasets checkboxes to determine if all are selected.
  ///
  /// Parameters:
  ///   - [clearHive]: Whether the Hive storage checkbox is checked.
  ///   - [clearSharedPrefs]: Whether the Shared Preferences checkbox is checked.
  ///   - [clearImageCache]: Whether the Image Cache checkbox is checked.
  ///   - [clearDatasets]: Whether the Datasets checkbox is checked.
  ///
  /// Returns:
  ///   - [bool]: True if all checkboxes are checked, false otherwise.
  bool _areAllSelected(
    bool clearHive,
    bool clearSharedPrefs,
    bool clearImageCache,
    bool clearDatasets,
  ) {
    return clearHive && clearSharedPrefs && clearImageCache && clearDatasets;
  }
}
