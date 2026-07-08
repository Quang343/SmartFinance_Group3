# 💸 SmartFinance (Group 3)

A robust, cloud-synced Cash Flow Management Application designed specifically for Small and Medium Enterprises (SMEs) to manage expenses, revenues, and invoices in real-time.

## 🏛 Architecture Overview

This project adheres to **Clean Architecture** principles and modular design to ensure scalability, testability, and separation of concerns.

- **Presentation Layer (`features/`)**: Contains the UI widgets, Riverpod providers, and state management logic.
- **Domain Layer (`domain/`)**: The core of the application. Contains business logic, pure Dart Entities.
- **Data Layer (`data/`)**: Implements Repositories and Data Sources (Firebase Firestore, Auth, and ImgBB APIs).
- **Core Layer (`core/`)**: Shared constants, themes, error handling, and reusable UI components.

## 🛠 Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing**: `go_router`
- **Backend & Database**: [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore) (Realtime Cloud Sync)
- **Authentication**: Firebase Auth (Email/Password & Google Sign-In)
- **File Storage**: [ImgBB API](https://api.imgbb.com/) (Cloud storage for avatars and invoices)
- **Environment Management**: `flutter_dotenv`

## 🚀 Key Features

- **Real-time Cloud Sync**: All data is securely stored and synchronized in real-time using Firebase Firestore. No more manual refreshing.
- **Role-Based Access Control (RBAC)**: Distinct permissions for roles like "Quản lý tài chính" (Finance Manager) and "Kế toán chi phí" (Expense Accountant).
- **Dashboard**: Live aggregation of income, expenses, and net cash flow with beautiful UI and charts.
- **Transaction & Invoice Management**: Track cash flows, automated categorization, and upload invoices seamlessly to the cloud.
- **Profile Customization**: Users can update their personal information and upload avatars (integrated with DiceBear for default cute avatars and ImgBB for custom uploads).
- **Reporting & Export**: Generate cash flow summaries and export to PDF.

## ⚙️ Getting Started

### 1. Prerequisites
- Flutter SDK ^3.0.0 installed.
- A Firebase project configured (with Firestore and Authentication enabled).

### 2. Environment Setup (API Keys)
This project uses **ImgBB** for fast, free image hosting. You need to configure the API key before running the app.
1. Create an account at [api.imgbb.com](https://api.imgbb.com/) and get a free API key.
2. At the root of the project, create or rename `.env.example` to `.env`.
3. Open `.env` and replace the placeholder with your actual key:
   ```env
   IMGBB_API_KEY=your_actual_api_key_here
   ```
*(Note: `.env` is intentionally ignored by `.gitignore` to keep your secrets safe. Do not push this file to GitHub).*

### 3. Run the App
Install dependencies and run the app:
```bash
flutter pub get
flutter run
```

## 📦 Default Seed Data

Upon the first launch, if the database is empty, the app will automatically run `FirebaseSeedService` to inject default Roles (Admin, Accountant, etc.) and a standard account into Firestore to help you test the UI and authorization flow immediately.
