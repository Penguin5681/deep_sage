import 'package:hive_flutter/adapters.dart';

part 'recent_imports_model.g.dart';

@HiveType(typeId: 1)
class RecentImportsModel {
  @HiveField(0)
  final String fileName;

  @HiveField(1)
  final String fileType;

  @HiveField(2)
  final DateTime importTime;

  @HiveField(3)
  final String fileSize;

  @HiveField(4)
  final String? filePath;

  RecentImportsModel({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.importTime,
    required this.filePath,
  });
}
