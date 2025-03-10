import 'package:flutter/material.dart';

class DatasetCard extends StatelessWidget {
  final String lightIconPath;
  final String darkIconPath;
  final String labelText;
  final double labelSize;
  final String subLabelText;
  final double subLabelSize;
  final String buttonText;

  final VoidCallback onSearch;

  // no way i forgot to create a onButtonClick prop for ts.
  // i will do it i need it lol.

  const DatasetCard({
    super.key,
    required this.lightIconPath,
    required this.labelText,
    this.labelSize = 25.0,
    required this.subLabelText,
    this.subLabelSize = 14.0,
    required this.buttonText,
    required this.darkIconPath,
    required this.onSearch,
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
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Color(0xff41434b)
                : Color(0xfff4f4f4),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 23.0,
          bottom: 23.0,
          left: 23.0,
          right: 100.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey
                        : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: getIconForTheme(
                  lightIcon: lightIconPath,
                  darkIcon: darkIconPath,
                  size: 15,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              labelText,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: labelSize,
              ),
            ),
            Text(subLabelText, style: TextStyle(fontSize: subLabelSize)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
