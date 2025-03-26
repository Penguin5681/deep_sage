import 'package:flutter/material.dart';
        import 'package:flutter/services.dart';

        /// [ShortcutService] is a [StatelessWidget] that manages keyboard shortcuts
        /// for tab navigation. It allows users to switch between tabs using
        /// `Ctrl + 1` to `Ctrl + 9` keyboard shortcuts and cycle through tabs
        /// using `Ctrl + Tab`.
        class ShortcutService extends StatelessWidget {
          /// The child widget to be wrapped by the shortcut manager.
          final Widget child;

          /// Callback function to be invoked when a tab change is triggered.
          /// It receives the index of the tab to navigate to.
          final Function(int) onTabChange;

          /// The total number of tabs available. This is used to determine
          /// the range of keyboard shortcuts to be registered.
          final int tabCount;

          /// The currently selected tab index, used for cycling tabs.
          final int currentIndex;

          /// Creates a [ShortcutService] widget.
          ///
          /// [child] is the widget below this widget in the tree.
          /// [onTabChange] is the callback for when a new tab is requested.
          /// [tabCount] is the number of tabs that shortcuts should be assigned to.
          /// [currentIndex] is the currently selected tab index (defaults to 0).
          const ShortcutService({
            super.key,
            required this.child,
            required this.onTabChange,
            required this.tabCount,
            this.currentIndex = 0,
          });

          @override
          Widget build(BuildContext context) {
            final Map<ShortcutActivator, Intent> shortcuts = {};

            // Register shortcuts for each tab, from Ctrl+1 to Ctrl+9.
            for (int i = 1; i <= tabCount; i++) {
              if (i <= tabCount) {
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

            // Create and return the widget tree for handling shortcuts and actions.
            return Shortcuts(
              shortcuts: shortcuts,
              child: Actions(
                actions: {
                  TabNavigationIntent: CallbackAction<TabNavigationIntent>(
                    onInvoke: (intent) {
                      onTabChange(intent.tabIndex);
                      return null;
                    },
                  ),
                  CycleTabIntent: CallbackAction<CycleTabIntent>(
                    onInvoke: (intent) {
                      // Cycle to the next tab, looping back to the first tab when at the end
                      final nextIndex = (currentIndex + 1) % tabCount;
                      onTabChange(nextIndex);
                      return null;
                    },
                  ),
                },
                child: Focus(autofocus: true, child: child),
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