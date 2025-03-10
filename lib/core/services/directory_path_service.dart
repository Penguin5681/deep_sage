import 'dart:async';

class DirectoryPathService {
  static final DirectoryPathService _instance =
      DirectoryPathService._internal();

  factory DirectoryPathService() {
    return _instance;
  }

  DirectoryPathService._internal();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get pathStream => _controller.stream;

  void notifyPathChange(String path) {
    _controller.add(path);
  }

  void dispose() {
    _controller.close();
  }
}
