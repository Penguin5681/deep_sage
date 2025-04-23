import 'package:flutter/material.dart';

class VisualizationScreen extends StatelessWidget {
  const VisualizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text(
          'This is for creating charts and stuff',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
