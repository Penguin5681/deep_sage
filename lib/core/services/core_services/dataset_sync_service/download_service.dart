import 'package:flutter/foundation.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final ValueNotifier<Map<String, String>> activeDownloads = ValueNotifier<Map<String, String>>({});

  void startDownload(String fileName, String status) {
    final downloads = Map<String, String>.from(activeDownloads.value);
    downloads[fileName] = status;
    activeDownloads.value = downloads;
  }

  void updateDownloadStatus(String fileName, String status) {
    final downloads = Map<String, String>.from(activeDownloads.value);
    downloads[fileName] = status;
    activeDownloads.value = downloads;
  }

  void completeDownload(String fileName) {
    final downloads = Map<String, String>.from(activeDownloads.value);
    downloads.remove(fileName);
    activeDownloads.value = downloads;
  }

  int get downloadCount => activeDownloads.value.length;
  bool get hasDownloads => activeDownloads.value.isNotEmpty;
}