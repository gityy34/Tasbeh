# Release procedure

The repository includes a GitHub Actions workflow at `.github/workflows/flutter.yml`.

It runs on pushes to `main`, pull requests, and manual dispatches. The workflow:

1. Installs the current Flutter stable channel on an Ubuntu runner.
2. Resolves packages.
3. Runs `flutter analyze`.
4. Runs the controller and persistence tests.
5. Builds a universal release APK, smaller ABI-specific APKs, and an AAB.
6. Verifies APK package integrity and signatures.
7. Stores the demo APK, smaller APKs, and AAB as separate workflow artifacts.

To run it manually, open the repository's **Actions** tab, select **Flutter checks and Android artifacts**, click **Run workflow**, choose `main`, and start the run. Download `tasbeh-demo-apk` for the easiest install. Extract it and install `app-release.apk` on Android 12 or newer. Use `tasbeh-small-apks` and the `arm64-v8a` file for a smaller download on most modern phones. The AAB is for Play distribution and cannot be installed directly.

The demo APK is signed with the CI runner's debug key so it is directly installable for testing. It is not a production signing key. A production Play Store release needs a private keystore configured through GitHub Actions secrets and a release signing configuration. Never commit a keystore or password.

