import 'dart:async';

/// A service that manages directory paths and notifies listeners when paths change.
///
/// This class follows the singleton pattern to ensure only one instance exists
/// throughout the application.
class DirectoryPathService {
  /// Internal singleton instance of [DirectoryPathService].
  static final DirectoryPathService _instance =
      DirectoryPathService._internal();

  /// Factory constructor that returns the singleton instance.
  ///
  /// Use this constructor to access the service: `DirectoryPathService()`.
  factory DirectoryPathService() {
    return _instance;
  }

  /// Private constructor used by the singleton pattern.
  DirectoryPathService._internal();

  /// Stream controller for broadcasting path changes.
  final _controller = StreamController<String>.broadcast();

  /// Stream that emits the current directory path whenever it changes.
  ///
  /// Subscribe to this stream to be notified of path changes.
  Stream<String> get pathStream => _controller.stream;

  /// Notifies all listeners that the directory path has changed.
  ///
  /// [path] The new directory path to broadcast.
  void notifyPathChange(String path) {
    _controller.add(path);
  }

  /// Closes the stream controller and releases resources.
  ///
  /// Should be called when the service is no longer needed.
  void dispose() {
    _controller.close();
  }
}
