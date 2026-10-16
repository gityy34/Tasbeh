# Implementation research notes

The implementation follows the current Flutter platform guidance available for the project setup:

- Flutter app architecture: keep UI, state, services, and models separate, while using the smallest state solution that fits the app. This project uses `ChangeNotifier` from Flutter itself instead of a large state-management dependency.
- Flutter animations: use `AnimationController` only inside a `StatefulWidget`, dispose it, and repaint the smallest possible area. The water surface is a `CustomPainter` driven by a single controller and uses `Listenable` repainting.
- Flutter theming: use `ThemeData`, `ColorScheme`, `ThemeMode`, and `MediaQuery`/`SafeArea`; do not hard-code system bar behavior in each screen.
- Persistence: use the maintained `shared_preferences` plugin from the Flutter packages ecosystem. The service is isolated behind a small interface so it can be replaced by a database later without changing the UI.
- Android startup: the native launch theme is intentionally minimal, while the branded day/night splash is rendered by Flutter after the engine is ready. This avoids putting a large bitmap in the Android launch resource.
- Accessibility: interactive controls use semantic labels and at least 48 logical pixels of touch area; progress is also exposed as text rather than relying on color alone.

Official references:

- https://docs.flutter.dev/app-architecture
- https://docs.flutter.dev/cookbook/animation/animation-controller
- https://docs.flutter.dev/cookbook/design/themes
- https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
- https://pub.dev/packages/shared_preferences
- https://developer.android.com/develop/ui/views/launch/splash-screen

The design references were translated into a small responsive layout: a day/night arch splash, a water-like circular counter, five target presets, and bottom actions that remain reachable one-handed. The exact Bismillah string is rendered as Flutter text with RTL direction rather than trusting text baked into artwork, so Arabic shaping remains a real text-rendering responsibility.

