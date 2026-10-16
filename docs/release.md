# Release procedure

The repository includes a GitHub Actions workflow at `.github/workflows/flutter.yml`.

It runs on pushes to `main`, pull requests, and manual dispatches. The workflow:

1. Installs the current Flutter stable channel on an Ubuntu runner.
2. Resolves packages.
3. Runs `flutter analyze`.
4. Runs the controller and persistence tests.
5. Builds a release APK and AAB.
6. Stores both files as the `tasbeh-android-release` workflow artifact.

To run it manually, open the repository's **Actions** tab, select **Flutter checks and Android artifacts**, click **Run workflow**, choose `main`, and start the run. Download the artifacts from the completed run.

The current Android Gradle configuration intentionally does not contain signing credentials. The generated release artifact is suitable for build validation, but a production Play Store release needs a private keystore configured through GitHub Actions secrets and a release signing configuration. Never commit a keystore or password.

