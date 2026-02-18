# Smart Expense Manager

Smart Expense Manager is an offline-first expense tracking mobile application built using Flutter and Firebase.

This project was developed to demonstrate scalable mobile architecture, structured state management, and real-world data handling practices.

---

## 🚀 Features

- User authentication using Firebase (Email & Password)
- Add, edit, and delete expenses
- Expense list with category support
- Monthly expense summary
- Offline-first data storage
- Automatic sync with Firestore when internet is available
- Clean and maintainable code structure

---

## 🏗 Project Architecture

The project follows a feature-based clean architecture approach with clear separation of responsibilities:

- **Presentation Layer** – UI and Bloc state management
- **Domain Layer** – Business logic and repository contracts
- **Data Layer** – Local (Hive) and Remote (Firestore) data sources

Key patterns used:

- Repository Pattern
- Bloc for predictable state management
- Dependency Injection (get_it)
- Local-first data strategy

The goal was to keep the code scalable, testable, and easy to maintain.

---

## 🔄 Offline-First Strategy

The app uses Hive for local storage.

- Expenses are saved locally first.
- If the device is online, data is synced to Firestore.
- If offline, data is marked as pending.
- When connectivity is restored, pending records are automatically synced.
- Conflict resolution is handled using a simple timestamp-based approach (last write wins).

This ensures a smooth user experience even without internet access.

---

## 🛠 Tech Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Hive (Local Storage)
- flutter_bloc
- get_it
- connectivity_plus

---

## 📂 Firestore Structure

Data is stored using a user-based structure:

users/{userId}/expenses/{expenseId}

Each expense includes:

- id
- title
- amount
- category
- date
- updatedAt
- syncStatus

---

## 🎯 Purpose of This Project

This project was built to practice and demonstrate:

- Scalable Flutter architecture
- State-driven UI design
- Repository abstraction
- Offline-first data handling
- Clean code organization

---

## 📌 Future Improvements

- Budget planning feature
- Expense export (CSV)
- Improved sync optimization
- Dark mode support
- Expanded unit test coverage

---

## 👨‍💻 Author

Amez Khan  
Flutter Developer

## Project Path

D:\FlutterLiveSource\Practice\smart_expense_manager