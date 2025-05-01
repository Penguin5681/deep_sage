import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [SearchShortcutService] is a [StatelessWidget] that manages keyboard shortcuts
/// for triggering a search overlay. It allows users to open the search overlay
/// using `Ctrl + F` keyboard shortcut.
class SearchShortcutService extends StatelessWidget {
  /// The child widget to be wrapped by the shortcut manager.
  final Widget child;

  /// Callback function to be invoked when the search is triggered.
  final VoidCallback onSearchTriggered;

  /// Creates a [SearchShortcutService] widget.
  ///
  /// [child] is the widget below this widget in the tree.
  /// [onSearchTriggered] is the callback for when the search shortcut is activated.
  const SearchShortcutService({
    super.key,
    required this.child,
    required this.onSearchTriggered,
  });

  @override
  Widget build(BuildContext context) {
    final Map<ShortcutActivator, Intent> shortcuts = {};

    // Register Ctrl+F shortcut for search
    shortcuts[LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyF,
    )] = const SearchIntent();

    // Create and return the widget tree for handling shortcuts and actions.
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              onSearchTriggered();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

/// [SearchIntent] is a custom [Intent] used to represent
/// a request to trigger the search overlay.
class SearchIntent extends Intent {
  /// Creates a [SearchIntent].
  const SearchIntent();
}