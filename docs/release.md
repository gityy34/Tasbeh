# Release procedure

The repository includes a GitHub Actions workflow at `.github/workflows/flutter.yml`.

It runs on pushes to `main`, pull requests, and manual dispatches. The workflow:

1. Installs the current Flutter stable channel on an Ubuntu runner.
2. Resolves packages.
3. Runs `flutter analyze`.
4. Runs the controller and persistence tests.
5. Builds a universal release APK, smaller ABI-specific APKs, and an AAB.
6. Verifies APK package integrity and signatures.
7. Publishes a universal demo APK first, plus arm64, armv7, and x86_64 APKs.

To run it manually, open the repository's **Actions** tab, select **Flutter checks and Android artifacts**, click **Run workflow**, choose `main`, and start the run. Download `tasbeh-universal.apk` for the safest direct install when the device architecture is unknown. Use an ABI-specific APK only when the device architecture is confirmed. The AAB is for Play distribution and cannot be installed directly.

Each downloadable APK release increments the version in `pubspec.yaml`. The
current release line is `v1.0.4`; CI includes that version in the release tag and
APK filenames, while the GitHub Actions run number supplies the Android build
number.

The demo APK is signed with the CI runner's debug key so it is directly installable for testing. It is not a production signing key. A production Play Store release needs a private keystore configured through GitHub Actions secrets and a release signing configuration. Never commit a keystore or password.

