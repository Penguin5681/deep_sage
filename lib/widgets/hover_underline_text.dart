import 'package:flutter/material.dart';

/// A widget that displays text that becomes underlined when hovered over.
class HoverUnderlineText extends StatefulWidget {
  /// The text to display.
  final String text;

  /// The style of the text.
  final TextStyle style;

  /// Creates a [HoverUnderlineText].
  ///
  /// The [text] and [style] arguments must not be null.
  ///
  /// Example:
  ///
  const HoverUnderlineText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<HoverUnderlineText> createState() => _HoverUnderlineTextState();
}

class _HoverUnderlineTextState extends State<HoverUnderlineText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Text(
        widget.text,
        style: widget.style.copyWith(
          decoration:
              _isHovering ? TextDecoration.underline : TextDecoration.none,
          decorationColor: Colors.blue,
        ),
      ),
    );
  }
}
