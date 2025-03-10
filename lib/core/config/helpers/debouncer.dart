import 'dart:async';

class Debouncer {
  final Duration delayBetweenRequests;
  Timer? _timer;

  Debouncer({required this.delayBetweenRequests});

  void run(Function() action) {
    _timer?.cancel();
    _timer = Timer(delayBetweenRequests, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
