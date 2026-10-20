# Tasbeh

An offline-first Flutter Tasbeh counter designed around a calm water surface,
large touch targets, persistent checkpoints, and device-local daily reminders.

## Structure

- `lib/models`: serializable settings, checkpoint, and reminder models.
- `lib/services`: persistence, notification, permission, and haptic boundaries.
- `lib/repositories`: schema-versioned reminder persistence.
- `lib/controllers`: reminder scheduling and state coordination.
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
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

The universal APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
Smaller device-specific APKs are written to the same directory as
`app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, and
`app-x86_64-release.apk`. The AAB is written to
`build/app/outputs/bundle/release/app-release.aab`.

The app supports Android API 21 and newer, including Android 12+. CI publishes
the universal APK as the primary demo because it contains the supported native
ABIs and avoids an install failure caused by choosing the wrong device-specific
APK. ABI-specific APKs are available only when the device architecture is
confirmed. Demo APKs are signed with the runner's debug key; use a private
release keystore before publishing to Google Play.

The app requests Android notification access only after the user enables or adds
a reminder. Exact alarm access is optional; when it is unavailable, reminders
use Android's inexact fallback and may be delayed. Reminder scheduling is local
and needs no account, Firebase, or internet connection. Configure a real Android
release keystore before publishing; no signing credentials are included here.

## Versioning

The current release line is `v1.0.6`. Every new downloadable APK
increments the version name (`v1.0.5`, `v1.0.6`, and so on). GitHub Actions uses
the workflow run number as the Android build number and includes the version in
each APK filename and release tag.

The `v1.0.6` demo uses the unique `com.gityy34.tasbeh` application ID and
legacy native-library packaging for Android 15/16 installation compatibility.

## GitHub Actions

The repository workflow in `.github/workflows/flutter.yml` runs analysis and tests,
builds a universal APK, smaller ABI-specific APKs, and an AAB, then verifies APK
signatures and package integrity before uploading separate artifacts. See
[docs/release.md](docs/release.md) for the exact procedure.

