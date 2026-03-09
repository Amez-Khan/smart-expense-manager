# 📱 Smart Expense Manager

**Smart Expense** is a premium, feature-rich mobile application built to help users seamlessly track their daily spending, manage monthly budgets, and gain financial clarity. Designed with a Pragmatic Feature-First Clean Architecture, it delivers a fast, secure, and highly personalized user experience comparable to top-tier FinTech apps.

---

## 🌟 Key Features

### 🔐 Secure & Seamless Authentication
* **Complete Auth Flow:** Secure Email/Password registration and login powered by Firebase Authentication.
* **Email Verification:** Mandates email verification for new accounts to maintain data integrity.
* **Password Recovery:** Integrated "Forgot Password" flow with secure reset links.
* **Verified Data Ownership:** Hardened **Firestore Security Rules** ensure users can only access their own documents nested under their unique `userId`.

### 💰 Intelligent Expense Tracking
* **Dynamic Dashboard:** Real-time visibility into your financial health, including a dedicated **"Today's Spend"** tracker.
* **Monthly Budgeting:** Set a custom monthly budget goal with a dynamic progress bar that shifts colors as you approach your limit.
* **Full CRUD Capabilities:** Support for adding, editing, and deleting transactions with real-time cloud synchronization.

### 🛠️ Professional Support & Compliance
* **Integrated Help Center:** A dedicated "Help & Support" portal accessible via the profile.
* **Direct Developer Contact:** Functional "Email Support" button that automatically launches the user's native email client.
* **Privacy First:** Built-in **Privacy Policy** integration to meet Google Play Store compliance standards for data handling.
* **Dynamic App Sharing:** Viral sharing feature powered by `share_plus` that distributes the latest release URL fetched dynamically from the cloud.

### 🎨 Premium UI & Personalization
* **Adaptive Dark Mode:** A system-aware Dark/Light theme featuring deep navy and soft silver palettes.
* **Native Splash Screen:** Android 12+ compliant adaptive splash screen that respects system themes.
* **Global Currency Picker:** Instantly swap between global currencies ($, ₹, €, £, ¥, ₩) with persistent local caching.
* **Custom Production Icons:** Professionally generated launcher icons for a polished home-screen presence.

### 🚀 Smart Update Engine (OTA)
* **Remote Config Force Update:** Uses Firebase Remote Config to compare the local version against a `minimum_required_version`.
* **Dynamic Store Redirection:** Automatically directs users to the `update_store_url` (GitHub or Play Store) when an update is required.

---

## 🏗️ App Architecture

This project strictly adheres to a **Pragmatic Feature-First Clean Architecture**, ensuring scalability and a perfect separation of concerns:

```text
lib/
 ├── core/                     # Shared app-wide logic
 │    ├── models/              # (e.g., expense_model.dart)
 │    └── services/            # (e.g., notification_service, user_service)
 │
 ├── features/                 # Independent feature modules
 │    ├── analytics/           # pages/ (Financial Insights)
 │    ├── auth/                # pages/, widgets/, services/
 │    ├── dashboard/           # pages/, widgets/
 │    ├── expenses/            # pages/ (All Expenses Search & Filter)
 │    └── profile/             # pages/ (Settings & Support)
 │
 ├── firebase_options.dart     # Firebase configuration
 └── main.dart                 # Entry point, Remote Config, & Global State

👨‍💻 Developer
Amez Khan Azeez Khan

Flutter App Developer with 4 years of experience.

GitHub: https://www.google.com/search?q=https://github.com/Amez-Khan

## ⚙️ Configuration & System Requirements

To ensure a stable development environment and successful production builds, this project is configured for the following specifications:

### 💻 Development System (Verified)
* **Operating System:** Windows 11 Pro (64-bit).
* **Flutter SDK:** Version 3.38.5 (Stable Channel).
* **Dart SDK:** Version 3.10.4.
* **Java Runtime:** Microsoft OpenJDK 17.0.13.
* **Android SDK:** API Level 36 (Build-tools 36.1.0).

### 📱 Target Platforms
* **Android:** Supports Android 5.0 (API 21) through Android 13 (API 33) and above.
* **Web:** Optimized for Google Chrome and Microsoft Edge.

### 🛠️ Required Dependencies
This project utilizes a **Feature-First Clean Architecture** and requires the following key integrations:
* **Firebase Core:** Authentication, Cloud Firestore, and Remote Config.
* **Local Storage:** `shared_preferences` for caching theme and currency.
* **Communication:** `url_launcher` for Email Support and Privacy Policy links.
* **Sharing:** `share_plus` for dynamic APK and document sharing.

### 🔐 Android Manifest Permissions
Ensure the following permissions and queries are present in your `AndroidManifest.xml` for full functionality:
* `RECEIVE_BOOT_COMPLETED` & `SCHEDULE_EXACT_ALARM` (For daily reminders).
* `POST_NOTIFICATIONS` (For budget alerts on Android 13+).
* `queries` block for `mailto:` and `https:` schemes (For Support & Updates).

