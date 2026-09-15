import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'fog_style.dart';
import 'noise.dart';

/// Called when shader or texture creation fails. No replacement overlay is drawn.
typedef FogErrorCallback = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Covers any child with organic fog: zero covers, one reveals.
///
/// The child determines layout. Use a SizedBox/AspectRatio for an explicit size.
/// This is a painted overlay, not a blur, child alpha mask, or security boundary.
class FogReveal extends StatefulWidget {
  /// Creates a progress-controlled reveal.
  ///
  /// Use `AnimatedFogReveal` for automatic, declarative, or controller-driven
  /// animation.
  const FogReveal({
    super.key,
    required this.progress,
    required this.child,
    this.motionProgress,
    this.style = const FogStyle(),
    this.borderRadius = BorderRadius.zero,
    this.blockInteraction = false,
    this.excludeSemantics = false,
    this.onError,
    this.onReady,
  });

  /// Reveal fraction. Finite out-of-range values are clamped; NaN is covered.
  /// Positive infinity reveals; negative infinity covers.
  final double progress;

  /// Progress used for cloud motion before reveal easing is applied.
  ///
  /// Defaults to [progress]. `FogTransition` sets this automatically so its
  /// animation matches the original demo.
  final double? motionProgress;

  /// Content that determines this widget's size.
  final Widget child;

  /// Fog appearance and procedural texture settings.
  final FogStyle style;

  /// Clips both child and overlay to this radius.
  final BorderRadius borderRadius;

  /// Ignores child pointer events until progress reaches one when true.
  final bool blockInteraction;

  /// Hides child accessibility semantics until fully revealed when true.
  final bool excludeSemantics;

  /// Reports load failures once per attempt. The child remains visible on failure.
  final FogErrorCallback? onError;

  /// Called after shader and texture are ready, including after seed/size changes.
  ///
  /// Use this to start externally controlled playback after loading.
  final VoidCallback? onReady;

  @override
  State<FogReveal> createState() => _FogRevealState();
}

ui.FragmentProgram? _program;
Future<ui.FragmentProgram>? _pendingProgram;
Future<ui.FragmentProgram> _loadProgram() async {
  final cached = _program;
  if (cached != null) return cached;
  final pending = _pendingProgram ??= ui.FragmentProgram.fromAsset(
      'packages/fog_reveal/shaders/fog_reveal.frag');
  try {
    return _program = await pending;
  } finally {
    if (identical(_pendingProgram, pending)) _pendingProgram = null;
  }
}

class _FogRevealState extends State<FogReveal> {
  ui.FragmentShader? _shader;
  NoiseTextureLease? _texture;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.style.validate();
    _load();
  }

  @override
  void didUpdateWidget(FogReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.style.validate();
    if (oldWidget.style.seed != widget.style.seed ||
        oldWidget.style.textureSize != widget.style.textureSize) {
      _generation++;
      _release();
      _load();
    }
  }

  void _release() {
    _shader?.dispose();
    _texture?.release();
    _shader = null;
    _texture = null;
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final style = widget.style;
    NoiseTextureLease? texture;
    ui.FragmentShader? shader;
    var ready = false;
    try {
      final program = await _loadProgram();
      if (!mounted || generation != _generation) return;
      texture = await acquireNoiseTexture(
        size: style.textureSize,
        seed: style.seed,
      );
      if (!mounted || generation != _generation) return;
      shader = program.fragmentShader();
      shader.setImageSampler(0, texture.image);
      setState(() {
        _texture = texture;
        _shader = shader;
      });
      // Ownership has transferred to State.
      texture = null;
      shader = null;
      ready = true;
    } catch (error, stack) {
      if (mounted && generation == _generation) {
        widget.onError?.call(error, stack);
      }
    } finally {
      shader?.dispose();
      texture?.release();
    }
    if (ready && mounted && generation == _generation) widget.onReady?.call();
  }

  @override
  void dispose() {
    _generation++;
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.isNaN ? 0.0 : widget.progress.clamp(0.0, 1.0);
    final rawMotion = widget.motionProgress ?? widget.progress;
    final motion = rawMotion.isNaN ? 0.0 : rawMotion.clamp(0.0, 1.0);
    final shader = _shader;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ExcludeSemantics(
              excluding: widget.excludeSemantics && p < 1,
              child: IgnorePointer(
                ignoring: widget.blockInteraction && p < 1,
                child: widget.child,
              ),
            ),
            if (shader != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _FogPainter(shader, p, motion, widget.style),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  _FogPainter(this.shader, this.progress, this.motionProgress, this.style);
  final ui.FragmentShader shader;
  final double progress;
  final double motionProgress;
  final FogStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, motionProgress * style.drift)
      ..setFloat(3, progress)
      ..setFloat(4, style.color.r)
      ..setFloat(5, style.color.g)
      ..setFloat(6, style.color.b)
      ..setFloat(7, style.color.a)
      ..setFloat(8, style.softness);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FogPainter oldDelegate) =>
      shader != oldDelegate.shader ||
      progress != oldDelegate.progress ||
      motionProgress != oldDelegate.motionProgress ||
      style != oldDelegate.style;
}
