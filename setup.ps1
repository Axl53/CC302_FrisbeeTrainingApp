$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter create --platforms=android,ios,web --project-name frisbee_training .
if ($LASTEXITCODE -ne 0) { throw 'Flutter create failed. Check Flutter installation.' }
$manifest = 'android/app/src/main/AndroidManifest.xml'
$text = Get-Content $manifest -Raw
if ($text -notmatch 'android.permission.INTERNET') {
  $text = $text.Replace('<application', '<uses-permission android:name="android.permission.INTERNET" /><application')
  Set-Content $manifest $text
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Analyze failed. Review errors above.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed. Review errors above.' }
Write-Host 'Setup complete. Run: flutter run'
