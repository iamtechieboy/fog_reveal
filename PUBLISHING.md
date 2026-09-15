# Publishing 0.0.1

Prepared locally; publication is deferred until requested by the owner.

1. Confirm package-name availability in the intended pub.dev account and keep the
   MIT copyright attribution accurate. If renaming, also update imports, the
   shader package prefix, example dependency and documentation.
2. Run the checks from the package directory:

   ```sh
   flutter pub get
   dart format --output=none --set-exit-if-changed lib test example/lib example/test
   flutter analyze
   flutter test
   dart doc
   cd example
   flutter pub get
   flutter test
   flutter build web --release
   cd ..
   flutter pub publish --dry-run
   ```

3. Inspect the dry-run archive listing, resolve warnings and smoke-test intended
   target devices. See VALIDATION.md for checks already completed.
4. When publication is requested, run `flutter pub publish`, authenticate with the
   owner's pub.dev account, and review the upload prompt.

Official guide: [Publishing packages](https://dart.dev/tools/pub/publishing).
