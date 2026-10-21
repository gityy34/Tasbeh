# Azkar content research and implementation decision

## Scope

The feature needs two different offline flows:

- **Subah-o-Shaam Azkar:** the user selects a PDF once and the app opens the
  saved copy on later launches.
- **Rozana ke Azkar:** the user pastes verified text into editable, persistent
  pages and moves between pages with circular previous/next controls.

## Research conclusions

The Android Storage Access Framework (`ACTION_OPEN_DOCUMENT`) is the correct
file-selection mechanism for Android 12 and later. It lets the system file
picker grant access to a user-selected document without requesting broad
storage permissions. The app copies the selected bytes into its own private
`filesDir`, so the document remains available offline and is not dependent on
the original provider or an internet connection.

Android's platform `PdfRenderer` has supported rendering PDF pages since API
21. Rendering the private copy to PNG bytes on a small Kotlin worker executor
keeps file I/O and page rendering away from Flutter's UI thread. Flutter then
provides the responsive themed shell, vertical page scrolling, pinch zoom and
error states.

This native approach was selected over adding a general-purpose PDF plugin:

- it adds no new Flutter dependency or native PDF runtime to the APK;
- it avoids package API/deprecation drift and licensing surprises;
- it keeps the PDF page pixels unchanged while the surrounding app follows
  Light, Dark and Auto themes;
- it gives the app a controlled private-storage boundary and a 50 MB safety
  limit for ordinary phones.

The standard Flutter platform-channel boundary is isolated behind
`AzkarPdfService`, so the UI and controller can be tested with fakes. Daily
Azkar text is stored as schema-versioned JSON in the existing local preference
storage mechanism, with one entry per editable page.

References reviewed for the implementation:

- Android Developers, “Access documents and other files from shared storage”:
  https://developer.android.com/training/data-storage/shared/documents-files
- Android Developers, “Access app-specific files”:
  https://developer.android.com/training/data-storage/app-specific
- Android Developers, `PdfRenderer` reference:
  https://developer.android.com/reference/android/graphics/pdf/PdfRenderer
- Flutter documentation, platform channels:
  https://docs.flutter.dev/platform-integration/platform-channels

No release APK is built as part of this source implementation. Build approval
will be requested only after analysis, automated tests and Android compilation
are clean.
