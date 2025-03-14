import 'package:hive_flutter/adapters.dart';

part 'recent_imports_model.g.dart';

/// A model class to store information about recently imported files.
///
/// This class is used with Hive for local persistence with typeId 1.
/// The generated adapter code is in the part file 'recent_imports_model.g.dart'.
@HiveType(typeId: 1)
class RecentImportsModel {
  /// The name of the imported file.
  @HiveField(0)
  final String fileName;

  /// The file type/extension of the imported file.
  @HiveField(1)
  final String fileType;

  /// The timestamp when the file was imported.
  @HiveField(2)
  final DateTime importTime;

  /// The size of the imported file, formatted as a string.
  @HiveField(3)
  final String fileSize;

  /// The full path to the imported file.
  /// May be null if the file path is not available.
  @HiveField(4)
  final String? filePath;

  /// Creates a new instance of [RecentImportsModel].
  ///
  /// All parameters except [filePath] are required.
  RecentImportsModel({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.importTime,
    required this.filePath,
  });
}
