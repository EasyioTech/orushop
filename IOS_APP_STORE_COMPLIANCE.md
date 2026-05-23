# iOS App Store Submission Compliance Checklist - OruShops

## App Information
- **App Name:** OruShops
- **Bundle ID:** com.orushops.orushops
- **Version:** 1.0.0
- **Category:** Business
- **Target iOS Version:** 14.0 or later

---

## Pre-Submission Checklist

### 1. App Metadata & Listing
- [ ] App name is clear and descriptive
- [ ] App subtitle explains main benefit
- [ ] App description covers features, offline support, GDPR compliance
- [ ] Keywords include: POS, inventory, retail, offline, Khata
- [ ] Support URL provided: https://orushops.com/support
- [ ] Privacy Policy URL provided: https://orushops.com/privacy
- [ ] Terms of Service URL provided: https://orushops.com/terms
- [ ] Contact email provided: support@orushops.com

### 2. Screenshots & Preview
- [ ] Minimum 2 screenshots (required for all devices)
- [ ] Screenshots show main features: POS, inventory, Khata, sales
- [ ] Screenshots include privacy/compliance messaging where applicable
- [ ] Preview video optional but recommended (show workflow demo)

### 3. PrivacyInfo.xcprivacy Manifest
- [ ] File exists at: `ios/Runner/PrivacyInfo.xcprivacy`
- [ ] NSPrivacyTracking: false (correct)
- [ ] NSPrivacyTrackingDomains: empty array (correct)
- [ ] NSPrivacyAccessedAPITypes declared:
  - [x] NSPrivacyAccessedAPICategoryFileTimestamp (C617.1)
  - [x] NSPrivacyAccessedAPICategorySystemBootTime (35F9.1)
  - [x] NSPrivacyAccessedAPICategoryUserDefaults (CA92.1)

### 4. Info.plist Permissions
- [ ] NSCameraUsageDescription: "Camera permission is required for QR and barcode scanning."
- [ ] NSPhotoLibraryUsageDescription: "Photo library access is needed to upload product images."
- [ ] NSLocalizedDescription: Added for all permission strings
- [ ] All permission descriptions are user-friendly and explain purpose

### 5. Data Collection & Privacy
- [ ] Privacy Policy accessible within app (Settings > Privacy & Compliance > Privacy Policy)
- [ ] Terms of Service accessible within app (Settings > Privacy & Compliance > Terms)
- [ ] Data deletion option available (Settings > Account > Request Data Deletion)
- [ ] Analytics consent toggle present (Settings > Privacy > Send Crash Reports)
- [ ] Crash reporting disabled by default (only enabled if user consents)
- [ ] No third-party tracking enabled without consent
- [ ] No sharing of IDFA (Apple ID for Advertisers) without consent

### 6. Third-Party SDKs & Compliance
- [ ] Firebase SDK latest version (^3.1.1)
- [ ] Firebase Crashlytics with consent-based collection implemented
- [ ] RevenueCat (purchases_flutter ^10.0.0) - payment processing only
- [ ] Google Sign-In (google_sign_in ^6.2.0) - optional social auth
- [ ] Sign in with Apple (sign_in_with_apple ^7.0.1) - required for iOS
- [ ] All third-party services comply with Apple privacy policies

### 7. Sign In with Apple
- [ ] Sign in with Apple implemented as primary auth option
- [ ] Available on iOS 13+
- [ ] "Sign in with Apple" button displayed prominently
- [ ] OAuth credentials properly configured in Apple Developer Console
- [ ] Privacy Policy references Apple account data handling

### 8. COPPA Compliance (if targeting under 13)
- [ ] Not targeting under 13 (Business app for store owners)
- [ ] Age gate not required
- [ ] No cartoonish or appealing-to-children design elements

### 9. GDPR Compliance
- [ ] Privacy Policy explicitly states GDPR compliance
- [ ] User consent obtained for data collection before use
- [ ] Right to access implemented (Users can view their data in app)
- [ ] Right to rectification implemented (Users can edit account info)
- [ ] Right to erasure implemented (Data deletion workflow)
- [ ] Right to data portability considered (Local export capability)
- [ ] Data Processing Agreement available if applicable

### 10. App Functionality & Technical
- [ ] App works offline (primary feature)
- [ ] Local SQLite database encrypted
- [ ] HTTPS used for all network communication
- [ ] No hardcoded credentials or API keys
- [ ] Crash reporting respects user consent preference
- [ ] App does not request unnecessary permissions
- [ ] App does not drain battery excessively
- [ ] App does not spam notifications

### 11. Content Restrictions & Appropriateness
- [ ] No violent, sexual, or offensive content
- [ ] No gambling or betting features
- [ ] No misleading advertising
- [ ] No content that violates intellectual property rights
- [ ] App description is honest and accurate

### 12. Subscription & In-App Purchase Compliance
- [ ] Subscription terms clearly disclosed
- [ ] Free trial terms disclosed (if applicable)
- [ ] Pricing displayed in local currency
- [ ] Cancellation method clearly explained (Settings > Subscription)
- [ ] Auto-renewal terms compliant with App Store guidelines
- [ ] RevenueCat handles all subscription logic

