import 'package:flutter/widgets.dart';
import 'fog_reveal.dart';
import 'fog_style.dart';

/// Connects any animation, including a FogRevealController, to a fog overlay.
///
/// The caller owns playback, listeners, reduced-motion policy and disposal.
/// The child is preserved while progress changes.
class FogTransition extends StatelessWidget {
  /// Creates an externally controlled transition.
  const FogTransition({
    super.key,
    required this.animation,
    required this.child,
    this.curve = Curves.easeInOutCubic,
    this.style = const FogStyle(),
    this.borderRadius = BorderRadius.zero,
    this.blockInteraction = false,
    this.excludeSemantics = false,
    this.onReady,
    this.onError,
  });

  /// Progress source. Values are clamped before applying [curve].
  ///
  /// Raw progress drives cloud motion while curved progress drives dissolve,
  /// matching the reference demo.
  final Animation<double> animation;

  /// Easing applied to animation progress.
  final Curve curve;

  /// Content under the fog.
  final Widget child;

  /// Custom appearance or a built-in FogStyle preset.
  final FogStyle style;

  /// Radius clipping both the content and fog.
  final BorderRadius borderRadius;

  /// Blocks child pointer input until fully revealed.
  final bool blockInteraction;

  /// Hides child semantics until fully revealed.
  final bool excludeSemantics;

  /// Called after the shader and texture are ready for playback.
  final VoidCallback? onReady;

  /// Reports shader and texture loading failures.
  final FogErrorCallback? onError;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final value = animation.value;
          final progress = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
          return FogReveal(
            progress: curve.transform(progress),
            motionProgress: progress,
            style: style,
            borderRadius: borderRadius,
            blockInteraction: blockInteraction,
            excludeSemantics: excludeSemantics,
            onReady: onReady,
            onError: onError,
            child: child!,
          );
        },
      );
}
