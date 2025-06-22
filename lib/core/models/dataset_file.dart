/// A class that represents a file in a dataset.
///
/// This class stores information about a file including its name, type,
/// size, path, modification time, sync status, and whether it is starred.
class DatasetFile {
  /// The name of the file.
  String fileName;

  /// The type of the file (e.g. 'csv', 'json', etc.).
  String fileType;

  /// The size of the file, formatted as a string (e.g. '2.5 MB').
  String fileSize;

  /// The full path to the file.
  String filePath;

  /// The date and time when the file was last modified.
  DateTime modified;

  /// Whether the file is marked as starred by the user.
  bool isStarred;

  /// The sync status of the file (e.g., "Synced", "NotSynced", "Syncing").
  String? syncStatus;

  /// Creates a new [DatasetFile] instance with the required properties.
  ///
  /// All parameters are required, except [syncStatus] which defaults to "NotSynced".
  DatasetFile({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.filePath,
    required this.modified,
    required this.isStarred,
    this.syncStatus = "NotSynced",
  });

  /// Converts this instance to a map representation.
  ///
  /// The returned map contains all properties as strings, with the modified
  /// date formatted using [_formatModifiedTime].
  ///
  /// Returns a [Map<String, String>] containing the properties of this instance.
  Map<String, String> toMap() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'filePath': filePath,
      'modified': _formatModifiedTime(modified),
      'isStarred': isStarred.toString(),
      'syncStatus': syncStatus ?? "NotSynced",
    };
  }

  /// Formats the provided [dateTime] into a human-readable string.
  ///
  /// The formatting follows these rules:
  /// - Less than 1 minute: "Just now"
  /// - Less than 1 hour: "X minutes ago"
  /// - Less than 1 day: "X hours ago"
  /// - Less than 7 days: "X days ago"
  /// - Less than 30 days: "X weeks ago"
  /// - Otherwise: The date in "yyyy-MM-dd" format
  ///
  /// Returns a formatted string representing the time elapsed since [dateTime].
  static String _formatModifiedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
    } else {
      return dateTime.toString().substring(0, 10);
    }
  }
}
