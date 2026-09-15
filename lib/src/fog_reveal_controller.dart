import 'package:flutter/animation.dart';

/// Animation controller with fog-specific playback helpers.
///
/// Pass this to `AnimatedFogReveal` as its controller. The owner must dispose it.
/// Inherited value/status listeners, forward, reverse, repeat and animateTo
/// remain available. External controllers own their reduced-motion policy.
class FogRevealController extends AnimationController {
  /// Creates a controller, initially covered unless [value] is supplied.
  FogRevealController({
    required super.vsync,
    Duration duration = const Duration(milliseconds: 2800),
    super.reverseDuration,
    double value = 0,
    super.debugLabel,
  }) : super(
          duration: duration,
          value: value,
          animationBehavior: AnimationBehavior.normal,
        );

  bool _reverse = false;

  /// Reveals from the current position.
  TickerFuture reveal() => forward();

  /// Covers from the current position.
  TickerFuture cover() => reverse();

  /// Restarts the reveal from fully covered.
  TickerFuture replay() => forward(from: 0);

  /// Pauses and remembers the current direction, including during a loop.
  void pause() {
    _reverse = status == AnimationStatus.reverse;
    stop();
  }

  /// Continues in the paused direction to its endpoint (does not restart loops).
  TickerFuture resume() => _reverse ? reverse() : forward();

  /// Stops playback and jumps to [progress], clamped to zero through one.
  void seek(double progress) {
    if (!progress.isFinite) {
      throw ArgumentError.value(progress, 'progress', 'Must be finite');
    }
    value = progress.clamp(0.0, 1.0);
  }

  /// Reverses the current direction, or reveals when fully covered.
  @override
  TickerFuture toggle({double? from}) =>
      status == AnimationStatus.forward || isCompleted
          ? reverse(from: from)
          : forward(from: from);
}
