# Google Play Content Rating Questionnaire - OruShops

## App Information
- **App Name:** OruShops
- **Package Name:** com.orushops.orushops
- **Category:** Business/Productivity (POS System)
- **Target Age:** 12+

---

## Content Rating Questionnaire Responses

### 1. Violence
**Does your app contain content that depicts, encourages, or promotes realistic or cartoonish violence?**
- ✅ **No**

---

### 2. Sexual Content
**Does your app contain sexual content, nudity, or erotic content?**
- ✅ **No**

---

### 3. Profanity
**Does your app contain profanity or vulgar language?**
- ✅ **No**

---

### 4. Alcohol, Tobacco & Drugs
**Does your app contain references to alcohol, tobacco, or illegal drugs?**
- ✅ **No**

---

### 5. Gambling
**Does your app contain gambling or betting functionality?**
- ✅ **No**

---

### 6. Advertising
**Does your app contain advertising?**
- ✅ **No** (The app uses optional in-app purchases via RevenueCat, not traditional advertising)

---

### 7. Data Collection & Privacy
**Does your app collect personal information from users?**
- ✅ **Yes** - Minimal Data Collection
  - **Types of data collected:**
    - Email address and authentication credentials
    - Business shop information (name, location, details)
    - Inventory data (products, stock quantities, batches, pricing)
    - Customer information (Khata/credit records)
    - Device information (OS version, app version) for analytics
    - Crash logs (only with explicit user consent)
  
  - **Data handling:**
    - Most data is stored locally on device in encrypted SQLite database
    - Account authentication data stored on Firebase
    - Data never sold to third parties
    - Crash reporting disabled by default; only enabled if user grants analytics consent
    - Users can request complete data deletion at any time via Settings > Account > Request Data Deletion

---

### 8. User-Generated Content
**Does the app allow users to create, upload, or share content?**
- ✅ **Yes** - Limited
  - Users can create and manage inventory, products, and customer records for their business
  - All content is local to the user's device
  - No public sharing or social features

---

### 9. Developer Contact & Support
**Does the app provide ways to contact the developer?**
- ✅ **Yes**
  - Email: support@orushops.com
  - Website: https://orushops.com
  - In-app support via Settings > Help & Support

---

### 10. Restricted Functionality
**Does the app require specific permissions?**
- ✅ **Yes** - Requested with specific purposes:
  - **Camera:** QR/barcode scanning only
  - **Photos:** Product image uploads only
  - **Biometric:** Optional local device authentication
  - **Storage:** Local database and export functionality
  - **Network:** Cloud sync and Firebase services

---

### 11. Compliance Statements

#### COPPA (Children's Online Privacy Protection Act)
- **Compliant:** Yes
- **Statement:** OruShops is not intended for users under 13 years old. We do not knowingly collect personal information from children under 13. If we learn we have collected data from a child under 13, we will delete it immediately.
- **Parental Consent:** N/A (intended for business owners 18+)

#### GDPR (General Data Protection Regulation)
- **Compliant:** Yes
- **Data Subject Rights Implemented:**
  - Right to access personal data (Settings > Privacy)
  - Right to rectification (edit account information)
  - Right to erasure (request data deletion via Settings > Account > Request Data Deletion)
  - Right to data portability (export local data)
  - Right to withdraw consent (disable analytics in Settings > Privacy)

#### CCPA (California Consumer Privacy Act)
- **Compliant:** Yes
- **Consumer Rights Implemented:**
  - Right to know what personal data is collected
  - Right to delete personal data via Settings > Account > Request Data Deletion
  - Right to opt-out of data sale (we do not sell data)
  - Right to non-discrimination (no penalties for exercising rights)

#### LGPD (Lei Geral de Proteção de Dados - Brazil)
- **Compliant:** Yes
- **Data Subject Rights Implemented:**
  - Right to access personal data
  - Right to correct inaccurate data
  - Right to delete data via Settings > Account > Request Data Deletion
  - Right to data portability
  - Right to opt-out of analytics (Settings > Privacy)

---

### 12. Third-Party Services & Privacy

**List of third-party services used:**

1. **Firebase (Google)**
   - Purpose: Authentication, backup, cloud sync
   - Privacy Policy: https://policies.google.com/privacy
   - Data shared: Email, authentication tokens

2. **RevenueCat**
   - Purpose: In-app purchase and subscription processing
   - Privacy Policy: https://www.revenuecat.com/privacy
   - Data shared: Subscription/purchase status (payment info NOT shared)
   - Note: Payment information is processed directly by RevenueCat and not stored by OruShops

3. **Firebase Crashlytics**
   - Purpose: Crash reporting and app stability (user consent required)
   - Privacy Policy: https://policies.google.com/privacy
   - Data shared: Only error logs and crash data (when user has granted analytics consent)

4. **Analytics (Firebase Analytics or similar)**
   - Purpose: Anonymized usage metrics for app improvement
   - Data shared: Anonymized device info, feature usage (user consent required)

---

### 13. Age Rating Summary

**Recommended Age Rating: 12+**

**Rationale:**
- No violent, sexual, profane, or inappropriate content
- Business productivity tool designed for small shop owners
- Minimal data collection with strong privacy controls
- Full GDPR/CCPA/LGPD compliance
- Transparent data handling with user consent mechanisms
- No gambling, betting, or addictive mechanics

---

### 14. Declaration

I, the developer of OruShops, declare that:
1. All information provided in this questionnaire is accurate and truthful
2. The app complies with all applicable laws and regulations
3. The app respects user privacy and data protection rights
4. Third-party services are vetted for privacy compliance
5. No content violates Google Play Store policies

**Signature:** OruShops Development Team
**Date:** May 11, 2026
**Email:** support@orushops.com

---

## Notes for Submission

- This questionnaire should be submitted along with the app's Privacy Policy and Terms of Service
- Ensure the Privacy Policy is accessible at: https://orushops.com/privacy
- Ensure the Terms of Service is accessible at: https://orushops.com/terms
- Screenshot the Privacy Policy and Terms links in the app's Settings screen for the Play Store listing
- Include a note about data deletion capability in the app description
