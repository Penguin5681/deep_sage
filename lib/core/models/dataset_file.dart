class DatasetFile {
  final String fileName;
  final String fileType;
  final String fileSize;
  final String filePath;
  final DateTime modified;
  final bool isStarred;

  DatasetFile({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.filePath,
    required this.modified,
    required this.isStarred,
  });

  Map<String, String> toMap() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'filePath': filePath,
      'modified': _formatModifiedTime(modified),
      'isStarred': isStarred.toString(),
    };
  }

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
      return '${(difference.inDays / 7).floor()} weeks${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
    } else {
      return dateTime.toString().substring(0, 10);
    }
  }
}
