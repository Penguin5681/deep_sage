import 'package:flutter/material.dart';

/// A utility class that creates custom route transitions for navigating
/// between screens in a Flutter application.
///
/// This class provides a way to create slide transitions with customizable
/// entry directions based on the provided delta values.
class RouteBuilder {
  /// Creates a custom page route with a slide transition effect.
  ///
  /// Parameters:
  /// - [screen]: The destination widget to navigate to.
  /// - [deltaX]: The starting x-offset for the slide animation.
  ///             Use 1.0 for right-to-left, -1.0 for left-to-right.
  /// - [deltaY]: The starting y-offset for the slide animation.
  ///             Use 1.0 for bottom-to-top, -1.0 for top-to-bottom.
  ///
  /// Returns a [PageRouteBuilder] with the configured slide transition.
  Route build(Widget screen, double deltaX, double deltaY) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(deltaX, deltaY);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
