import 'package:flutter/material.dart';

/// A service that manages the display of download overlays in the application.
///
/// This service uses the ChangeNotifier pattern to allow widgets to rebuild
/// when the overlay state changes, and provides a way to register and trigger
/// overlay display callbacks.
class DownloadOverlayService extends ChangeNotifier {
  /// Callback function that will be triggered to show the overlay.
  Function? _showOverlayCallback;

  /// Registers a callback function that will be used to display the overlay.
  ///
  /// This method should be called by the widget responsible for showing
  /// the overlay, typically during initialization.
  ///
  /// [showOverlayCallback] The function to call when the overlay should be shown.
  void registerOverlayCallback(Function showOverlayCallback) {
    _showOverlayCallback = showOverlayCallback;
  }

  /// Triggers the display of the download overlay.
  ///
  /// This method calls the registered callback function if one exists.
  /// If no callback has been registered, this method does nothing.
  void showDownloadOverlay() {
    if (_showOverlayCallback != null) {
      _showOverlayCallback!();
    }
  }
}
