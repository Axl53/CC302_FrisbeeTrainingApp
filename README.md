# Frisbee Training Program — CC 302

A simple student project for beginners who want to learn frisbee drills and schedule practice. Plain Material UI, green theme, standard font, icons and a bundled frisbee image. No login or backend is needed. Schedules are stored on this device only.

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
- Open-Meteo weather for Tagbilaran, Cebu and Manila: temperature, wind and conditions.
- Loading indicator, API timeout, Retry, and explicitly labeled offline sample.
- Feedback messages, empty states, scrollable screens and reusable widgets.

Drills are bundled local content. Weather is the API integration. The app does not pretend that local drills were downloaded. Offline sample weather is not a successful API call; demonstrate live weather with working Internet when possible.

## Requirement mapping
| Guide requirement | Code |
|---|---|
| AppBar/titles | TrainingHome, DrillDetails, SessionForm |
| Text/colors/fonts/assets | ThemeData, standard system font, Material icons, assets/frisbee.png |
| StatelessWidget | FrisbeeApp, InfoCard, DrillCard, MessageBox, DrillDetails |
| StatefulWidget | TrainingHome, SessionForm, WeatherScreen |
| Custom widgets | InfoCard, DrillCard, MessageBox |
| ListView.builder | programs(), schedule() |
| API integration | WeatherScreen.fetch(): HTTPS GET, JSON decode |
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
6. Open Weather and demonstrate live API data; change city and refresh.
7. Disable Internet and refresh; explain error, Retry, and offline sample.
8. Delete a session: cancel first, then confirm.
9. Restart app to demonstrate saved data.
10. Explain StatefulWidget vs StatelessWidget and HCI choices.

## Before submission
This environment did not have Flutter/Dart, so compilation, automated tests and device UI checks could not be executed here. Run the setup checks locally and test on a phone before presenting. Check portrait/landscape, larger text size, search with no matches, save/restart, delete cancellation, API success/failure and release-build Internet access.

After setup, push the entire generated project including lib, assets, test, pubspec.yaml, pubspec.lock and platform directories. Exclude build output, local.properties, signing secrets and API credentials. Create a GitHub repository, commit, add its remote and push. Submit the accessible repository URL through CASTLY separately.

## Example introduction
“Our app is called Frisbee Training Program. It helps beginners learn drills and organize their practice sessions. Users can search drills, add and edit a schedule, track completed training, and delete sessions. It also uses a weather API to show outdoor conditions. We used a simple interface so users can easily understand the main features.”

## Likely questions
- Why StatefulWidget? Forms, lists and API screens have data that changes.
- Why StatelessWidget? Display cards receive data and do not own changing state.
- Where is the API? WeatherScreen.fetch() calls Open-Meteo and decodes its response.
- How does delete work? Confirm first, remove selected ID, save updated list.
- Where is data saved? shared_preferences on the current device, as JSON.
- What if API fails? Display error and Retry; sample is labeled for offline demonstration.

Weather source: https://open-meteo.com/ (CC BY 4.0). Bundled disc illustration created for this project.
