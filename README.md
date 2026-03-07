# 📱 Smart Expense Manager

**Smart Expense** is a premium, feature-rich mobile application built to help users seamlessly track their daily spending, manage monthly budgets, and gain financial clarity. Designed with a Pragmatic Feature-First Clean Architecture, it delivers a fast, secure, and highly personalized user experience comparable to top-tier FinTech apps.

---

## 🌟 Key Features

### 🔐 Secure & Seamless Authentication
* **Complete Auth Flow:** Secure Email/Password registration and login powered by Firebase Authentication.
* **Email Verification:** Mandates email verification for new accounts to maintain data integrity.
* **Password Recovery:** Integrated "Forgot Password" flow with secure reset links.

### 💰 Intelligent Expense Tracking
* **Dynamic Dashboard:** Real-time visibility into your financial health, including a dedicated **"Today's Spend"** tracker seamlessly integrated into the main UI.
* **Monthly Budgeting:** Set a custom monthly budget goal. The app features a dynamic progress bar that shifts colors (Green ➔ Orange ➔ Red) as you approach your limit.
* **Smart Categorization:** Organize expenses by category (Food, Transport, Bills, Entertainment, Other) with a visual percentage breakdown.
* **Full CRUD Capabilities:** Easily add, tap-to-edit, and swipe-to-delete daily transactions.

### 🔍 Advanced Search & Filter (All Expenses)
* **Real-time Search:** A dedicated "All Expenses" hub to instantly search through your entire financial history by title.
* **Dynamic Category Filters:** Quickly isolate spending using horizontal category chips (e.g., viewing only "Transport" or "Food" expenses).

### 🔔 Smart Notifications
* **Budget Alerts:** Automatically pushes a local device notification if you exceed 90% of your monthly budget.
* **Daily Reminders:** Scheduled local notifications at 8:00 PM to remind users to log their daily expenses and keep their streak alive.

### 🎨 Premium UI & Personalization
* **Adaptive Dark Mode:** A flawless, system-aware Dark/Light theme featuring deep navy and soft silver palettes for a comfortable viewing experience.
* **Native Splash Screen:** Android 12+ compliant adaptive splash screen that respects system themes.
* **Global Currency Picker:** Instantly swap between global currencies ($, ₹, €, £, ¥, ₩) across the entire app.
* **Cloud Sync & Local Cache:** User preferences (Theme, Currency) are cached locally using `Shared Preferences` for instant load times, while seamlessly syncing to Firestore in the background.

### 🚀 Over-The-Air (OTA) Updates
* **Force Update Engine:** Integrated Firebase Remote Config to instantly lock outdated app versions and redirect users to download the latest release via GitHub Releases.

---

## 🏗️ App Architecture

This project strictly adheres to a **Pragmatic Feature-First Clean Architecture**. This flattened structure ensures massive scalability, maintainability, and perfect separation of concerns without unnecessary folder nesting:

```text
lib/
 ├── core/                     # Shared app-wide logic
 │    ├── models/              # (e.g., expense_model.dart)
 │    └── services/            # (e.g., expense_service, user_service)
 │
 ├── features/                 # Independent, isolated feature modules
 │    ├── auth/                # pages/, widgets/, services/
 │    ├── dashboard/           # pages/, widgets/
 │    ├── profile/             # pages/
 │    └── transactions/        # pages/ (All Expenses Search & Filter)
 │
 ├── firebase_options.dart     # Firebase configuration
 └── main.dart                 # App entry point & Global State Notifiers