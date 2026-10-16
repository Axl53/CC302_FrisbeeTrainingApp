# Frisbee Training Program â€” CC 302

A simple student project for beginners who want to learn frisbee drills and schedule practice. Plain Material UI, green theme, standard font, icons and a bundled frisbee image. No login is needed. The Drills tab uses a local Python REST backend (see backend/README.md). Schedules are stored on this device only.

## Run on Windows
1. Install Flutter stable, Android Studio and an Android emulator (or enable USB debugging on an Android phone). Run `flutter doctor` and resolve Android toolchain issues.
2. Extract this ZIP and open the `frisbee_training` folder in VS Code. Install the Flutter extension (which also installs Dart).
3. Open a terminal in this folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
flutter devices
flutter run
```

The setup script generates the standard Android/iOS/web platform folders using your installed Flutter SDK, adds Android Internet permission, installs packages, analyzes the code, and runs the included tests. This download contains application source and bootstrap scripts; it is not a compiled APK or an already generated platform project.

On macOS/Linux: `bash setup.sh`, then `flutter run`. iOS requires macOS/Xcode. For a quick browser check: `flutter run -d chrome`. For a release Android APK after testing: `flutter build apk --release`.

If PowerShell scripts are blocked, run `flutter create --platforms=android,ios,web --project-name frisbee_training .`, then add `<uses-permission android:name="android.permission.INTERNET" />` immediately before `<application` in `android/app/src/main/AndroidManifest.xml`. Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run`.

## Features
- Six drills with instructions, difficulty and duration.
- Drill search and difficulty filter; tap a drill for details.
- Add/edit sessions with date picker and optional notes.
- Mark sessions completed or undo completion; Home displays progress.
- Delete confirmation with Cancel and Delete.
- Sessions and completion saved using shared_preferences.
- Loading indicators, retryable storage errors, and empty states.
- Feedback messages, empty states, scrollable screens and reusable widgets.

The Drills tab fetches the six drills through HTTP, with loading, error, empty states and Retry. Home and scheduling retain bundled drills. Sessions and profiles are saved on this device. See [backend setup](backend/README.md) to start the API and configure its URL.

## Requirement mapping
| Guide requirement | Code |
|---|---|
| AppBar/titles | TrainingHome, DrillDetails, SessionForm |
| Text/colors/fonts/assets | ThemeData, standard system font, Material icons, assets/frisbee.png |
| StatelessWidget | FrisbeeApp, InfoCard, DrillCard, MessageBox, DrillDetails |
| StatefulWidget | TrainingHome, SessionForm |
| Custom widgets | InfoCard, DrillCard, MessageBox |
| ListView.builder | programs(), schedule() |
| Delete | delete(): AlertDialog followed by local storage save |
| Navigation | BottomNavigationBar and Navigator.push/pop |
| Interaction/state | setState, forms, complete/undo, search/filter |
| Loading/errors/empty | loading, saving, loadError, busy, error, MessageBox |
| Extra features | Add/edit, local persistence, progress, filters |

## HCI explanation
Consistency: same theme and buttons. Visibility: labeled tabs and actions. Feedback: snackbars and progress indicators. User control: Cancel on delete and undo completion. Error prevention: constrained drill selector/date picker, notes limit and save validation. Recovery: Retry and errors; a failed save keeps the previous data. Readability: normal Material text and touch targets. Responsive layout: scrolling lists and wrapping action buttons.

## Presentation sequence
1. Introduce purpose and intended users.
2. Open Drills; search Backhand, filter difficulty, show drill instructions.
3. Add a session; choose date and add notes.
4. Edit notes and save.
5. Complete session; show Home progress; undo if needed.
6. Delete a session: cancel first, then confirm.
7. Restart app to demonstrate saved data.
8. Explain StatefulWidget vs StatelessWidget and HCI choices.

## Before submission
Run the backend and Flutter tests using the commands in backend/README.md. Device UI checks still need to be performed locally. Run the setup checks locally and test on a phone before presenting. Check portrait/landscape, larger text size, search with no matches, save/restart, delete cancellation, storage failure and retry.

After setup, push the entire generated project including lib, assets, test, pubspec.yaml, pubspec.lock and platform directories. Exclude build output, local.properties, signing secrets and API credentials. Create a GitHub repository, commit, add its remote and push. Submit the accessible repository URL through CASTLY separately.

## Example introduction
â€œOur app is called Frisbee Training Program. It helps beginners learn drills and organize their practice sessions. Users can search drills, add and edit a schedule, track completed training, and delete sessions. We used a simple interface so users can easily understand the main features.â€

## Likely questions
- Why StatefulWidget? Forms, lists and API screens have data that changes.
- Why StatelessWidget? Display cards receive data and do not own changing state.
- How does delete work? Confirm first, remove selected ID, save updated list.
- Where is data saved? shared_preferences on the current device, as JSON.

Bundled disc illustration created for this project.

## UI organization

- `lib/ui/discfit_widgets.dart`: forest-green design tokens, reusable surfaces, headings, badges, responsive tiles, hero, and bottom navigation.
- `lib/ui/training_cards.dart`: drill cards, details, information cards, and reusable loading-recovery/empty messages.
- `lib/main.dart`: application theme, local session/profile state and forms, screen composition, and quick actions.
- `lib/drills_list.dart` / `lib/drills_api.dart`: HTTP catalog state and network parsing, separate from visual components.

Navigation uses the named `AppTab` enum in this order: Drills, Schedule, Home, Progress, Profile. Home is selected initially. The center Home circle sits inside the navigation bar's reserved space. Selected destinations have a visible indicator and accessibility selection state. Text scaling is preserved; content tiles wrap, pages scroll, and search controls can scroll independently in short landscape viewports. Navigation and completion animations respect reduced-motion settings.

Progress statistics and earned achievements come from locally saved sessions. Home recommendations and schedule choices use the bundled catalog, while the Drills screen displays the API catalog. No example workout counts are displayed.

## Settings

Open the Home gear or the Settings card on Profile. Both open the same screen without changing bottom navigation order.

- Appearance: System follows device brightness; Light and Dark override it throughout routes, cards, forms, and navigation.
- Text size: Default preserves the device text scaler; Large applies an additional 1.2 multiplier, including nonlinear accessibility scaling.
- About: reads the version directly from the bundled project `pubspec.yaml`.
- Clear training history: requires confirmation, deletes only `sessions`, and resets in-memory progress/achievements after a successful storage write. The profile and settings remain saved. Cancel changes nothing.

`lib/settings/app_settings.dart` owns preferences and exposes them above the app Navigator. `lib/settings/settings_screen.dart` contains the shared settings UI. `lib/ui/app_theme.dart` defines the light/dark themes. Preference keys are `appearance` and `largeText`; changes are saved with SharedPreferences and restored before opening Home. Failed saves keep the current preference and show feedback.
