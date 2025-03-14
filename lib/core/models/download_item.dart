/// A class representing an item being downloaded.
///
/// This model maintains information about a download including its progress,
/// completion status, and various metadata like name, size, and speed.
class DownloadItem {
  /// The name of the download item.
  final String name;

  /// The unique identifier for the dataset.
  final String datasetId;

  /// The size of the download, formatted as a string (e.g., "10 MB").
  final String size;

  /// The timestamp when the download was started.
  final DateTime timeStarted;

  /// The progress of the download as a percentage (0.0 to 100.0).
  late final double progress;

  /// Whether the download has been completed.
  late final bool isComplete;

  /// The current download speed, formatted as a string (e.g., "1.2 MB/s").
  late final String downloadSpeed;

  /// The source of the download (e.g., "kaggle").
  final String source; // kaggle would be the source always

  /// Creates a new [DownloadItem] with the provided parameters.
  ///
  /// All parameters except [downloadSpeed] are required.
  /// The [downloadSpeed] defaults to '0 KB/s' if not provided.
  DownloadItem({
    required this.name,
    required this.datasetId,
    required this.size,
    required this.timeStarted,
    required this.progress,
    required this.isComplete,
    required this.source,
    this.downloadSpeed = '0 KB/s',
  });

  /// Creates a copy of this [DownloadItem] but with the given fields replaced with the new values.
  ///
  /// This allows for immutable updates of the object, returning a new instance with updated values.
  /// Any parameter not provided will retain its original value.
  DownloadItem copyWith({
    String? name,
    String? datasetId,
    String? size,
    DateTime? timeStarted,
    double? progress,
    bool? isComplete,
    String? source,
    String? downloadSpeed,
  }) {
    return DownloadItem(
      name: name ?? this.name,
      datasetId: datasetId ?? this.datasetId,
      size: size ?? this.size,
      timeStarted: timeStarted ?? this.timeStarted,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      source: source ?? this.source,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
    );
  }
}
