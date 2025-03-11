class DownloadItem {
  final String name;
  final String size;
  final DateTime timeStarted;
  late final double progress;
  late final bool isComplete;
  late final String downloadSpeed;
  final String source; // kaggle would be the source always

  DownloadItem({
    required this.name,
    required this.size,
    required this.timeStarted,
    required this.progress,
    required this.isComplete,
    required this.source,
    this.downloadSpeed = '0 KB/s',
  });

  DownloadItem copyWith({
    String? name,
    String? size,
    DateTime? timeStarted,
    double? progress,
    bool? isComplete,
    String? source,
    String? downloadSpeed,
  }) {
    return DownloadItem(
      name: name ?? this.name,
      size: size ?? this.size,
      timeStarted: timeStarted ?? this.timeStarted,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      source: source ?? this.source,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
    );
  }
}
