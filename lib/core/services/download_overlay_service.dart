import 'package:flutter/material.dart';

class DownloadOverlayService extends ChangeNotifier {
  Function? _showOverlayCallback;

  void registerOverlayCallback(Function showOverlayCallback) {
    _showOverlayCallback = showOverlayCallback;
  }

  void showDownloadOverlay() {
    if (_showOverlayCallback != null) {
      _showOverlayCallback!();
    }
  }
}
