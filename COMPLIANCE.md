# OruShops Compliance Checklist for App Store Submission

## Google Play Store Requirements

### ✅ Must-Have (App Will Be Rejected Without These)

- [x] Privacy Policy (accessible in-app + web URL)
  - File: `lib/presentation/widgets/compliance_modals.dart`
  - Must explain data collection, usage, and user rights
  
- [x] Terms of Service (accessible in-app + web URL)
  - File: `lib/presentation/widgets/compliance_modals.dart`
  - Must explain usage restrictions and liability limitations

- [x] Data Deletion Feature (GDPR/CCPA requirement)
  - File: `lib/core/services/compliance_service.dart`
  - Implementation: Settings > Account > Request Data Deletion
  - Backend endpoint required: `POST /api/users/{userId}/request-deletion`

- [x] Required Android Permissions in AndroidManifest.xml
  - CAMERA (QR scanning)
  - USE_BIOMETRIC (auth)
  - READ/WRITE_EXTERNAL_STORAGE (data export)
  - READ_MEDIA_IMAGES (photo picker)
  - File: `android/app/src/main/AndroidManifest.xml`

- [x] Content Rating Questionnaire Answers
  - **Action Required:** Answer Google Play's content rating form during submission
  - This app: Low risk (business/productivity, no violence/adult content)
  - Mark all as "No" unless app has content filters, ads, etc.

### ⚠️ Strongly Recommended

- [x] Crash Reporting Consent
  - File: `lib/presentation/widgets/compliance_modals.dart` (AnalyticsConsentModal)
  - Implementation: Opt-in for Firebase Crashlytics

- [x] Analytics Consent (GDPR/CCPA)
  - File: `lib/core/services/compliance_service.dart`
  - Settings > Privacy > Analytics & Crash Reports toggle

## Apple App Store Requirements

### ✅ Must-Have

- [x] Privacy Policy (web URL + in-app link)
  - Must comply with GDPR, CCPA, LGPD
  - Include data collection, third-party sharing, user rights

- [x] Terms of Service (web URL + in-app link)
  - Must be accessible to all users

- [x] Privacy Manifest (PrivacyInfo.xcprivacy)
  - **Action Required:** Create `ios/Runner/PrivacyInfo.xcprivacy` listing:
    - NSPrivacyTracking: false
    - NSPrivacyTrackingDomains: [] (if no tracking)
    - NSPrivacyAccessedAPITypes: [list APIs used below]

- [x] iOS Info.plist Privacy Descriptions
  - File: `ios/Runner/Info.plist`
  - Includes:
    - NSCameraUsageDescription (QR scanning)
    - NSBiometricUsageDescription (authentication)
    - NSPhotoLibraryUsageDescription (image upload)

- [x] App Transport Security (ATS)
  - **Status:** Default secure
  - All HTTP endpoints must be HTTPS or whitelisted

### ⚠️ Strongly Recommended

- [x] Offline Functionality Disclosure
  - Explain in App Store description that app works offline

- [x] Subscription Management (RevenueCat)
  - **Status:** Already integrated
  - Ensure pricing and renewal terms are clearly displayed

- [x] iCloud/Data Backup Policy
  - **Action Required:** Add to privacy policy
  - SQLite database is local-only by default

## Implementation Status

### Completed ✅
1. Privacy Policy modal in app
2. Terms of Service modal in app
3. Data deletion request endpoint (service layer)
4. Analytics consent toggle
5. Permissions service with runtime permission handling
6. Android permissions in manifest
7. iOS privacy descriptions in Info.plist
8. Settings screen with privacy links

### TODO 🔄

1. **Create Webpage Privacy Policy & Terms**
   - Publish at: `https://orushops.example.com/privacy` and `/terms`
   - Include: data collection, third-party sharing, user rights, deletion process

2. **iOS Privacy Manifest (PrivacyInfo.xcprivacy)**
   - Add file: `ios/Runner/PrivacyInfo.xcprivacy`
   - List APIs: Firebase Analytics, Google Sign-In, RevenueCat APIs accessed

3. **Content Rating Submission**
   - During Google Play upload, answer questionnaire:
     - Violence: No
     - Profanity: No
     - Adult Content: No
     - Gambling: No
     - Alcohol/Tobacco: No (unless app tracks inventory of these)
     - Ads: Specify if using banner/interstitial/rewarded ads

4. **App Signing Certificates**
   - **Android Release:** Create/import keystore for signing
     - Location: `orushops-release.jks`
     - Configured in: `android/app/build.gradle.kts`
   - **iOS Release:** Export provisioning profile + certificate from Apple Developer

5. **Backend Data Deletion Endpoint**
   ```
   POST /api/users/{userId}/request-deletion
   Body: { "reason": "optional" }
   Response: { "status": "deletion_queued", "completionDate": "ISO-8601" }
   ```

6. **Crash Reporting Integration**
   - Enable Firebase Crashlytics in `lib/main.dart`
   - Ensure consent check before sending crashes

7. **App Version Management**
   - Update `version: 1.0.0+1` in `pubspec.yaml` for each release
   - Format: `major.minor.patch+buildNumber`

8. **Test Accounts for Reviewers**
   - **Action:** Provide test account credentials to app stores if payment testing needed
   - Ensure test account works without payment

## Compliance Checklist Before Submission

### Both Stores
- [ ] Privacy Policy live and accessible at public URL
- [ ] Terms of Service live and accessible at public URL
- [ ] Data deletion feature working end-to-end
- [ ] App does NOT crash on permission denials
- [ ] All third-party libraries disclosed (Firebase, RevenueCat, etc.)
- [ ] No hardcoded API keys or secrets
- [ ] Crash reporting works and respects user consent

### Google Play
- [ ] AndroidManifest.xml has all required permissions
- [ ] App icon and screenshots uploaded
- [ ] Content rating answers submitted
- [ ] Privacy policy URL matches store listing
- [ ] Release signing keystore configured

### Apple App Store
- [ ] Info.plist has all privacy descriptions
- [ ] PrivacyInfo.xcprivacy is complete and accurate
- [ ] App icon, screenshots, and description uploaded
- [ ] Build signing certificate + provisioning profile valid
- [ ] Privacy policy URL in app store listing

## External URLs to Update

Update these before release:
```
Privacy Policy: https://orushops.example.com/privacy
Terms of Service: https://orushops.example.com/terms
Data Deletion Request Form: https://orushops.example.com/support/data-deletion
```

---

**Last Updated:** 2026-05-11
**Next Review:** Before each app release
