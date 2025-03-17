import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;

/// A utility class that provides file transfer functionality.
///
/// This class contains static methods to move files from one location to another
/// while handling file name conflicts and preserving starred status.
class FileTransferUtil {
  /// Moves files from source paths to a destination directory.
  ///
  /// Takes a list of source file paths and moves them to the specified destination
  /// directory. Returns a list of the new file paths after the move operation.
  ///
  /// Parameters:
  /// - [sourcePaths]: List of file paths to be moved.
  /// - [destinationDirectory]: Target directory where files will be moved.
  /// - [createDestinationIfMissing]: Creates the destination directory if it doesn't exist (default: true).
  /// - [overwriteExisting]: Overwrites existing files in the destination (default: false).
  ///
  /// Returns:
  /// A [Future] that completes with a list of new file paths after the move operation.
  ///
  /// Throws:
  /// - [Exception] if the destination directory cannot be created.
  static Future<List<String>> moveFiles({
    required List<String> sourcePaths,
    required String destinationDirectory,
    bool createDestinationIfMissing = true,
    bool overwriteExisting = false,
  }) async {
    List<String> newFilePaths = [];
    final destinationDir = Directory(destinationDirectory);
    final starredBox = Hive.box('starred_datasets');

    if (!await destinationDir.exists() && createDestinationIfMissing) {
      try {
        await destinationDir.create(recursive: true);
      } catch (e) {
        throw Exception('Failed to create destination directory: $e');
      }
    }

    for (String sourcePath in sourcePaths) {
      try {
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          debugPrint('Source file does not exist: $sourcePath');
          continue;
        }

        final fileName = path.basename(sourcePath);
        final destinationPath = path.join(destinationDirectory, fileName);
        final destinationFile = File(destinationPath);

        bool isStarred = starredBox.get(sourcePath, defaultValue: false);

        if (await destinationFile.exists()) {
          if (overwriteExisting) {
            await destinationFile.delete();
          } else {
            String newFileName = await _getUniqueFileName(
              destinationDirectory,
              fileName,
            );
            final uniqueDestinationPath = path.join(
              destinationDirectory,
              newFileName,
            );

            await sourceFile.copy(uniqueDestinationPath);
            try {
              await sourceFile.delete();
            } catch (e) {
              debugPrint('Warning: Could not delete original file: $e');
            }

            if (isStarred) {
              await starredBox.delete(sourcePath);
              await starredBox.put(uniqueDestinationPath, true);
            }

            newFilePaths.add(uniqueDestinationPath);
            continue;
          }
        }

        await sourceFile.copy(destinationPath);
        try {
          await sourceFile.delete();
        } catch (e) {
          debugPrint('Warning: Could not delete original file: $e');
        }

        if (isStarred) {
          await starredBox.delete(sourcePath);
          await starredBox.put(destinationFile, true);
        }

        newFilePaths.add(destinationPath);
      } catch (e) {
        debugPrint('Error moving file $sourcePath: $e');
      }
    }

    return newFilePaths;
  }

  /// Creates a unique file name to avoid overwriting existing files.
  ///
  /// If a file with the same name exists in the destination directory,
  /// this method appends a counter to the file name until a unique name is found.
  ///
  /// Parameters:
  /// - [directory]: The directory path where the file will be saved.
  /// - [fileName]: The original file name.
  ///
  /// Returns:
  /// A [Future] that completes with a unique file name.
  static Future<String> _getUniqueFileName(
    String directory,
    String fileName,
  ) async {
    final fileNameWithoutExtension = path.basenameWithoutExtension(fileName);
    final extension = path.extension(fileName);

    String newFileName = fileName;
    int counter = 1;

    while (await File(path.join(directory, newFileName)).exists()) {
      newFileName = '${fileNameWithoutExtension}_$counter$extension';
      counter++;
    }

    return newFileName;
  }
}
