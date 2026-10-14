#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
flutter create --platforms=android,ios,web --project-name frisbee_training .
python3 - <<'PY'
from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
if 'android.permission.INTERNET' not in s:
    p.write_text(s.replace('<application', '<uses-permission android:name="android.permission.INTERNET" /><application', 1))
PY
flutter pub get
flutter analyze
flutter test
printf 'Setup complete. Run: flutter run\n'
