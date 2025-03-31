import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deep_sage/save_overlay.dart'; // Import the SaveOverlay widget

/// [SaveShortcutService] is a [StatelessWidget] that manages the Ctrl+S keyboard shortcut
/// and triggers a save overlay when the shortcut is activated.
class SaveShortcutService extends StatelessWidget {
  /// The child widget to be wrapped by the shortcut service
  final Widget child;

  /// Callback function to be invoked when the save is triggered.
  final VoidCallback onSave;

  /// Creates a [SaveShortcutService] widget.
  ///
  /// [child] is the widget below this widget in the tree.
  /// [onSave] is the callback for when a save is requested.
  const SaveShortcutService({
    super.key,
    required this.child,
    required this.onSave,
  });

  /// Shows the save overlay
  void _showSaveOverlay(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => SaveOverlay(
            onSave: () {
              // Perform save action
              onSave();

              // Remove the overlay
              overlayEntry?.remove();
            },
            onCancel: () {
              // Simply remove the overlay
              overlayEntry?.remove();
            },
          ),
    );

    // Insert the overlay entry into the screen
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    // Define Ctrl + S shortcut
    final shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          SaveIntent(),
    };

    // Create and return the widget tree for the handling shortcuts and actions
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) {
              // Show save overlay when Ctrl + S is pressed
              _showSaveOverlay(context);
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

/// [SaveIntent] is a custom [Intent] used to represent a request to save the current state.
class SaveIntent extends Intent {
  /// Creates a [SaveIntent] instance.
  const SaveIntent();
}
