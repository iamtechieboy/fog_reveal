# Validation — 0.0.1

Checked on 2026-09-15 with the local stable Flutter toolchain.

| Check | Result |
| --- | --- |
| Dart formatting | Passed |
| Public API documentation | Passed, no warnings or errors |
| `flutter analyze` | Passed, no issues |
| Package widget/unit tests | Passed, 13 tests |
| Consumer example tests | Passed, 7 tests |
| Release web build | Passed |
| Flutter build Wasm dry run | Passed |
| `flutter pub publish --dry-run` | Valid 80 KiB archive, no warnings |

The dry run did not upload anything. The package metadata points to the public
source repository and validation completes without warnings.

Tests cover the real packaged shader, organic pixel output and endpoints,
declarative loader state changes, controller playback, progress clamping,
callbacks, pointers, semantics, empty layouts, failure handling, seeded noise,
shared textures, initial progress, resource reload without replay, managed-loop
controller replacement, and disposal.

Not tested: physical devices, browser runtime interaction, the minimum supported
SDK, pub.dev package-name availability, or authenticated server-side publication.
