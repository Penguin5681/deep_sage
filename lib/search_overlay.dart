import 'package:flutter/material.dart';

/// A widget that displays a search overlay modeled after Discord's search interface.
class SearchOverlay extends StatelessWidget {
  /// Text controller for the search field
  final TextEditingController textController;

  /// Focus node for the search field
  final FocusNode focusNode;

  /// Callback when the overlay should be closed
  final VoidCallback onClose;

  /// Creates a [SearchOverlay] widget.
  ///
  /// [textController] controls the text in the search field.
  /// [focusNode] manages focus for the search field.
  /// [onClose] is called when the overlay should be closed.
  const SearchOverlay({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2D31),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search for servers, channels or DMs',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Search input field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: textController,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Where would you like to go?',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => onClose(),
                      ),
                    ),
                  ],
                ),
              ),
              // Previous channels section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF232428),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        'PREVIOUS CHANNELS',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Channel items from the screenshot
                    _buildChannelItem(
                      icon: '#',
                      name: 'chodampatti',
                      type: 'TEXT CHANNELS',
                      server: 'Chusta Bhaat',
                    ),
                    _buildChannelItem(
                      icon: '🔊',
                      name: 'no-gaali-galoj',
                      server: 'Chusta Bhaat',
                    ),
                    _buildChannelItem(
                      icon: '#',
                      name: 'code-paradise',
                      type: '—TEXT CHANNELS—',
                      server: 'Chill-Paradise',
                    ),

                    // ProTip section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'PROTIP: ',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: 'Start searches with '),
                            TextSpan(
                              text: '@  #  !  *',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' to narrow down results. '),
                            TextSpan(
                              text: 'Learn more',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single channel item for the search results
  Widget _buildChannelItem({
    required String icon,
    required String name,
    String? type,
    required String server,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Channel icon
          Container(
            width: 20,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8),
            child: Text(
              icon,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Channel name and type
          Expanded(
            child: Row(
              children: [
                Text(name, style: const TextStyle(color: Colors.white)),
                if (type != null)
                  Text(
                    ' $type',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Server name
          Text(
            server,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// /// A provider for managing search functionality throughout the app
// class SearchProvider extends ChangeNotifier {
//   /// Indicates whether the search overlay is currently visible
//   bool _isSearchVisible = false;
//   bool get isSearchVisible => _isSearchVisible;

//   /// Text controller for the search field
//   final TextEditingController textController = TextEditingController();

//   /// Focus node for the search field
//   final FocusNode focusNode = FocusNode();

//   /// List of recently visited channels
//   final List<ChannelItem> _recentChannels = [
//     ChannelItem(icon: '#', name: 'chodampatti', type: 'TEXT CHANNELS', server: 'Chusta Bhaat'),
//     ChannelItem(icon: '🔊', name: 'no-gaali-galoj', server: 'Chusta Bhaat'),
//     ChannelItem(icon: '#', name: 'code-paradise', type: '—TEXT CHANNELS—', server: 'Chill-Paradise'),
//   ];
//   List<ChannelItem> get recentChannels => _recentChannels;

//   /// Opens the search overlay
//   void openSearch() {
//     _isSearchVisible = true;
//     focusNode.requestFocus();
//     notifyListeners();
//   }

//   /// Closes the search overlay
//   void closeSearch() {
//     _isSearchVisible = false;
//     focusNode.unfocus();
//     notifyListeners();
//   }

//   /// Toggles the search overlay visibility
//   void toggleSearch() {
//     if (_isSearchVisible) {
//       closeSearch();
//     } else {
//       openSearch();
//     }
//   }

//   /// Handles search submission
//   void submitSearch() {
//     // Implement search logic here
//     closeSearch();
//   }

//   /// Cleans up resources when the provider is disposed
//   @override
//   void dispose() {
//     textController.dispose();
//     focusNode.dispose();
//     super.dispose();
//   }
// }

// /// Model class for channel items in search results
// class ChannelItem {
//   final String icon;
//   final String name;
//   final String? type;
//   final String server;

//   ChannelItem({
//     required this.icon,
//     required this.name,
//     this.type,
//     required this.server,
//   });
// }

// /// Widget to provide the search functionality to the app
// class SearchProviderWidget extends StatelessWidget {
//   final Widget child;

//   const SearchProviderWidget({
//     Key? key,
//     required this.child,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => SearchProvider(),
//       child: _SearchShortcutHandler(child: child),
//     );
//   }
// }

// /// Internal widget to handle keyboard shortcuts
// class _SearchShortcutHandler extends StatelessWidget {
//   final Widget child;

//   const _SearchShortcutHandler({
//     Key? key,
//     required this.child,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final searchProvider = Provider.of<SearchProvider>(context, listen: false);

//     // Define shortcuts
//     final Map<ShortcutActivator, Intent> shortcuts = {
//       LogicalKeySet(
//         LogicalKeyboardKey.control,
//         LogicalKeyboardKey.keyF,
//       ): const SearchIntent(),
//     };

//     return Shortcuts(
//       shortcuts: shortcuts,
//       child: Actions(
//         actions: {
//           SearchIntent: CallbackAction<SearchIntent>(
//             onInvoke: (intent) {
//               searchProvider.toggleSearch();
//               return null;
//             },
//           ),
//         },
//         child: Stack(
//           children: [
//             Focus(autofocus: true, child: child),
//             // Conditionally show the search overlay
//             Consumer<SearchProvider>(
//               builder: (context, provider, _) {
//                 return provider.isSearchVisible
//                   ? SearchOverlay(provider: provider)
//                   : const SizedBox.shrink();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Custom intent for search actions
// class SearchIntent extends Intent {
//   const SearchIntent();
// }

// /// The search overlay UI component
// class SearchOverlay extends StatelessWidget {
//   final SearchProvider provider;

//   const SearchOverlay({
//     Key? key,
//     required this.provider,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.black54,
//       child: Center(
//         child: Container(
//           width: 500,
//           decoration: BoxDecoration(
//             color: const Color(0xFF2B2D31),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Search for servers, channels or DMs',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     // Search input field
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF1E1F22),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: TextField(
//                         controller: provider.textController,
//                         focusNode: provider.focusNode,
//                         style: const TextStyle(color: Colors.white),
//                         decoration: const InputDecoration(
//                           hintText: 'Where would you like to go?',
//                           hintStyle: TextStyle(color: Colors.grey),
//                           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           border: InputBorder.none,
//                         ),
//                         onSubmitted: (_) => provider.submitSearch(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Previous channels section
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(8.0),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF232428),
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(8),
//                     bottomRight: Radius.circular(8),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                       child: Text(
//                         'PREVIOUS CHANNELS',
//                         style: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     // Channel items
//                     ...provider.recentChannels.map((item) => _buildChannelItem(item)),

//                     // ProTip section
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: RichText(
//                         text: const TextSpan(
//                           style: TextStyle(color: Colors.grey, fontSize: 12),
//                           children: [
//                             TextSpan(
//                               text: 'PROTIP: ',
//                               style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//                             ),
//                             TextSpan(text: 'Start searches with '),
//                             TextSpan(text: '@  #  !  *', style: TextStyle(fontWeight: FontWeight.bold)),
//                             TextSpan(text: ' to narrow down results. '),
//                             TextSpan(
//                               text: 'Learn more',
//                               style: TextStyle(color: Colors.blue),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Builds a single channel item for the search results
//   Widget _buildChannelItem(ChannelItem item) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
//       margin: const EdgeInsets.symmetric(vertical: 2.0),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(4),
//         color: Colors.transparent,
//       ),
//       child: Row(
//         children: [
//           // Channel icon
//           Container(
//             width: 20,
//             alignment: Alignment.center,
//             margin: const EdgeInsets.only(right: 8),
//             child: Text(
//               item.icon,
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           // Channel name and type
//           Expanded(
//             child: Row(
//               children: [
//                 Text(
//                   item.name,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 if (item.type != null)
//                   Text(
//                     ' ${item.type}',
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//               ],
//             ),
//           ),
//           // Server name
//           Text(
//             item.server,
//             style: const TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }
