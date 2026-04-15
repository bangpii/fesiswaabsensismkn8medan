import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AppAnimations {
  static Widget fadeUp({
    required Widget child,
    int duration = 600,
  }) {
    return FadeInUp(
      duration: Duration(milliseconds: duration),
      child: child,
    );
  }

  static Widget fadeIn({
    required Widget child,
    int duration = 600,
  }) {
    return FadeIn(
      duration: Duration(milliseconds: duration),
      child: child,
    );
  }

  static Widget zoomIn({
    required Widget child,
    int duration = 600,
  }) {
    return ZoomIn(
      duration: Duration(milliseconds: duration),
      child: child,
    );
  }
}