import 'package:flutter/material.dart';

class CategoryGovernment extends StatelessWidget {
  final Function(String) onSearch;

  const CategoryGovernment({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Government Category'),
    );
  }
}