import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

final _textureCache = <(int, int), _NoiseTextureEntry>{};

class _NoiseTextureEntry {
  _NoiseTextureEntry(this.image);

  final Future<ui.Image> image;
  int users = 0;
}

/// A shared noise texture reference used internally by fog widgets.
class NoiseTextureLease {
  NoiseTextureLease._(this.image, this._key, this._entry);

  /// The decoded texture shared by widgets with the same seed and size.
  final ui.Image image;
  final (int, int) _key;
  final _NoiseTextureEntry _entry;
  bool _released = false;

  /// Releases this reference and disposes the texture after its last user.
  void release() {
    if (_released) return;
    _released = true;
    _entry.users--;
    if (_entry.users == 0 && identical(_textureCache[_key], _entry)) {
      _textureCache.remove(_key);
      image.dispose();
    }
  }
}

/// Shares a generated texture between active widgets with matching settings.
Future<NoiseTextureLease> acquireNoiseTexture({
  required int size,
  required int seed,
}) async {
  final key = (size, seed);
  final entry = _textureCache.putIfAbsent(
    key,
    () => _NoiseTextureEntry(createNoiseTexture(size: size, seed: seed)),
  );
  entry.users++;
  try {
    return NoiseTextureLease._(await entry.image, key, entry);
  } catch (_) {
    entry.users--;
    if (entry.users == 0 && identical(_textureCache[key], entry)) {
      _textureCache.remove(key);
    }
    rethrow;
  }
}

/// Creates an owned seamless grayscale texture. Caller must dispose it.
Future<ui.Image> createNoiseTexture({
  required int size,
  required int seed,
}) async {
  final pixels = Uint8List(size * size * 4);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final nx = x / size;
      final ny = y / size;
      final value = _fractalNoise(nx, ny, seed);
      final shade = math.max(0, math.min(255, (value * 255).round()));
      final index = (y * size + x) * 4;

      pixels[index] = shade;
      pixels[index + 1] = shade;
      pixels[index + 2] = shade;
      pixels[index + 3] = 255;
    }
  }

  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;

  try {
    descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: size,
      height: size,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

double _fractalNoise(double x, double y, int seed) {
  var sum = 0.0;
  var amplitude = 0.56;
  var amplitudeSum = 0.0;
  var cells = 2;

  for (var octave = 0; octave < 5; octave++) {
    sum += _periodicValueNoise(
          x * cells,
          y * cells,
          period: cells,
          seed: seed + octave * 101,
        ) *
        amplitude;
    amplitudeSum += amplitude;
    amplitude *= 0.52;
    cells *= 2;
  }

  final normalized = sum / amplitudeSum;
  return _smoothStep(0.08, 0.92, normalized);
}

double _periodicValueNoise(
  double x,
  double y, {
  required int period,
  required int seed,
}) {
  final xFloor = x.floor();
  final yFloor = y.floor();
  final x0 = xFloor % period;
  final y0 = yFloor % period;
  final x1 = (x0 + 1) % period;
  final y1 = (y0 + 1) % period;
  final tx = _fade(x - xFloor);
  final ty = _fade(y - yFloor);

  final top =
      _lerp(_latticeRandom(x0, y0, seed), _latticeRandom(x1, y0, seed), tx);
  final bottom =
      _lerp(_latticeRandom(x0, y1, seed), _latticeRandom(x1, y1, seed), tx);

  return _lerp(top, bottom, ty);
}

double _latticeRandom(int x, int y, int seed) {
  var hash = x * 374761393 + y * 668265263 + seed * 69069;
  hash = (hash ^ (hash >> 13)) * 1274126177;
  hash ^= hash >> 16;
  return (hash & 0x7FFFFFFF) / 0x7FFFFFFF;
}

double _fade(double value) {
  return value * value * value * (value * (value * 6 - 15) + 10);
}

double _lerp(double start, double end, double amount) {
  return start + (end - start) * amount;
}

double _smoothStep(double start, double end, double value) {
  final t = ((value - start) / (end - start)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
