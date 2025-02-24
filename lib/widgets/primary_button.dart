import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color:
              Theme.of(
                context,
              ).elevatedButtonTheme.style?.textStyle?.resolve({})?.color,
          fontWeight:
              Theme.of(
                context,
              ).elevatedButtonTheme.style?.textStyle?.resolve({})?.fontWeight,
        ),
      ),
    );
  }
}
