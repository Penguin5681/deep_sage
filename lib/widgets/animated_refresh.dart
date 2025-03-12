import 'package:flutter/material.dart';

class AnimatedRefresh extends StatefulWidget {
  final Future<void> Function() onPressed;
  final Color? color;
  final double size;

  const AnimatedRefresh({
    super.key,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  });

  @override
  State<AnimatedRefresh> createState() => _AnimatedRefreshState();
}

class _AnimatedRefreshState extends State<AnimatedRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    _controller.repeat();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() {
          _isAnimating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value,
            child: Icon(Icons.sync, size: widget.size),
          );
        },
      ),
      onPressed: _handlePress,
      tooltip: 'Refresh',
    );
  }
}
