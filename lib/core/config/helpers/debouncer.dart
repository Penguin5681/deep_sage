import 'dart:async';

/// A utility class that helps to limit the rate at which a function is called.
///
/// This class is useful in cases where you want to delay executing a function
/// until after a certain amount of time has elapsed since the last invocation.
/// Common use cases include search input debouncing, button click handlers, and
/// resize/scroll event handlers.
class Debouncer {
  /// The amount of time to wait before executing the delayed function.
  final Duration delayBetweenRequests;

  /// Internal timer that manages the delayed execution.
  Timer? _timer;

  /// Creates a Debouncer with the specified delay duration.
  ///
  /// [delayBetweenRequests] is the time to wait after the last call
  /// before executing the function.
  Debouncer({required this.delayBetweenRequests});

  /// Executes the given action after the specified delay.
  ///
  /// If [run] is called again before the delay has elapsed,
  /// the previous pending action is canceled and a new one is scheduled.
  ///
  /// [action] is the function to execute after the delay.
  void run(Function() action) {
    _timer?.cancel();
    _timer = Timer(delayBetweenRequests, action);
  }

  /// Cancels any pending execution and releases resources.
  ///
  /// Should be called when the debouncer is no longer needed
  /// to avoid memory leaks.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
