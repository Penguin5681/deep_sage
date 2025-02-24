import 'package:flutter/material.dart';

class PrimaryEditText extends StatefulWidget {
  final String placeholderText;
  final TextEditingController controller;
  final bool obscureText;
  final Icon prefixIcon;

  const PrimaryEditText({
    super.key,
    required this.placeholderText,
    required this.controller,
    required this.obscureText,
    required this.prefixIcon,
  });

  @override
  State<PrimaryEditText> createState() => _PrimaryEditTextState();
}

class _PrimaryEditTextState extends State<PrimaryEditText> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      maxLines: 1,
      cursorColor: Colors.white,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        suffixIcon:
            widget.obscureText
                ? IconButton(
                  onPressed: _toggleVisibility,
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                )
                : null,
        hintText: widget.placeholderText,
      ),
    );
  }
}
