import 'package:flutter/material.dart';

class SourceDropdown extends StatefulWidget {
  final VoidCallback? onSelected;
  final Function(String)? onValueChanged;

  const SourceDropdown({super.key, this.onSelected, this.onValueChanged});

  @override
  State<SourceDropdown> createState() => _SourceDropdownState();
}

class _SourceDropdownState extends State<SourceDropdown> {
  String selectedValue = 'Hugging Face';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Source',
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700], fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: false,
          icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey[700]),
          style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
          dropdownColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          items: const [
            DropdownMenuItem(value: 'Kaggle', child: Text('Kaggle')),
            DropdownMenuItem(value: 'Hugging Face', child: Text('Hugging Face')),
            DropdownMenuItem(value: 'All', child: Text('All')),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedValue = newValue;
              });
              widget.onSelected?.call();
              widget.onValueChanged?.call(newValue);
            }
          },
        ),
      ),
    );
  }
}
