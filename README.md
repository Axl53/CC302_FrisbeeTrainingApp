# DiscFit - Frisbee Training App

A Flutter student project for beginner frisbee players. Learn drills, plan practice, and track completed sessions in a forest-green interface.

## Run

From the project folder in the VS Code terminal:

```powershell
flutter pub get
flutter run
```

For a browser: `flutter run -d chrome`. For Android: start an emulator or connect a phone, then use `flutter run`. No local API server or second terminal is required.

## API integration: Weather

Tap the cloud icon labeled Weather on Home. Select Tagbilaran, Cebu, or Manila to see temperature, wind speed and weather conditions. The app calls the public Open-Meteo HTTPS API directly; internet is needed for weather only. No API key is required for this non-commercial student project.

Source and documentation: https://open-meteo.com/en/docs (CC BY 4.0).

- Loading indicator while fetching.
- 12-second timeout, readable errors and Retry.
- Separate empty state when current conditions are unavailable.
- Refresh and city selection; an older city's response cannot overwrite the new selection.
- Weather observation time is displayed in Philippine time. No sample weather is substituted on failure.

All six training drills are bundled in `lib/drill.dart` and work offline, including search, difficulty filtering and instructions. The previous local drills backend has been removed.

## Features and navigation

Bottom navigation: Drills | Schedule | Home | Progress | Profile. Home opens by default, with a circular elevated center button.

- Home: disc photo, training categories and working quick actions.
- Drills: search, difficulty filter, duration and instructions.
- Schedule: add/edit, date picker, notes validation, complete/undo, and confirmed deletion.
- Progress: statistics and achievements calculated from saved sessions.
- Profile: locally saved name, skill level and optional location.
- Settings: System/Light/Dark theme, Default/Large text, About, and confirmed training-history clearing.

Sessions, profile and preferences use SharedPreferences. Clearing history removes sessions and resets progress/achievements, keeping profile and settings. Appearance changes apply throughout the app; Large text adds 20% while respecting device accessibility scaling. About reads version metadata from the bundled project pubspec.yaml.

## Code organization

- `lib/main.dart`: app preferences, navigation, session storage, profile and forms.
- `lib/drill.dart` / `lib/drills_list.dart`: bundled drill catalog and searchable list.
- `lib/weather/weather_api.dart`: HTTPS request, JSON validation and weather model.
- `lib/weather/weather_screen.dart`: city selection and loading/error/empty/success states.
- `lib/ui/`: reusable surfaces, badges, statistics, photo, navigation and light/dark themes.
- `lib/settings/`: preference persistence and the shared Settings screen, opened from Home and Profile.

The user's photo at `assets/images/frisbee_disc.jpg` uses Image.asset, contain in the hero and cover for thumbnails, with rounded corners and separate text.

## Checks

```powershell
flutter analyze
flutter test
```

Before presenting, test weather with internet, then turn it off and demonstrate Retry. Show offline drills, add/edit/complete a session, view real progress, cancel a delete, and restart to demonstrate persistence. Check portrait, landscape and larger text on the target phone/emulator.

## HCI and presentation

Consistency: shared green theme and reusable controls. Visibility: labeled tabs, session status, weather time and progress. Feedback: loading indicators and snackbars. User control: cancel deletion, undo completion and retry requests. Error prevention: validated forms, constrained drill selection and confirmation before clearing history. Readability: scrolling layouts, responsive cards and device text scaling.

StatefulWidget owns changing data (forms, weather and local sessions). StatelessWidget displays supplied data (cards, drill list and photo). The weather API demonstrates HTTP and JSON; SharedPreferences demonstrates local persistence.
