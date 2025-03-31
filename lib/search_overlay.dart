import 'package:flutter/material.dart';

/// A search overlay widget that mimics Discord's search interface.
class SearchOverlay extends StatelessWidget {
  /// Controller for the search text field.
  final TextEditingController controller;
  
  /// Focus node for the search text field.
  final FocusNode focusNode;
  
  /// Callback function when the overlay should be closed.
  final VoidCallback onClose;

  /// Creates a [SearchOverlay] widget.
  const SearchOverlay({
    super.key,
    required this.controller,
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
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Where would you like to go?',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                    _buildChannelItem(icon: '#', name: 'chodampatti', type: 'TEXT CHANNELS', server: 'Chusta Bhaat'),
                    _buildChannelItem(icon: '🔊', name: 'no-gaali-galoj', server: 'Chusta Bhaat'),
                    _buildChannelItem(icon: '#', name: 'code-paradise', type: '—TEXT CHANNELS—', server: 'Chill-Paradise'),
                    
                    // ProTip section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'PROTIP: ',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Start searches with '),
                            TextSpan(text: '@  #  !  *', style: TextStyle(fontWeight: FontWeight.bold)),
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

  /// Builds a single channel item for the search results exactly as shown in the screenshot
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
                Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                ),
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