# Smart Expense Manager 💰

A robust, production-grade Flutter application designed to help users track their personal finances with ease. Built with a focus on clean architecture, secure authentication, and a premium user experience.

## ✨ Features (Phase 1: Authentication)

This project currently features a complete, enterprise-level Firebase Authentication flow:
* **Secure Registration & Login:** Email and password authentication powered by Firebase.
* **Local Form Validation:** Regex-enforced strong passwords (minimum 8 characters, uppercase, and numbers) to prevent weak credentials before hitting the server.
* **Mandatory Email Verification:** Protects the database from fraudulent accounts. Users are blocked by a reactive verification screen until they click the secure link sent to their inbox.
* **Reactive Session Routing (`AuthGate`):** Utilizes Dart Streams (`FirebaseAuth.instance.userChanges()`) to automatically route users between the Login, Verification, and Dashboard screens without manual navigation pushing/popping.
* **Graceful Error Handling:** Translates Firebase exception codes (like `email-already-in-use` or `too-many-requests`) into user-friendly UI SnackBars.
* **Modern UI/UX:** Consistent, professional gradient styling with responsive loading states and clean text field components.

## 🛠️ Tech Stack & Architecture
* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Backend:** [Firebase Authentication](https://firebase.google.com/docs/auth)
* **Architecture Pattern:** Feature-first folder structure with a dedicated Service Layer to separate UI logic from backend API calls.

## 📱 Screenshots
> **Note to self:** Take a screenshot of your Login screen, Verify Email screen, and Dashboard using your phone or emulator. Save them in a folder called `assets/screenshots/` and uncomment the lines below to show them off!

## 🚀 Getting Started

If you want to clone this repository and run it locally, follow these steps:

### Prerequisites
* Install [Flutter](https://docs.flutter.dev/get-started/install)
* Install [Firebase CLI](https://firebase.google.com/docs/cli)
* Have an Android Emulator, iOS Simulator, or physical device ready.

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/Amez-Khan/smart-expense-manager.git](https://github.com/Amez-Khan/smart-expense-manager.git)