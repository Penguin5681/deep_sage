import 'package:flutter/material.dart';

class CategoryManufacturing extends StatelessWidget {
  final Function(String) onSearch;

  const CategoryManufacturing({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Manufacturing Category'),
    );
  }
}