import 'dart:math';

import 'package:flutter/material.dart';

class DatasetCard extends StatelessWidget {
  /// The path to the icon image used in light mode.
  final String lightIconPath;

  /// The path to the icon image used in dark mode.
  final String darkIconPath;

  /// The main text label displayed on the card.
  final String labelText;

  /// The font size of the main label text. Defaults to 20.0.
  final double labelSize;

  /// The secondary text label displayed below the main label.
  final String subLabelText;

  /// The font size of the sub-label text. Defaults to 13.0.
  final double subLabelSize;

  /// The text displayed on the action button.
  final String buttonText;

  /// Callback function invoked when the button is pressed.
  final VoidCallback onButtonClick;

  /// Creates a [DatasetCard] widget.
  ///
  /// This card displays information about a dataset, including an icon,
  /// a main label, a sub-label, and an action button.
  ///
  /// The [lightIconPath] and [darkIconPath] are required and represent the
  /// paths to the icon images for light and dark modes, respectively.
  ///
  /// The [labelText], [subLabelText], and [buttonText] are required text
  /// fields displayed on the card.
  ///
  /// The [onButtonClick] is a required callback that is called when the
  /// button on the card is pressed.
  ///
  /// [labelSize] and [subLabelSize] are optional parameters that control the
  /// font sizes of the labels, with default values of 20.0 and 13.0, respectively.
  const DatasetCard({
    super.key,
    required this.lightIconPath,
    required this.labelText,
    this.labelSize = 20.0,
    required this.subLabelText,
    this.subLabelSize = 13.0,
    required this.buttonText,
    required this.darkIconPath,
    required this.onButtonClick,
  });

  Widget getIconForTheme({
    required String lightIcon,
    required String darkIcon,
    double size = 24,
  }) {
    return Builder(
      /// Returns an icon widget based on the current theme.
      ///
      /// This method dynamically loads an icon based on whether the app is in
      /// dark mode or light mode.
      ///
      /// [lightIcon]: The path to the icon to display in light mode.
      /// [darkIcon]: The path to the icon to display in dark mode.
      /// [size]: The size of the icon. Defaults to 24.
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(
          isDarkMode ? darkIcon : lightIcon,
          width: size,
          height: size,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    // Adaptive width calculation - smaller on small screens
    final cardWidth =
        width < 600 ? min(width * 0.75, 280.0) : min(width * 0.25, 320.0);

    return Container(
      width: cardWidth,
      height: 200, // Reduced from 260
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [const Color(0xFF2C2D35), const Color(0xFF373A47)]
                  : [const Color(0xFFFFFFFF), const Color(0xFFF0F4F8)],
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Accent decorations
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80, // Smaller decoration
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDarkMode
                        ? Colors.blue.withValues(alpha: 0.05)
                        : Colors.blue.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -10,
            child: Container(
              width: 100, // Smaller decoration
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDarkMode
                        ? Colors.purple.withValues(alpha: 0.05)
                        : Colors.purple.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Card content - more compact padding
          Padding(
            padding: const EdgeInsets.all(16.0), // Reduced from 24.0
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0), // Reduced from 12.0
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              isDarkMode
                                  ? [
                                    Colors.blue.shade800,
                                    Colors.purple.shade900,
                                  ]
                                  : [
                                    Colors.blue.shade400,
                                    Colors.purple.shade500,
                                  ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isDarkMode
                                    ? Colors.blue.withValues(alpha: 0.3)
                                    : Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: getIconForTheme(
                        lightIcon: lightIconPath,
                        darkIcon: darkIconPath,
                        size: 18, // Smaller icon
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Move title next to icon on small screens
                    width < 600
                        ? Expanded(
                          child: Text(
                            labelText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: labelSize,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
                  ],
                ),
                if (width >= 600) const SizedBox(height: 16),
                // Only show title in separate row on larger screens
                if (width >= 600)
                  Text(
                    labelText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: labelSize,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                const SizedBox(height: 8), // Reduced from 12
                Text(
                  subLabelText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subLabelSize,
                    color:
                        isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonClick,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return isDarkMode
                              ? Colors.blue.shade900
                              : Colors.blue.shade700;
                        }
                        return isDarkMode
                            ? Colors.blue.shade700
                            : Colors.blue.shade600;
                      }),
                      overlayColor: WidgetStateProperty.all(
                        isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 14, // Smaller text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
