import 'package:flutter/material.dart';

class CategoryHealthcare extends StatelessWidget {
  final Function(String) onSearch;

  const CategoryHealthcare({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Healthcare Category'),
    );
  }
}