### 13. Localization (if applicable)
- [ ] English version complete
- [ ] Consider additional languages based on target market
- [ ] Translations reviewed for accuracy
- [ ] RTL language support if applicable

### 14. Build Configuration
- [ ] Release build certificate and provisioning profile configured
- [ ] Code signing enabled in Xcode project
- [ ] No debug symbols in release build
- [ ] App icons set for all required sizes
- [ ] Launch screen configured
- [ ] Minimum iOS version: 14.0

### 15. Testing Checklist
- [ ] App tested on real iPhone devices (not just simulator)
- [ ] App tested on latest iOS version (15.0+)
- [ ] All permissions tested and working correctly
- [ ] Privacy Policy and Terms links functional
- [ ] Data deletion flow tested end-to-end
- [ ] Analytics consent toggle tested
- [ ] Crash reporting respects user consent
- [ ] Sign in with Apple tested
- [ ] Offline functionality verified
- [ ] App does not crash on any screen
- [ ] No performance issues detected

### 16. Screenshots for App Store Review (Required)
```
Screen 1 (Home/Dashboard):
- Show main POS interface
- Include app name and tagline
- Highlight offline capability

Screen 2 (Inventory Management):
- Show product management features
- Demonstrate batch/expiry tracking
- Highlight sync capability

Screen 3 (Khata/Credit):
- Show customer credit management
- Display data management features

Screen 4 (Privacy/Compliance):
- Screenshot of Privacy Policy link in Settings
- Screenshot of Terms of Service link
- Screenshot of Data Deletion option

Note: Add text overlays explaining features if needed
```

---

## App Store Review Notes

```
=== NOTES FOR APPLE REVIEW TEAM ===

OruShops is an offline-first POS (Point of Sale) system designed for small 
retail store owners in India and beyond. 

KEY FEATURES:
- Offline-first operation (no internet required for core functionality)
- Local data storage with encrypted SQLite database
- Cloud sync via Firebase when online
- QR/barcode scanning for inventory
- Customer Khata (credit) tracking
- Sales analytics and reporting
- Optional cloud backup
- Optional in-app purchase subscriptions

PRIVACY & COMPLIANCE:
- GDPR, CCPA, and LGPD compliant
- Firebase Crashlytics with user consent (disabled by default)
- No tracking or advertising
- User can request complete data deletion at any time
- Privacy Policy: https://orushops.com/privacy
- Terms of Service: https://orushops.com/terms

PERMISSIONS USAGE:
- Camera: QR/barcode scanning only (images not stored)
- Photos: Product image uploads only
- Biometric: Optional local authentication (not transmitted)
- Network: Cloud sync and backup services
- Storage: Local database and export functionality

Third-party services used:
1. Firebase (Google) - authentication, backup, crash reporting
2. RevenueCat - subscription/purchase processing
3. Google Sign-In (optional) - social authentication
4. Sign in with Apple - primary authentication method

The app respects all Apple privacy guidelines and does not engage in 
unauthorized data collection, tracking, or ad targeting.

Contact: support@orushops.com
```

---

## Common Rejection Reasons to Avoid

- [ ] ❌ Do NOT hide privacy policy or terms
- [ ] ❌ Do NOT request unnecessary permissions
- [ ] ❌ Do NOT collect data without user consent
- [ ] ❌ Do NOT use IDFA for tracking without user opt-in
- [ ] ❌ Do NOT crash on startup or any screen
- [ ] ❌ Do NOT include malware or inappropriate content
- [ ] ❌ Do NOT violate intellectual property rights
- [ ] ❌ Do NOT mislead users about functionality
- [ ] ❌ Do NOT require sign-in to use basic features (allow guest/demo mode if needed)
- [ ] ❌ Do NOT spam notifications

---

## Submission Timeline

1. **Week 1:** Prepare build, screenshots, metadata
2. **Week 2:** Submit to App Store for review (allow 24-48 hours for initial review)
3. **Week 2-3:** Monitor for rejection reasons and respond quickly
4. **Week 3:** Resubmit if rejected with fixes
5. **Week 4:** App should be live (typical timeline)

**Note:** Apple review can take 24 hours to several days depending on queue and complexity.

---

## Post-Launch Monitoring

- [ ] Monitor crash reports in Xcode Organizer
- [ ] Track user reviews and ratings
- [ ] Respond to user feedback and support requests
- [ ] Plan for future iOS version compatibility
- [ ] Monitor Firebase console for errors
- [ ] Plan regular updates (quarterly recommended)

---

## Reference Links

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy – App Store – Apple Developer](https://developer.apple.com/app-store/privacy/)
- [PrivacyInfo.xcprivacy API Declarations](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Sign in with Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode-release-notes/xcode-13-release-notes)

---

**Last Updated:** May 11, 2026
**Status:** Ready for submission
**Prepared By:** OruShops Development Team
