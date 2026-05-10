# OruShops

A premium, offline-first Point of Sale (POS) system built with Flutter.

## Features

- **Offline-First Architecture**: Seamlessly process transactions and manage inventory without an internet connection.
- **Global Catalog Integration**: High-density product barcode identification for rapid item entry.
- **Real-time Synchronization**: Automatically syncs local data to Firestore when online.
- **Comprehensive Inventory Management**: Track stock levels, pricing, and product metadata.
- **Premium UI/UX**: Designed for efficiency and visual excellence in retail environments.

## Getting Started

### Prerequisites

- Flutter SDK (^3.11.4)
- Firebase Account (for cloud synchronization)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/orushops.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective platform directories.

4. Run the app:
   ```bash
   flutter run
   ```

## Architecture

- **State Management**: [Riverpod](https://riverpod.dev/)
- **Database**: [Sqflite](https://pub.dev/packages/sqflite) (Local) & [Cloud Firestore](https://firebase.google.com/docs/firestore) (Cloud)
- **Monetization**: [RevenueCat](https://www.revenuecat.com/)

## License

Copyright © 2026 OruShops. All rights reserved.
