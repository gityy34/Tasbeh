# Tasbeh

An offline-first Flutter Tasbeh counter designed around a calm water surface, large touch targets, and persistent checkpoints.

## Structure

- `lib/models`: serializable settings and checkpoint models.
- `lib/services`: persistence boundary.
- `lib/state`: counter state and application controller.
- `lib/theme`: theme and palette definitions.
- `lib/widgets`: reusable counter, splash artwork, and controls.
- `lib/screens`: app screens.
- `test`: counter and persistence-focused tests.

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Release builds

```sh
flutter build apk --release
flutter build appbundle --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`; the AAB is written to `build/app/outputs/bundle/release/app-release.aab`.

The project does not request runtime permissions. Configure a real Android release keystore before publishing; no signing credentials are included here.

## GitHub Actions

The repository workflow in `.github/workflows/flutter.yml` runs analysis and tests, then builds APK and AAB artifacts on GitHub's Android-capable runner. See [docs/release.md](docs/release.md) for the exact procedure.

