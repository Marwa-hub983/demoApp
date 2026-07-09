# Antigravity Commerce - Enterprise-Grade Flutter E-Commerce Application

An enterprise-ready, premium mini e-commerce mobile application built with **Flutter** using **Clean Architecture** (Feature-First approach), **BLoC/Cubit** for state management, **Hive** for encrypted local database caching, **Cloud Firestore** for backend persistence, and **GetIt / Injectable** for Dependency Injection.

This repository features a complete customer storefront coupled with a secure **Administrator Management Console** featuring real-time inventory tracking, low-stock warnings, and barcode scanner simulation.

---

## 🏗️ Architecture Design

The application follows the **Clean Architecture** model combined with a **Feature-First** structural design. This decouples business rules from UI components, assuring high scalability, testability, and code reuse.

```text
                                  CLEAN ARCHITECTURE LAYER PATTERNS
                                  
   +-----------------------------------------------------------------------------------------+
   | PRESENTATION LAYER (UI Widgets & Screens)                                               |
   |   Uses Bloc / Cubit to capture user gestures (Events) and render layouts (States).       |
   +---------------------------+-------------------------------------------------------------+
                               | (Triggers Use Cases / Repositories)
                               v
   +-----------------------------------------------------------------------------------------+
   | DOMAIN LAYER (Pure Dart Business Rules)                                                 |
   |   - Entities: Business models mapping objects (UserEntity, ProductEntity, OrderEntity). |
   |   - Repository Interfaces: Abstract contracts for data queries.                         |
   +---------------------------+-------------------------------------------------------------+
                               | (Implemented by Data Layer)
                               v
   +-----------------------------------------------------------------------------------------+
   | DATA LAYER (Data Retrieval & Mappings)                                                  |
   |   - Models: Data serialization structures mapping to JSON payloads.                     |
   |   - Repositories: Implements domain contracts, mapping exceptions to Failure models.    |
   |   - Datasources: Queries remote (Firestore/Dio) and local (Encrypted Hive) DB engines.  |
   +-----------------------------------------------------------------------------------------+
```

---

## 📂 Folder Structure

```text
lib/
├── core/                       # Core shared structures
│   ├── di/                     # Dependency injection (GetIt setup & generated config)
│   ├── errors/                 # Exception mappings & Failure models
│   ├── network/                # Dio client, connectivity check, & JWT headers
│   ├── routes/                 # Navigation system via GoRouter paths
│   ├── services/               # AES-encrypted Hive caches & Firestore simulations
│   ├── theme/                  # Material 3 dark/light settings & grid metrics
│   └── widgets/                # Reusable UI kit (shimmers, buttons, error views)
└── features/                   # Feature-first clean blocks
    ├── admin/                  # Dashboard charts, product CRUD, inventory scanner sim
    ├── authentication/         # splash animations, onboarding, login chips, registration
    ├── cart/                   # shopping cart, coupons, tax computation, checkout
    ├── orders/                 # logistics timelines, QR invoice, and PDF sharing
    ├── products/               # recommended grids, search lists, product details & reviews
    ├── profile/                # address books, settings, and dark mode toggles
    └── wishlist/               # realtime offline favorites caching
```

---

## ⚙️ Core Technical Stack & Dependencies

- **Framework**: Flutter Latest Stable (Material 3)
- **Language**: Dart (100% Null Safety)
- **State Management**: `flutter_bloc` (Cubit implementations with global observer logs)
- **Database / Backend**: **Cloud Firestore** & **Firebase Authentication** (Real-time database sync and server-side verification)
- **Local Storage**: `hive_flutter` + `flutter_secure_storage` (AES-256 local caches encryption)
- **Routing**: `go_router` (Deep-link ready structure)
- **DI Service Locator**: `get_it` + `injectable` (Auto-wires dependency instances during boot)
- **Networking**: `dio` (Timeouts, logger interceptor, connection checker, token auto-injector)
- **UI Utilities**: `barcode_widget` (QR generator), `pdf` (invoice building), `share_plus` (sharing), `shimmer` (loading skeleton screens)

---

## 🚀 Running the Project

### Prerequisites
Make sure you have Flutter installed and configured.

```bash
# Verify Flutter and Dart versions
flutter --version
```

### Installation
1. Clone the repository and navigate to the project directory:
```bash
cd demo_app
```

2. Retrieve dependencies:
```bash
flutter pub get
```

3. Run code generators (`injectable` DI generator):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Launch the application:
```bash
flutter run
```

### Run Tests
Execute the unit and state verification tests:
```bash
flutter test
```

---

## 🔧 Firebase Integration vs Sandbox Mock Mode

The application contains a dual-data layer structure. By default, it runs in **Sandbox Mock Mode**, utilizing `MockDatabaseService` (simulated Firestore) and `CacheService`. This allows you to immediately test, log orders, restock products, and change order timeline states offline without needing active Firebase keys.

To migrate the application to a production **Firebase** backend:
1. Create a Firebase project in the Console.
2. Download and drag-and-drop the configuration files:
   - For Android: Place `google-services.json` inside `/android/app/`
   - For iOS: Place `GoogleService-Info.plist` inside `/ios/Runner/`
3. Initialize Firebase in `lib/main.dart`:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## 🛡️ Security Implementations

1. **Encrypted Caches**: Local tokens, settings, and customer preferences are stored inside Hive boxes encrypted with AES-256 keys. The encryption key is securely generated and written inside platform keychain/keystores using `flutter_secure_storage`.
2. **Protected Routing**: Navigation pathways are filtered inside `go_router`. Unauthorized routes are intercepted, and users are redirected to login forms.
3. **No Secrets Inside Code**: Sensitive tokens are read dynamically at runtime from local secure storage.
