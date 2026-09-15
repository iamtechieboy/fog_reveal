import 'package:flutter/widgets.dart';

/// Appearance and procedural texture settings for a fog overlay.
@immutable
class FogStyle {
  /// Creates custom fog settings.
  const FogStyle({
    this.color = const Color(0xFFF0F2F2),
    this.softness = 0.1,
    this.drift = 6,
    this.seed = 1709,
    this.textureSize = 256,
  })  : assert(softness > 0 && softness <= 0.5),
        assert(drift >= -1000 && drift <= 1000),
        assert(seed >= 0 && seed <= 0x7fffffff),
        assert(textureSize >= 16 && textureSize <= 512);

  /// The original demo appearance.
  static const demo = FogStyle();

  /// Light fog matching the original demo.
  static const light = FogStyle();

  /// Dark blue fog for dark surfaces.
  static const dark = FogStyle(color: Color(0xFF172033));

  /// Soft, translucent mist.
  static const mist =
      FogStyle(color: Color(0xB3F0F2F2), softness: 0.2, drift: 3);

  /// Demo appearance with a smaller texture for image lists and grids.
  static const lightweight = FogStyle(textureSize: 128);

  /// Fog tint; alpha controls maximum opacity, including at progress zero.
  final Color color;

  /// Dissolve edge width, in (0, 0.5].
  final double softness;

  /// Texture travel over the reveal. The demo uses 6.
  ///
  /// Zero freezes the clouds and a negative value reverses their directions.
  /// Range: `-1000` through `1000`. No independent idle ticker is created.
  final double drift;

  /// Repeatable pattern seed from `0` through `2147483647`.
  ///
  /// The pattern is stable for the same Dart target/runtime; integer behavior
  /// can produce a different pattern between native and web builds.
  final int seed;

  /// Square texture resolution from `16` through `512`.
  ///
  /// Only seed or size changes rebuild the texture.
  final int textureSize;

  /// Returns a copy with selected properties replaced.
  FogStyle copyWith({
    Color? color,
    double? softness,
    double? drift,
    int? seed,
    int? textureSize,
  }) =>
      FogStyle(
        color: color ?? this.color,
        softness: softness ?? this.softness,
        drift: drift ?? this.drift,
        seed: seed ?? this.seed,
        textureSize: textureSize ?? this.textureSize,
      );

  /// Validates settings in release builds as well as debug builds.
  void validate() {
    if (!softness.isFinite ||
        softness <= 0 ||
        softness > 0.5 ||
        !drift.isFinite ||
        drift < -1000 ||
        drift > 1000 ||
        seed < 0 ||
        seed > 0x7fffffff ||
        textureSize < 16 ||
        textureSize > 512) {
      throw ArgumentError('Invalid FogStyle values. See property ranges.');
    }
  }
}
