import 'package:flutter/widgets.dart';
import 'fog_reveal.dart';
import 'fog_reveal_controller.dart';
import 'fog_style.dart';
import 'fog_transition.dart';

/// Animates [child] from fully covered to fully revealed by organic fog.
///
/// With no [controller], changing [revealed] automatically reveals or covers the
/// child. This is convenient for image loading and other asynchronous content.
/// Supply a [FogRevealController] when playback controls such as replay, seek,
/// pause, cover, or repeat are needed. A supplied controller is never disposed.
///
/// [duration], [reverseDuration], [initialProgress], and [revealed] apply only
/// to the internal controller. [loop] works with either controller mode.
class AnimatedFogReveal extends StatefulWidget {
  /// Creates an animated fog reveal.
  const AnimatedFogReveal({
    super.key,
    required this.child,
    this.controller,
    this.duration = const Duration(milliseconds: 2800),
    this.reverseDuration,
    this.initialProgress = 0,
    this.revealed = true,
    this.loop = false,
    this.curve = Curves.easeInOutCubic,
    this.style = const FogStyle(),
    this.borderRadius = BorderRadius.zero,
    this.blockInteraction = false,
    this.excludeSemantics = false,
    this.onEnd,
    this.onError,
    this.onReady,
  }) : assert(initialProgress >= 0 && initialProgress <= 1);

  /// Optional playback controller.
  ///
  /// When omitted, this widget creates and disposes its own controller.
  final FogRevealController? controller;

  /// Reveal duration used by the internal controller. Defaults to 2800 ms.
  final Duration duration;

  /// Optional cover duration used by the internal controller.
  final Duration? reverseDuration;

  /// Initial progress used by the internally created controller, from 0 to 1.
  final double initialProgress;

  /// Whether the child should be revealed when using the internal controller.
  ///
  /// This is ignored when an external [controller] is supplied.
  final bool revealed;

  /// Repeats the reveal from covered to revealed until set to false.
  ///
  /// Disabling it lets the current reveal pass finish. With an internal
  /// controller, looping is inactive while [revealed] is false.
  final bool loop;

  /// Easing applied to the controller's progress.
  final Curve curve;

  /// Content being revealed.
  final Widget child;

  /// Fog appearance and procedural texture settings.
  final FogStyle style;

  /// Clip radius for content and fog.
  final BorderRadius borderRadius;

  /// Block child pointer input until fully revealed.
  final bool blockInteraction;

  /// Exclude child semantics until fully revealed.
  final bool excludeSemantics;

  /// Called when non-repeating playback reaches revealed or covered.
  ///
  /// Also applies to seeking to an endpoint. Not called on initial attachment,
  /// controller replacement, shader readiness, or individual loop cycles.
  final VoidCallback? onEnd;

  /// Shader or texture failure callback.
  final FogErrorCallback? onError;

  /// Called after the shader and texture are ready for playback.
  ///
  /// Runs on the initial load and after seed or texture-size reloads.
  final VoidCallback? onReady;

  @override
  State<AnimatedFogReveal> createState() => _AnimatedFogRevealState();
}

class _AnimatedFogRevealState extends State<AnimatedFogReveal>
    with SingleTickerProviderStateMixin {
  late FogRevealController _controller;
  bool _ready = false;
  bool _managedLoop = false;

  bool get _ownsController => widget.controller == null;

  FogRevealController _createController() => FogRevealController(
        vsync: this,
        duration: widget.duration,
        reverseDuration: widget.reverseDuration,
        value: widget.initialProgress,
      );

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _createController();
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(AnimatedFogReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged) {
      final oldController = _controller;
      if (_managedLoop) oldController.stop();
      _managedLoop = false;
      oldController.removeStatusListener(_onStatus);
      _controller = widget.controller ?? _createController();
      _controller.addStatusListener(_onStatus);
      if (oldWidget.controller == null) oldController.dispose();
      if (_ready) {
        if (widget.loop && (!_ownsController || widget.revealed)) {
          _startLoop();
        } else if (_ownsController) {
          _animateToTarget();
        }
      }
    } else if (_ownsController) {
      final durationChanged = oldWidget.duration != widget.duration;
      _controller
        ..duration = widget.duration
        ..reverseDuration = widget.reverseDuration;
      if (_ready && oldWidget.revealed != widget.revealed) {
        _animateToTarget();
      } else if (_ready && widget.loop && durationChanged) {
        _startLoop();
      }
    }
    if (_ready && !controllerChanged && oldWidget.loop != widget.loop) {
      if (widget.loop) {
        _startLoop();
      } else if (_controller.isAnimating) {
        _managedLoop = false;
        _ownsController && !widget.revealed
            ? _controller.cover()
            : _controller.forward();
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onEnd?.call();
      if (!mounted) return;
    }
    if (status == AnimationStatus.completed &&
        widget.loop &&
        (!_ownsController || widget.revealed)) {
      _controller.repeat();
    }
  }

  void _animateToTarget() {
    _managedLoop = false;
    if (widget.revealed) {
      _controller.reveal();
    } else {
      _controller.cover();
    }
  }

  void _startLoop() {
    if (widget.loop && (!_ownsController || widget.revealed)) {
      _controller.repeat();
      _managedLoop = true;
    }
  }

  void _onReady() {
    final firstReady = !_ready;
    _ready = true;
    widget.onReady?.call();
    if (!mounted) return;
    if (widget.loop && (!_ownsController || widget.revealed)) {
      _startLoop();
    } else if (_ownsController && firstReady) {
      _animateToTarget();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    if (_managedLoop) _controller.stop();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FogTransition(
        animation: _controller,
        curve: widget.curve,
        style: widget.style,
        borderRadius: widget.borderRadius,
        blockInteraction: widget.blockInteraction,
        excludeSemantics: widget.excludeSemantics,
        onError: widget.onError,
        onReady: _onReady,
        child: widget.child,
      );
}
