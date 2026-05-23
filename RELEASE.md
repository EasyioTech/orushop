# RetailDost — Release Checklist

## 1. Bump version
Edit `pubspec.yaml`:
```
version: X.Y.Z+N   # e.g. 1.2.0+12 — N is versionCode on Play Store
```
- `X.Y.Z` = semantic version shown to users
- `+N` = integer build number, must be **strictly higher** than the last Play Store upload

---

## 2. Clean & prep
```powershell
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 3. Verify
```powershell
flutter analyze --no-pub --fatal-infos
flutter test
```
Fix all errors before proceeding. Warnings are OK; infos are not (they'll fail CI).

---

## 4. Build

### APK (direct install / QA)
```powershell
flutter build apk --release --no-pub
# Output: build\app\outputs\flutter-apk\app-release.apk
```

### AAB (Play Store upload)
```powershell
flutter build appbundle --release --no-pub
# Output: build\app\outputs\bundle\release\app-release.aab
```

---

## 5. Signing (automatic)
Signing is wired into Gradle — no extra flags needed.

**Local machine** — Gradle reads `android/key.properties` (gitignored):
```
storeFile=app/orushops-release-jks.jks
keyAlias=orushops
storePassword=OruShops@123
keyPassword=OruShops@123
```

**CI** — set these env vars (no `key.properties` on CI):
```
STORE_FILE=<path-to-jks>
KEY_ALIAS=orushops
STORE_PASSWORD=<password>
KEY_PASSWORD=<password>
```

Keystore file: `android/app/orushops-release-jks.jks` (gitignored, **back it up externally**)
SHA-256 cert fingerprint: `36:CF:04:63:C9:39:43:80:11:81:46:66:EF:DB:EE:E5:54:FE:0E:FE:20:33:3E:53:17:55:A6:C4:E1:51:97:76`

---

## 6. Play Store upload
1. Go to Play Console → RetailDost → Production (or Internal for testing)
2. Create new release → Upload `app-release.aab`
3. Fill release notes
4. Review → Roll out

---

## What to NEVER do

| Action | Why |
|--------|-----|
| Commit `*.jks` or `key.properties` | Exposes signing key — app can be cloned/signed by anyone |
| Commit `android/local.properties` | Machine-specific SDK paths |
| Upload to Play Store with a **lower** versionCode | Play rejects it |
| Use `flutter build apk --debug` for release | Debug builds are unsigned / slower |
| Set `STORE_FILE`, `KEY_PASSWORD`, `STORE_PASSWORD` env vars on dev machine | They override `key.properties` and will cause signing failures |
| Delete or overwrite the `.jks` file without a backup | The app cannot be updated on Play Store without the original signing key |

---

## Troubleshooting

### "keystore password was incorrect"
- Check `android/key.properties` — passwords must match the `.jks` file exactly
- Unset any `STORE_PASSWORD` / `KEY_PASSWORD` env vars on your machine (they override `key.properties`)

### `integration_test` compile error on release
- Already fixed in `settings.gradle.kts` + `build.gradle.kts` (flutter#56591 workaround)
- Do not remove the `compileOnly(project(":integration_test"))` line

### `lintVitalAnalyzeRelease` file lock (Windows)
- Already disabled for library subprojects in `android/build.gradle.kts`
- If it reappears: add an exclusion for Windows Defender on the `build/` directory

### Build cache stale after config change
```powershell
cd android && .\gradlew.bat --stop
cd .. && flutter clean
Remove-Item -Recurse -Force build
flutter build apk --release --no-pub
```

---

## Key files (DO NOT DELETE OR MOVE)

| File | Purpose |
|------|---------|
| `android/app/orushops-release-jks.jks` | Release signing key — **back up off-repo** |
| `android/key.properties` | Signing config for local builds — gitignored |
| `android/app/google-services.json` | Firebase config |
| `android/app/proguard-rules.pro` | R8 keep rules for release minification |
