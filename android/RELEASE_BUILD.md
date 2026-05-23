# Release Build Configuration

## Keystore Setup
The release keystore is located at `android/app/orushops-release.jks` and is generated with:
- **Keystore Password**: OruShops@123
- **Key Alias**: orushops
- **Key Password**: OruShops@123

## Credentials Storage
Credentials are stored in `android/key.properties` (gitignored for security):
```properties
storePassword=OruShops@123
keyPassword=OruShops@123
keyAlias=orushops
storeFile=app/orushops-release.jks
```

## Building Release APK
The build process automatically reads credentials from `key.properties`. Just run:
```bash
cd orushops
flutter build apk --release
```

No environment variables needed. The gradle config reads from `key.properties` automatically.

## Output
The signed APK is created at: `build/app/outputs/flutter-apk/app-release.apk`

## Rebuilding Keystore
If credentials are lost, regenerate the keystore:
```bash
keytool -genkey -v -keystore android/app/orushops-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias orushops \
  -keypass OruShops@123 \
  -storepass OruShops@123 \
  -dname "CN=OruShops,O=OruShops,C=IN"
```

## Cache Issues
To clean build cache and prevent issues:
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build apk --release
```
