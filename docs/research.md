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

## Reference home layout decisions

The latest reference was implemented as one shared home composition rather than a
different layout per palette. This keeps the counter circle, Tasbeh selector, target
row, and action row aligned across light, dark, nature, and water variants while the
palette-specific painter continues to own the visual treatment inside the counter.

The Tasbeh picker uses Flutter's built-in `showModalBottomSheet` with a scrollable,
semantics-friendly list. It avoids a dependency for a small interaction, preserves
one-handed use, and lets the selected Arabic phrase remain real RTL text instead of
being baked into an image. The selected phrase is stored in the existing settings
JSON, so older saved state falls back safely to Bismillah.

Target controls are circular, keep a minimum 48 logical-pixel touch area, and use the
reference order 33, 100, 313, 1000, and infinity. Reaching a finite target returns an
explicit completion signal from the controller; the UI uses Flutter's built-in
`HapticFeedback.mediumImpact` once at that boundary, without adding a package or
re-triggering haptics on taps after completion. Blank space in the main content is a
counting surface, while all visible controls retain their own actions.

The follow-up layout keeps the larger count-only water circle shared by every
palette and moves Target, its five compact selectors, Reset, and Save into one
responsive panel bounded by top and bottom dividers. Completion progress text is
not duplicated in the visual counter; the selected target remains available
through the controls and accessibility labels. Target completion haptics are
enabled by default and persisted through settings, with a user-facing switch in
Settings to turn them off. Flutter's built-in haptic API is sufficient, so no
runtime permission or extra package is needed.

## Offline reminder research and decision

The reminder implementation uses `flutter_local_notifications` 22.3.2, the
latest non-prerelease release verified on 2026-10-19, and `timezone` 0.11.0.
The plugin is actively maintained, supports Android notification permission
checks, exact-alarm access, app-notification settings, reboot restoration,
timezone-aware `zonedSchedule`, and daily matching. Version 23 was rejected
because the available release was still a development prerelease. Firebase,
cloud messaging, background web services, and a continuously running timer are
not needed.

Daily reminders use `zonedSchedule` with `DateTimeComponents.time`. The device's
IANA timezone ID comes from a tiny Android platform channel, avoiding another
timezone-discovery dependency. Exact scheduling uses
`AndroidScheduleMode.exactAllowWhileIdle` only when Android grants exact-alarm
access; otherwise the service uses `inexactAllowWhileIdle` and the UI explains
that Android may delay delivery. `SCHEDULE_EXACT_ALARM` is used rather than the
more policy-restricted `USE_EXACT_ALARM` permission.

The plugin's documented scheduled-notification and boot receivers restore
enabled schedules after reboot and app replacement. A minimal time-change
receiver asks the same plugin scheduler to recalculate cached timezone-aware
alarms after the system clock or timezone changes. Opening or resuming the app
also performs an idempotent resynchronization. Stable persisted notification IDs
and cancel-before-schedule updates prevent duplicates.

Android 13 notification permission is requested only after an in-app explanation
when the user enables or adds reminders. The Settings UI exposes permission
state and links to Android settings. Android force-stop and aggressive OEM
battery restrictions remain operating-system limitations and are described
honestly in the screen.

Reminder data is stored under a separate schema-versioned key, so existing
counter, checkpoint, theme, and Arabic content storage remains untouched. The
notification plugin is hidden behind a service interface and the controller is
tested with a fake scheduler.

Official/current references reviewed:

- https://developer.android.com/develop/ui/views/notifications/notification-permission
- https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- https://developer.android.com/reference/android/Manifest.permission#SCHEDULE_EXACT_ALARM
- https://github.com/MaikuB/flutter_local_notifications/releases/tag/flutter_local_notifications-v22.3.2
- https://github.com/MaikuB/flutter_local_notifications/tree/flutter_local_notifications-v22.3.2/flutter_local_notifications

