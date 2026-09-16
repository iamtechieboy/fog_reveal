## 0.0.4

- Fixed pub.dev screenshots

## 0.0.2

- Add pub.dev screenshots showing the default reveal and customizable styles.
- Add the same visual preview to the English and Uzbek package READMEs.

## 0.0.1

- Initial release of the organic fog reveal shader for Flutter widgets and
  images.
- Match the reference demo's two-layer noise, motion, dissolve, color, timing,
  curve, and seeded pattern.
- Add controller-free declarative playback through `revealed`, plus optional
  duration, reverse duration, initial progress, and looping.
- Add `FogRevealController` controls for reveal, cover, replay, pause, resume,
  seek, toggle, and standard `AnimationController` operations.
- Add direct `FogReveal` progress and generic `FogTransition` animation APIs.
- Add configurable color, softness, drift, seed, and texture size, with demo,
  light, dark, mist, and lightweight presets.
- Share matching noise textures between active widgets and safely dispose async,
  replaced, and widget-managed resources.
- Preserve initial progress and current playback across texture reloads; safely
  transfer managed loops when controllers are replaced.
- Add pointer and semantics controls, readiness/error callbacks, API docs,
  runnable examples, and shader/lifecycle regression tests.
