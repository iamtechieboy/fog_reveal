#version 320 es

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uProgress;
uniform vec4 uColor;
uniform float uSoftness;
uniform sampler2D uNoise;

out vec4 fragColor;

void main() {
  vec2 position = FlutterFragCoord().xy;
  float shortestSide = max(min(uSize.x, uSize.y), 1.0);
  vec2 uv = position / shortestSide;

  vec2 firstDrift = vec2(uTime * 0.025, -uTime * 0.015);
  vec2 secondDrift = vec2(-uTime * 0.018, uTime * 0.022);

  float largeClouds = texture(
    uNoise,
    fract(uv * 0.62 + firstDrift)
  ).r;
  float smallClouds = texture(
    uNoise,
    fract(uv * 1.17 + secondDrift + vec2(0.31, 0.67))
  ).r;

  float noise = largeClouds * 0.72 + smallClouds * 0.28;
  noise = smoothstep(0.12, 0.88, noise);

  // At 0 everything is fog; at 1 the fog has organically dissolved.
  float threshold = mix(1.0 + 2.0 * uSoftness, -1.2 * uSoftness, uProgress);
  float fog = 1.0 - smoothstep(
    threshold - uSoftness,
    threshold + uSoftness,
    noise
  );

  float alpha = fog * uColor.a;
  vec3 fogColor = uColor.rgb;

  // Flutter expects premultiplied alpha from runtime-effect shaders.
  fragColor = vec4(fogColor * alpha, alpha);
}
