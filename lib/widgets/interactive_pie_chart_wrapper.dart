import 'package:flutter/material.dart';
import 'dart:math';

class InteractivePieChartWrapper extends StatefulWidget {
  final Widget child;
  final bool isImage;

  const InteractivePieChartWrapper({super.key, required this.child, required this.isImage});

  @override
  State<InteractivePieChartWrapper> createState() => _InteractivePieChartWrapperState();
}

class _InteractivePieChartWrapperState extends State<InteractivePieChartWrapper> {
  final TransformationController _transformationController = TransformationController();
  double _rotation = 0.0;
  bool _isFullScreen = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (context, _, __) => Scaffold(
              backgroundColor: Colors.black.withValues(alpha: 0.9),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('Chart Viewer'),
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isFullScreen = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
              body: SafeArea(child: _buildInteractiveChart()),
            ),
      ),
    );
  }

  Widget _buildInteractiveChart() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.5,
              maxScale: 4.0,
              child:
                  widget.isImage
                      ? widget.child
                      : Transform.rotate(angle: _rotation, child: widget.child),
            ),
          ),
        ),
        _buildToolBar(),
      ],
    );
  }

  Widget _buildToolBar() {
    return Container(
      color: Colors.black12,
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              final zoom = _transformationController.value.getMaxScaleOnAxis();
              if (zoom < 4.0) {
                _transformationController.value = Matrix4.identity()..scale(zoom + 0.5);
              }
            },
            tooltip: 'Zoom In',
            icon: Icon(Icons.zoom_in),
          ),
          IconButton(
            onPressed: () {
              final zoom = _transformationController.value.getMaxScaleOnAxis();
              if (zoom > 4.0) {
                _transformationController.value = Matrix4.identity()..scale(max(0.5, zoom - 0.5));
              }
            },
            tooltip: 'Zoom Out',
            icon: Icon(Icons.zoom_out),
          ),
          if (!widget.isImage)
            IconButton(
              icon: const Icon(Icons.rotate_right),
              onPressed: () {
                setState(() {
                  _rotation += pi / 6; // this shi would be 30 degrees
                });
              },
              tooltip: "Rotate",
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _rotation = 0; // this shi would reset the thing
              });
            },
            tooltip: "Reset Value",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(onDoubleTap: _enterFullScreen, child: _buildInteractiveChart()),
        ),
        if (!_isFullScreen)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.fullscreen, size: 18),
                  label: const Text('Full Screen'),
                  onPressed: _enterFullScreen,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
