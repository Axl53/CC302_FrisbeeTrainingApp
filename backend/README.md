# Drills REST API

Python 3 standard library only; no packages or API key required. From the project root:

```powershell
python backend/server.py
```

Leave that terminal running. In a second terminal:

```powershell
flutter run -d chrome
```

The app uses `http://localhost:8000` on web/iOS simulator and `http://10.0.2.2:8000` on Android emulator. Open the Drills tab to fetch data. The Android debug manifest permits local HTTP. For release hosting, use HTTPS and configure its URL.

For a physical Android phone on the same Wi-Fi, bind the backend to your computer's network interface:

```powershell
python backend/server.py --host 0.0.0.0
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000
```

Replace `YOUR_PC_LAN_IP` with your computer's IPv4 address from `ipconfig`. Allow the server through the firewall on your private network. For physical iOS devices use a reachable HTTPS endpoint. An HTTPS-hosted Flutter website also needs an HTTPS API to avoid mixed-content blocking.

## Routes

- `GET /health`: `200 {"status":"ok"}`.
- `GET /api/drills`: `200` JSON array, including an empty `[]` when no drills exist.
- Unknown route: `404 {"error":"Not found"}`.
- Unreadable/invalid data file: `500 {"error":"Could not load drills"}`.
- `OPTIONS`: CORS preflight support for browser clients. GET responses allow cross-origin access.

Example drill:

```json
{
  "id": "1",
  "title": "Backhand Throw",
  "level": "Beginner",
  "minutes": 15,
  "instructions": "1. Warm up your wrists and shoulders."
}
```

Edit `backend/drills.json` to change the catalog; the next request reads the file again. Flutter validates title, level (Beginner/Intermediate/Advanced), positive integer minutes, and instructions. Invalid responses and HTTP failures show an error with Retry; requests time out after 10 seconds. Empty catalogs and searches with no matches have separate messages. Refresh uses the same endpoint. No bundled data is substituted on API failure.

The Drills tab uses HTTP data. Home recommendations, scheduling options, and progress duration calculations retain the original bundled catalog and local session storage. This backend is a local, read-only development server; it does not store sessions or provide authentication or write routes.

## Verification

```powershell
python -m unittest discover -s backend -v
flutter test
```

To check recovery manually, stop the server and refresh Drills, then restart it and tap Retry. To check the empty state, temporarily replace `drills.json` with `[]` and refresh; restore the catalog afterward.
