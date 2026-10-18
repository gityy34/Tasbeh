# Implementation research notes

The implementation follows the current Flutter platform guidance available for the project setup:

- Flutter app architecture: keep UI, state, services, and models separate, while using the smallest state solution that fits the app. This project uses `ChangeNotifier` from Flutter itself instead of a large state-management dependency.
- Flutter animations: use `AnimationController` only inside a `StatefulWidget`, dispose it, and repaint the smallest possible area. The water surface is a `CustomPainter` driven by a single controller and uses `Listenable` repainting.
- Flutter theming: use `ThemeData`, `ColorScheme`, `ThemeMode`, and `MediaQuery`/`SafeArea`; do not hard-code system bar behavior in each screen.
- Persistence: use the maintained `shared_preferences` plugin from the Flutter packages ecosystem. The service is isolated behind a small interface so it can be replaced by a database later without changing the UI.
- Android startup: the native launch theme is intentionally minimal, while the branded day/night splash is rendered by Flutter after the engine is ready. This avoids putting a large bitmap in the Android launch resource.
- Accessibility: interactive controls use semantic labels and at least 48 logical pixels of touch area; progress is also exposed as text rather than relying on color alone.

## Realistic Water Theme decision

The uploaded reference was treated as a visual direction, not as a static screen. The
counter remains a real Flutter layout so the count, target, progress, accessibility
semantics, and tap target continue to work.

For the water effect, the practical options were:

- A Flutter `CustomPainter` driven by a finite `AnimationController`: no new dependency,
  precise control over a falling droplet, splash rings, highlights, and the settling time.
- Lottie/Rive: useful for a pre-authored animation, but adds an asset/runtime dependency
  and does not naturally respond to the counter's live progress and theme colors.
- A fragment shader: potentially more physically detailed, but adds shader lifecycle,
  device compatibility, and tuning complexity that is not justified for this counter.

The implementation uses the first option. The existing Water palette keeps its ambient
wave behavior. `Realistic Water Theme` uses one shared ticker only while a drop, ripple,
or fish needs repainting. Each tap owns an independent drop timeline, so rapid taps do
not restart or cancel earlier drops. A relaxed tap falls at the normal speed; closely
spaced taps use a bounded speed boost. Every impact keeps its ripple for up to three
seconds and the surface then settles to a still state. This keeps the effect responsive
on ordinary Android phones without adding a permanently running shader or animation
runtime. The theme's palette and text-color choices remain in Settings; no color
controls are added to the counter page.

The fish effect is also painter-based: a golden fish enters on tap 10 and a red fish on
tap 30, each transforming from its colored drop when it reaches the waterline. Fish
movement, breathing bubbles, and gradual growth are deterministic and clipped to the
water sphere. Growth is capped at the size reached at tap 50, preventing unbounded
visual or memory growth during long sessions. Active drops are bounded to 32 so a
continuous rapid-tap session remains safe on ordinary phones.

Official references:

- https://docs.flutter.dev/app-architecture
- https://docs.flutter.dev/cookbook/animation/animation-controller
- https://docs.flutter.dev/cookbook/design/themes
- https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
- https://pub.dev/packages/shared_preferences
- https://developer.android.com/develop/ui/views/launch/splash-screen

The design references were translated into a small responsive layout: a day/night arch splash, a water-like circular counter, five target presets, and bottom actions that remain reachable one-handed. The exact Bismillah string is rendered as Flutter text with RTL direction rather than trusting text baked into artwork, so Arabic shaping remains a real text-rendering responsibility.

