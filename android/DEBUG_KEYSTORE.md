# Android Debug Keystore Setup

The build.gradle.kts now references `debug.keystore` for debug builds. Generate it with:

```bash
keytool -genkey -v -keystore debug.keystore -keyalg RSA -keysize 2048 -validity 10000 \
  -alias androiddebugkey -keypass android -storepass android \
  -dname "CN=Android Debug, O=, C=US"
```

Place `debug.keystore` in the `android/` directory.

For Google Sign-In, get the SHA-1 fingerprint:

```bash
keytool -list -v -keystore debug.keystore -alias androiddebugkey -keypass android -storepass android
```

Then add to Firebase Console under Android app SHA-1 fingerprint.
