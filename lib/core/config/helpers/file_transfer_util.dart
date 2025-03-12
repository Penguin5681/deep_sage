import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;

class FileTransferUtil {
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
