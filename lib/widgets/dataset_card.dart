import 'package:flutter/material.dart';

class DatasetCard extends StatelessWidget {
  final String lightIconPath;
  final String darkIconPath;
  final String labelText;
  final double labelSize;
  final String subLabelText;
  final double subLabelSize;
  final String buttonText;
  final VoidCallback onButtonClick;

  const DatasetCard({
    super.key,
    required this.lightIconPath,
    required this.labelText,
    this.labelSize = 25.0,
    required this.subLabelText,
    this.subLabelSize = 14.0,
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

    return Container(
      width: 320,
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            const Color(0xFF2C2D35),
            const Color(0xFF373A47),
          ]
              : [
            const Color(0xFFFFFFFF),
            const Color(0xFFF0F4F8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? Colors.blue.withValues(alpha: 0.05)
                    : Colors.blue.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? Colors.purple.withValues(alpha: 0.05)
                    : Colors.purple.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
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
                        color: isDarkMode
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
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 4),
                Text(
                  subLabelText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subLabelSize,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
                const Spacer(), // Pushes the button to the bottom.
                ElevatedButton(
                  onPressed: onButtonClick,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
