import 'package:deep_sage/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [SearchShortcutService] extends the original shortcut service by adding
/// a Ctrl+F shortcut that triggers a search overlay.
class SearchShortcutService extends StatefulWidget {
  /// The child widget to be wrapped by the shortcut manager.
  final Widget child;

  /// Callback function to be invoked when a tab change is triggered.
  final Function(int) onTabChange;

  /// The total number of tabs available.
  final int tabCount;

  /// The currently selected tab index, used for cycling tabs.
  final int currentIndex;

  /// Creates a [SearchShortcutService] widget.
  const SearchShortcutService({
    super.key,
    required this.child,
    required this.onTabChange,
    required this.tabCount,
    this.currentIndex = 0,
  });

  @override
  State<SearchShortcutService> createState() => _SearchShortcutServiceState();
}

class _SearchShortcutServiceState extends State<SearchShortcutService> {
  /// Controls visibility of the search overlay
  bool _showSearchOverlay = false;
  
  /// Text controller for the search input field
  final TextEditingController _searchController = TextEditingController();
  
  /// Focus node for the search input field
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Toggles the search overlay visibility
  void _toggleSearchOverlay() {
    setState(() {
      _showSearchOverlay = !_showSearchOverlay;
      if (_showSearchOverlay) {
        // When showing overlay, focus the search field
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  /// Closes the search overlay
  void _closeSearchOverlay() {
    if (_showSearchOverlay) {
      setState(() {
        _showSearchOverlay = false;
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<ShortcutActivator, Intent> shortcuts = {};

    // Register shortcuts for each tab, from Ctrl+1 to Ctrl+9.
    for (int i = 1; i <= widget.tabCount; i++) {
      if (i <= widget.tabCount) {
        shortcuts[LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey(0x30 + i),
        )] = TabNavigationIntent(i - 1);
      }
    }

    // Add Ctrl+Tab shortcut for cycling through tabs
    shortcuts[LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.tab,
    )] = CycleTabIntent();

    // Add Ctrl+F shortcut for search overlay
    shortcuts[LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyF,
    )] = SearchOverlayIntent();

    // Add Escape shortcut to close the search overlay when it's open
    shortcuts[LogicalKeySet(LogicalKeyboardKey.escape)] = CloseOverlayIntent();

    // Create and return the widget tree for handling shortcuts and actions.
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          TabNavigationIntent: CallbackAction<TabNavigationIntent>(
            onInvoke: (intent) {
              widget.onTabChange(intent.tabIndex);
              return null;
            },
          ),
          CycleTabIntent: CallbackAction<CycleTabIntent>(
            onInvoke: (intent) {
              // Cycle to the next tab, looping back to the first tab when at the end
              final nextIndex = (widget.currentIndex + 1) % widget.tabCount;
              widget.onTabChange(nextIndex);
              return null;
            },
          ),
          SearchOverlayIntent: CallbackAction<SearchOverlayIntent>(
            onInvoke: (intent) {
              _toggleSearchOverlay();
              return null;
            },
          ),
          CloseOverlayIntent: CallbackAction<CloseOverlayIntent>(
            onInvoke: (intent) {
              _closeSearchOverlay();
              return null;
            },
          ),
        },
        child: Stack(
          children: [
            // Main content
            Focus(autofocus: true, child: widget.child),
            
            // Search overlay (only visible when _showSearchOverlay is true)
            if (_showSearchOverlay)
              SearchOverlay(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onClose: _closeSearchOverlay,
              ),
          ],
        ),
      ),
    );
  }
}

/// [TabNavigationIntent] is a custom [Intent] used to represent
/// a request to navigate to a specific tab.
class TabNavigationIntent extends Intent {
  /// The index of the tab to navigate to.
  final int tabIndex;

  /// Creates a [TabNavigationIntent] with the given [tabIndex].
  const TabNavigationIntent(this.tabIndex);
}

/// [CycleTabIntent] is a custom [Intent] used to represent
/// a request to cycle to the next tab.
class CycleTabIntent extends Intent {
  /// Creates a [CycleTabIntent].
  const CycleTabIntent();
}

/// [SearchOverlayIntent] is a custom [Intent] used to represent
/// a request to toggle the search overlay.
class SearchOverlayIntent extends Intent {
  /// Creates a [SearchOverlayIntent].
  const SearchOverlayIntent();
}

/// [CloseOverlayIntent] is a custom [Intent] used to represent
/// a request to close open overlays.
class CloseOverlayIntent extends Intent {
  /// Creates a [CloseOverlayIntent].
  const CloseOverlayIntent();
}